+++
date = "2016-09-14T22:24:54-08:00"
draft = false
title = "Broken Toolchain Post Mortem"
slug = "broken-toolchain"
disqus_url = "http://blog.benjamin-encz.de/post/broken-toolchain/"
+++

Dependency managers, IDEs, continous integration, automated tests - all these tools are created to supercharge a developer's productivity. Yet more often than not, tools are getting in the way and stop us from writing code. Ask me about migrating to Xcode 8. 

**I'm not writing this to blame any individual party.** I don't really have a solution to offer. I'm writing this to share my frustration. By doing so I'll hopefully get a better understanding of why most software development tools are broken and be less frustrated in future.

There's also a slight chance that this post will make other's that struggle feel better. I remember how complicated tooling almost deterred me from a career in software development ("if I can't even get a J2EE app configured and running, I probably shouldn't be a software developer").

<!--more-->

## Migrating to Xcode 8

This is a somewhat chronological sequence of various issues I encountered when updating our CI server to work (again) with Xcode 8.

#### 1. Broken Code Signing

Xcode 8 set out to fix one of the major tool annoyances that developers encounter: code signing. The "Fix issue" button has been removed and automatic code signing has been overhauled. You can enable it with a simple checkbock (which will trigger Xcode to generate provisioning profiles automatically):

![]()

However, this option is not compatible with `xcodebuild`. I haven't dug into the details, but when this option is checked you need to be signed into a development team so I believe the feature cannot be used on a CI machine from the command line.

Other folks ran into this issue as well: [here](https://github.com/fastlane/fastlane/issues/6055). You can just disable automatic code signing and select specific profiles as mentioned in the [fastlane codesigning docs](https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Codesigning/XcodeProject.md#readme).

However, this approach is not compatible with our current build configuration. We create various different PlanGrid builds (e.g. daily, release candidates, etc.) with slightly different configurations. As part of these configurations we change the bundle identifier to allow multiple builds to be installed on a device side by side.

In Xcode 7 we could use a script to rename the bundle identifier and the `Automatic` provisioning setting would pick the right provisioning profile based on the bundle identifier.

However, this option is no longer available in Xcode 8 (you can go fully automated or you need explicitly specify a profile for each target & build configuration).

I could work around this by defining an environment variable that specifies the correct provisioning profile for each lane and using that environment variable as part of the build configuration.

**First issue solved; this one was easy as I could reproduce it on a local machine.** At this point fastlane builds were passing locally, but for some misterious reason they were still failing on CI with the catchall error `Exit status: 65`.

**Takeaway 1:** It would be great if Apple would have documented if/how automatic signing should be used with `xcodebuild`. But admittedly our use case for changing bundle identifiers dynamically is a little unconventional (we could just have separate targets).

#### 2. Ruby Issues

At this point I was investigating our `buid_deploy_latest` lane, which runs whenever we merge to `dev`. It creates a build, ships it to HockeyApp, runs the test suite and reports code coverage to codecov.

This lane was failing on both steps (archiving & testing) on CI, while still passing locally. This was the error message in the CI build log:

![]()

In the past, `Exit status: 65` mostly meant codesigning issues, so I spent some time investigating in the wrong direction here. The log was claiming that a build script failure was failing the build. In particular the script that uploads our dSYM to Bugsnag.

For too long I assumed this error message to be incorrect. The Bugsnag script is one of the last steps before codesigning so I assumed Xcode is attributing the error incorrectly. Especially since it seemed extremely unlikely that a script that hasn't caused any issues so far would pass locally and fail on CI.

After spending too much time on investigating code signing as the potential issue, I found out that the build logs referred to additional log data in the `Derived Data` folder. 

I modified the Bitrise workflow to add a step that deployed the `Derived Data` folder to S3 after building (Bitrise offers a convenient "Artifact Deploy" step for this).

Within the `Derived Data` folder I found `.xcactivitylog` files. These log files capture the output that you can in the build log in the  Xcode IDE. StackOverflow told me that these are [files that can be unzipped](http://stackoverflow.com/questions/13861658/is-it-possible-to-search-though-all-xcodes-logs).

Luckily these logs contained a lot more details on the failed script phase:

![]()

The following line stands out as the root cause of the script failure:

```
Could not find json-1.8.3 in any of the sources (Bundler::GemNotFound)
```

At this point I found out that the Bitrise macOS image install the latest version of ruby from homebrew, which was version `2.3.1` while I was using the macOS system default: ruby `2.0.0`.

Looking at the stacktrace we can see that the scrupt is calling ruby `2.0.0`'s `require` function which is then calling the ruby `2.3.0` `bundler` gem. I'm tapping a little in the dark if this version mismatch is actually the root of the problem - if you're better versed in the ruby universe than I am, please drop a comment!

Using `brew unlink ruby` (thanks Bitrise support for the tip!) I was able to switch back to the system ruby on Bitrise and the error vanished!

I later switched to what I thought was a better fix (which wouldn't require updating all workflows to unlink brew's ruby). I noticed that the run script phase for the Bugsnag ruby script uses the `/usr/bin/ruby` shell command for invoking the script. This invokes the script with the system version of ruby. I changed the command to `/usr/local/bin/ruby` to ensure that the user version of ruby was used instead. This way ruby `2.3.1` was used to invoke run script.

**Takeaway 2:** Read xcodebuild's error messages exactly and believe them even though they can be off sometimes. Probably should also pin the ruby version used locally and on CI using `RVM` or `chruby` to avoid such mismatches in future.

#### 3. Xcode Test Manager Timeouts

This one is still a complete mistery to me. At this point I can run all lanes on fastlane locally. I can run `xcodebuild test` on Bitrise. However, running tests via fastlane on Bitrise is still failing. The failure only occurs in this combination. I've opened tickets with both tools - I'm aware that likely no one will feel responsible for fixing this since both tools work in isolation. But maybe someone else finds these issues useful? ([Bitrise](https://github.com/bitrise-io/bitrise.io/issues/66), [fastlane](https://github.com/fastlane/fastlane/issues/6111))

On the surface (xcodebuild output piped to fastlane/xcpretty) the error reporting is again very limited: `**TEST FAILED** and `Exit status: 65`:

![]()

I again resorted to investigating the `xcactivitylog` files; this time for the test activity instead of the build activity. From there it became pretty obvious what is happening:

![]()

For some reason the communication between `testmanagerd` Xcode and the Simulator is broken and timing out, which eventually causes the test suite to fail. For now my patience is over and I've replaced this particular fastlane step with a manual call to `xcodebuild test`.

**Takeaway 3:** Interop between various tools is the worst. If you encounter issues that only occur when you combine multiple tools together, it is very hard to narrow down the root cause. In this case it seems like an `xcodebuild` bug. Why is it only happening when using fastlane on Bitrise? I don't know (yet?).


#### 4. GitHub Request Timeouts &  HockeyApp Deploy Failure

Various builds would fail due to GitHub request timeouts that caused CocoaPods to fail. Sometimes uploads from Bitrise to HockeyApp would fail as well. Nothing to learn here, just want to demonstrate the amount of pain I went through:

![]()
![]()


## Conclusion

I should probably accept that our tools are complex and fragile and that a significant portion of my job responsibility is simply to keep things running as various tools change over time. 

However, I think working with `xcodebuild` is particular painful as it doesn't seem that Apple is focusing a lot of effort on it. There's barely any (up to date) documentation and logging is still a huge issue (which is why we need tools like xcpretty and fastlane in the first place.) Even if Apple wants to push Xcode server, they should still aknowledge that practically everyone is relying on `xcodebuild` as of today.

For CI providers it also can't help that macOS virtualization is still in its infancy. It seems to add further reliability issues. 

For now I'm hoping for a better future, while I work on improving my toolkit debugging skills.