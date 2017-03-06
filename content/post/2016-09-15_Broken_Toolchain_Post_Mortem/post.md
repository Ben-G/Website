+++
date = "2016-09-15T22:24:54-08:00"
draft = false
title = "Broken Toolchain Post Mortem"
slug = "broken-toolchain"
disqus_url = "http://blog.benjamin-encz.de/post/broken-toolchain/"
+++

Dependency managers, IDEs, continuous integration, automated tests - all these tools are created to supercharge a developer team's productivity. While modern development tools are amazing in many ways, they unfortunately also add maintenance burden to a project. 

Ask me about migrating our Bitrise & fastlane CI workflows to Xcode 8. 

The goal of this post it not to blame any individual party. I'm writing this for the following reasons:

- share my frustration (if you're feeling stupid for struggling with tooling, hopefully you won't anymore after reading this)
- keep track of the issues I encountered & fixed (always helpful, and I'll never forget why it took 3 days to fix all CI workflows)
- reflect on what the causes of complicated tooling are and how they might be fixed in future
 
I also have a somewhat special relationship to tools. I remember how, as a student, complicated tooling almost deterred me from a career in software development - "If I can't even get a J2EE app configured and running, I probably shouldn't be a software developer". This post is some form of self-therapy...

<!--more-->

## Migrating to Xcode 8

This is a somewhat chronological sequence of various issues I encountered when updating our CI server to work (again) with Xcode 8.

#### 1. Broken Code Signing

Xcode 8 set out to fix one of the major tool annoyances that developers encounter: code signing. The "Fix issue" button has been removed and automatic code signing has been overhauled. You can enable it with a simple checkbox (which will trigger Xcode to generate provisioning profiles automatically):

![](auto_sign.png)

However, this option is not compatible with `xcodebuild`. I haven't dug into the details, but when this option is checked you need to be signed into a development team so I believe the feature cannot be used on a CI machine from the command line.

Other folks ran into this issue [as well](https://github.com/fastlane/fastlane/issues/6055). You can just disable automatic code signing and select specific profiles as mentioned in the [fastlane codesigning docs](https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Codesigning/XcodeProject.md#readme).

However, this approach is not compatible with our current build configuration. We create various different PlanGrid builds (daily, release candidates, etc.) with slightly different configurations. As part of these configurations we change the bundle identifier to allow multiple builds to be installed on a device side by side.

In Xcode 7 we could use a script to rename the bundle identifier and the `Automatic` provisioning setting would pick the right provisioning profile based on the bundle identifier.

However, this option is no longer available in Xcode 8 (you can go fully automated or you need to explicitly specify a profile for each target & build configuration).

I could work around this by defining an environment variable that specifies the correct provisioning profile for each lane and using that environment variable as part of the build configuration.

**First issue solved; this one was easy as I could reproduce it on a local machine.** At this point fastlane builds were passing locally, but for some mysterious reason they were still failing on CI with the catchall error `Exit status: 65`.

**Takeaway 1:** It would be great if Apple would have documented if/how automatic signing should be used with `xcodebuild`. But admittedly our use case for changing bundle identifiers dynamically is a little unconventional (we could just have separate targets).

#### 2. Ruby Issues

At this point I was investigating our `buid_deploy_latest` lane, which runs whenever we merge to `dev`. It creates a build, ships it to HockeyApp, runs the test suite and reports code coverage to codecov.

This lane was failing on both steps (archiving & testing) on CI, while it was passing locally. This was the error message in the CI build log:

![](ruby_crash.png)

In the past, `Exit status: 65` mostly meant codesigning issues, so I spent some time investigating in the wrong direction here. The log was claiming that a build script failure was failing the build. In particular the script that uploads our dSYM to Bugsnag.

For too long I assumed this error message to be incorrect. The Bugsnag script is one of the last steps before codesigning so I assumed Xcode is attributing the error incorrectly. Especially since it seemed extremely unlikely that a script that hasn't caused any issues so far would pass locally and fail on CI.

After spending too much time on investigating code signing as the potential issue, I found out that the build logs referred to additional log data in the `Derived Data` folder. 

I modified the Bitrise workflow to add a step that deployed the `Derived Data` folder to S3 after building (Bitrise offers a convenient "Artifact Deploy" step for this).

Within the `Derived Data` folder I found `.xcactivitylog` files. These log files capture the output that you can see in the build log in the  Xcode IDE. StackOverflow told me that these are [files that can be unzipped](http://stackoverflow.com/questions/13861658/is-it-possible-to-search-though-all-xcodes-logs).

Luckily these logs contained a lot more details on the failed script phase:

![](ruby_crash_details.png)

The following line stands out as the root cause of the script failure:

```
Could not find json-1.8.3 in any of the sources (Bundler::GemNotFound)
```

At this point I found out that the Bitrise macOS image install the latest version of ruby from homebrew, which was version `2.3.1` while I was using the macOS system default, ruby `2.0.0`, on my local machine.

Looking at the stacktrace we can see that the script is calling ruby `2.0.0`'s `require` function which is then calling the ruby `2.3.0` `bundler` gem. The Bugnsag script is executed with `usr/bin/ruby` (which is the system default of `2.0.0` on Bitrise). I could temporarily fix the issue by calling the script with `usr/local/bin/ruby` (which is ruby `2.3.0` installed by homebrew on Bitrise).
I'm tapping a little in the dark if this version mismatch is actually the root of the problem - if you're better versed in the ruby universe than I am, please drop a comment!

Eventually I decided that the best solution would be to leave the script untouched and instead ensure that Bitrise uses the system version of ruby. That's the default on any new developer's machine and should therefore cause the least discrepancy between local and CI builds.

Using `brew unlink ruby` (thanks Bitrise support for the tip!) I was able to switch back to the system ruby on Bitrise and the error vanished.

**Takeaway 2:** Read xcodebuild's error messages exactly and believe them even though they can be misleading sometimes. Probably should also pin the ruby version used locally and on CI using `RVM` or `chruby` to avoid such mismatches in future (though this would increase the time for spinning up a new machine on Bitrise). I will also need to investigate further why this issue started ocurring after switching to the Xcode 8 toolchain. So far I'm assuming the Bitrise image was updated as part of the Xcode update and installed a newer version of ruby.

#### 3. Xcode Test Manager Timeouts

This one is still a complete mystery to me. At this point I can run all lanes on fastlane locally. I can run `xcodebuild test` on Bitrise. However, running tests via fastlane on Bitrise is still failing. The failure only occurs in this combination. I've opened tickets with both tools - I'm aware that likely no one will feel responsible for fixing this since both tools work in isolation. But maybe someone else finds these issues useful? ([Bitrise](https://github.com/bitrise-io/bitrise.io/issues/66), [fastlane](https://github.com/fastlane/fastlane/issues/6111))

On the surface (looking at xcodebuild output piped to fastlane/xcpretty) the error reporting is again very limited: `**TEST FAILED** and `Exit status: 65`:

![](test-hangs.png)

I again resorted to investigating the `xcactivitylog` files; this time for the test activity instead of the build activity. From there it became pretty obvious what is happening:

![](test-hangs-details.png)

For some reason the communication between `testmanagerd`, Xcode and the Simulator is broken and timing out, which eventually causes the test suite to fail. For now my patience is over and I've replaced this particular fastlane step with a manual call to `xcodebuild test`. I'm planning on filing a radar, though I feel bad for not really having a reproduction case.

**Takeaway 3:** Interop between various tools is the worst. If you encounter issues that only occur when you combine multiple tools, it is very hard to narrow down the root cause. In this case it seems like an `xcodebuild` bug. Why is it only happening when using fastlane on Bitrise? I don't know (yet?).


#### 4. GitHub Request Timeouts &  HockeyApp Deploy Failure

Various builds would fail due to GitHub request timeouts that caused CocoaPods to fail. Sometimes uploads from Bitrise to HockeyApp would fail as well. Nothing to learn here, just want to demonstrate the amount of pain I went through:

![](hockey-deploy-failed.png)
![](github_timeout.png)

## Conclusion

I should probably accept that our tools are complex and fragile and that a significant portion of my job responsibility is simply to keep things running as various tools change over time. 

However, working with tools in Apple's ecosystem often feels unnecessary painful. 

`xcodebuild` is one of the prime examples: there's barely any (up to date) documentation and the unstructured build output is still a huge issue. Maybe Apple is trying to push Xcode Server? Even if that's the case they shouldn't ignore the fact that most companies & open source projects rely on `xcodebuild` as of today. 

I'm under the impression that Apple is building tools that work great for small teams and indie developers - the new automatic code signing is the latest example. But it's time to admit that a lot of app development happens in large companies that rely heaviliy on automation and therefore need a solid command line interface for the entire toolchain.

So far the open source community has done a great job at filling the various gaps in Apple's developer tool ecosystem. But I sincerely hope these are just temporary solutions. The combinatorial complexity of piecing together various third party solutions will always lead to issues that are extremely difficult to track down and fix. 

Recent hiring efforts on Apple's developer tools team make me optimistic. 

For now I will work on my patience and on improving my toolkit debugging skills. 

----

Couldn't stop myself from adding these, too...

![](last_two.png)
![](last_one.png)
