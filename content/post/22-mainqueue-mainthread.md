+++
date = "2016-06-05T10:24:54-08:00"
draft = true
title = "GCD's Main Queue vs. Cocoa's Main Thread"
slug = "main-queue-vs-main-thread"
disqus_url = "http://blog.benjamin-encz.de/post/main-queue-vs-main-thread/"
+++

The correct way to ensure that code runs on the main thread / main queue is a recurring issue that causes some confusion among Cocoa developers. 
The topic came up again this week as part of an issue with ReactiveCocoa and MapKit: 

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Apple DTS “explicitly stated that main queue and the main thread are not the same thing, have subtle differences”. <a href="https://t.co/YxAbqkvtse">https://t.co/YxAbqkvtse</a></p>&mdash; Ole Begemann (@olebegemann) <a href="https://twitter.com/olebegemann/status/738656134731599872">June 3, 2016</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

<!--more-->

##The Problem

When interacting with certain frameworks, e.g. UIKit, we need to ensure that all calls into the framework happen from the main thread.
Typically we have some sort of check to determine whether our code is already executing on the main thread or whether we are on a background thread and actively need to dispatch to the main thread. Let's take a function that generates an image as a trivial example:

```swift
func createImageUnsafe(filename: String) -> UIImage? {
    // TODO: Check for Main Thread
    return UIImage(contentsOfFile: filename)
}
```
##The Easy Solution

The easiest way to check if we are currently executing on the main thread is using `NSThread.isMainThread()` - GCD lacks a similarly convenient API for checking if we are running on the main queue, so many developers use the `NSThread` API instead. Our updated function will look somewhat like this:

```swift
func createImage(filename: String) -> UIImage? {
    var image: UIImage?

    if NSThread.isMainThread() {
        image = UIImage(contentsOfFile: filename)
    } else {
        dispatch_sync(dispatch_get_main_queue()) {
            image = UIImage(contentsOfFile: filename)
        }
    }

    return image
}
```

This works in most cases, [until it doesn't](https://github.com/ReactiveCocoa/ReactiveCocoa/issues/2635#issuecomment-170215083):

 

##The Correct Solution

##Conclusion

By combining GCD and Cocoa's `NSThread` API we are drilling through the abstraction that CGD should provide in the first place. APIs that fully rely on GCD and ignore the presence of the underlying threads can run into problems if you call them on the main thread but not the main queue. This means we should always be using `dispatch_queue_set_specific` and `dispatch_get_specific` to check if our code is running on the correct queue.

**Other Blog Posts:**

- @[krzyzanowskim](https://twitter.com/krzyzanowskim) has written a [blog post about the relationship of threads, queues and runloops](http://blog.krzyzanowskim.com/2016/06/03/queues-are-not-bound-to-any-specific-thread/)
