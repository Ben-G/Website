+++
date = "2015-07-09T22:24:54-08:00"
draft = false
title = "iOS 9 Detects Cycles in Layout Trees"
disqus_url = "http://blog.benjamin-encz.de/ios-9-detects-cycles-in-layout-trees/"
slug = "ios-9-detects-cycles-in-layout-trees"
+++

A couple of months ago I was faced with an issue that was fairly hard to debug:

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">Hackathons are a great place to see noteworthy issues. Yesterday&#39;s highlight: endless recursion in Storyboard <a href="https://twitter.com/LAHacks">@LAHacks</a></p>&mdash; Benjamin Encz (@benjaminencz) <a href="https://twitter.com/benjaminencz/status/584757451469127680">April 5, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

<!--more-->

What I found out, after about 30 minutes of debugging, was the following:

![](https://www.dropbox.com/s/kcjgm6sgftmxo5y/accessoryView.png?dl=1)

The hackathon attendee hat mistakenly set the `accessoryView` of a `UITableViewCell` to the `UITableView` in which the cell was contained - causing an endless recursion during the first layout cycle.

This however wasn't immediately obvious to me since the symptom was an exception within the `cellForRowAtIndexPath:` method.

## Fixed in iOS 9

Today I wanted to see if it is possible to reproduce the issue with Xcode 7 Beta 3.

Indeed, I can still cause the crash. However, instead of causing a stack overflow the app now terminates because `CALayer` throws an exception:

```
CrashTableViewCell[33582:11713163] *** Terminating app due to uncaught exception 'CALayerInvalid', reason: 'layer <CALayer: 0x7f875943c730> is a part of cycle in its layer tree
```

I couldn't find any reference to this exception in a Stack Overflow exception so I assume the cycle detection is new in iOS 9.

This fix will likely save some headaches!

It also serves as a good real world example of [detecting cycles in directed graphs](https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm).
