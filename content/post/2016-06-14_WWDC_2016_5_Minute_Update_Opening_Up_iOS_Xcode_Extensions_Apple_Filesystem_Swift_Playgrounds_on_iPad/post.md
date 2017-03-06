+++
date = "2016-06-14T10:24:54-08:00"
draft = false
title = "WWDC 2016 5 Minute Update: Opening Up iOS, Xcode Extensions, Apple Filesystem, Swift Playgrounds on iPad"
slug = "wwdc-2016-open-ios-xcode-extensions-apple-file-system"
disqus_url = "http://blog.benjamin-encz.de/post/wwdc-2016-open-ios-xcode-extensions-update-apple-file-system/"
+++

A very brief summary of changes & impressions from WWDC 2016 Day One.

<!--more-->

## Opening up iOS

The most notable changes to iOS were the addition of many APIs and Extension points. Apple wants to allow developers to build apps that integrate stronger with system services:

- [SiriKit](https://developer.apple.com/library/prerelease/content/documentation/Intents/Conceptual/SiriIntegrationGuide/index.html#//apple_ref/doc/uid/TP40016875-CH11-SW1) will allow developers to integrate with Siri on iOS.
- iMessage now comes with its own App Store and the [Messages framework](https://developer.apple.com/reference/messages) that allows apps to enrich iMessage conversations.
- A new VOIP Api, [CallKit](https://developer.apple.com/reference/callkit) will allow third party apps to integrate with the native iOS calling experience (e.g. real ringtones, lock screen notifications on calls, integration with address book, etc.)
- Via [Map Extensions](https://developer.apple.com/maps/), Apple Maps is now open to third party integrations as well


## Xcode Extensions

Xcode 8 comes with support for Extensions. For now these extensions will be limited to the source editor itself. At the same time Apple is shutting down [Alcatraz](http://alcatraz.io/):

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/fzwob">@fzwob</a> Xcode 8 uses library validation. It won&#39;t load in-process plugins anymore.</p>&mdash; Joe Groff (@jckarter) <a href="https://twitter.com/jckarter/status/742471686935568384">June 13, 2016</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

I'm still glad to see an official (albeit for the time limited) API for building Xcode extensions. From the presentation it seemed clear that Apple wants to expand the scope of Xcode extensions quickly.

## New Apple Filesystem

While this won't affect most developers a lot, this is still an important step in modernizing Apple's Operating Systems and it will have benefits for users, such as much faster backups and copy-on-write clones. Ars Technica has a good writeup on the key features of [APFS](http://arstechnica.com/apple/2016/06/digging-into-the-dev-documentation-for-apfs-apples-new-file-system/). Apple has also published a [guide](https://developer.apple.com/library/prerelease/content/documentation/FileManagement/Conceptual/APFS_Guide/NewFeatures/NewFeatures.html#//apple_ref/doc/uid/TP40016999-CH3-SW1) that announces a release in 2017 and mentions that while there is no open source implementation for now, the APFS volume format specification will be published.

If you're curios why Apple needed a new file system you can read this blog post about some of the issues with the current [HFS+ file system](https://t.co/wB40yheV39).

## Swift Playgrounds on iPad

The new Swift Playgrounds app for iPad promises to be a great educational tool and demonstrates the emphasize that Apple has been putting on Swift as a beginner friendly language. The app will be open to third party educational content. 

Besides the compiler the app is also entirely written in Swift, which most likely makes it the largest in house Swift project at Apple to date.

## Xcode Memory Graph Debugger

This feature, announced during the State of the Union, had the largest *WOW* effect. Xcode 8 ships with a memory graph debugger that allows halting a program and inspecting a memory management graph at runtime. This will make tracking down retain cycles a lot easier in future. 

## Logging API

Apple has released a new [logging system](https://developer.apple.com/reference/os/1891852-logging). It's great to see such an important issue tackled by a first party API.

## Surprises: Machine Learning & Server Side Swift

To me, two surprises on the WWDC session schedule were:

- Session 415: Going Server-side with Swift Open Source
- Session 715: Neural Networks and Accelerate

It's great to see Apple so openly promote the use of Swift on other platforms. Being featured as part of WWDC gives the current efforts of building server side Swift frameworks a lot more credibility.

Apples new push into machine learning is also evident this year. I plan on attending the "Neural Networks and Accelerate" session; and it appears that Metal also provides new APIs relevant to machine learning:

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Metal now has a set of comprehensive APIs for building convolutional neural networks. <a href="https://t.co/BppyeRJurJ">https://t.co/BppyeRJurJ</a> <a href="https://t.co/syfbUy63Jm">pic.twitter.com/syfbUy63Jm</a></p>&mdash; Indragie Karunaratne (@indragie) <a href="https://twitter.com/indragie/status/742484067996704768">June 13, 2016</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

It seems that Apple is pioneering on device machine learning which goes hand in hand with their privacy efforts (e.g. Differential Privacy). I'm very curios to see if it possible to create great results in machine learning while maintaining users privacy. 