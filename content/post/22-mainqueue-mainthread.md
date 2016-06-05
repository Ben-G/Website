+++
date = "2016-06-05T10:24:54-08:00"
draft = false
title = "GCD's Main Queue vs. Cocoa's Main Thread"
slug = "main-queue-vs-main-thread"
disqus_url = "http://blog.benjamin-encz.de/post/main-queue-vs-main-thread/"
+++

The correct way to ensure that code runs on the main thread / main queue is a recurring issue that causes some confusion among Cocoa developers. 
The topic came up again this week as part of an issue with ReactiveCocoa and MapKit: 

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Apple DTS “explicitly stated that main queue and the main thread are not the same thing, have subtle differences”. <a href="https://t.co/YxAbqkvtse">https://t.co/YxAbqkvtse</a></p>&mdash; Ole Begemann (@olebegemann) <a href="https://twitter.com/olebegemann/status/738656134731599872">June 3, 2016</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

<!--more-->

## The Problem

When interacting with certain frameworks, e.g. UIKit, we need to ensure that all calls into the framework happen from the main thread.
Typically we have some sort of check to determine whether our code is already executing on the main thread or whether we are on a background thread and actively need to dispatch to the main thread. 

Let's take a function that generates an image as a trivial example:

{{< highlight swift >}}
func createImageUnsafe(filename: String) -> UIImage? {
    // TODO: Check for Main Thread
    return UIImage(contentsOfFile: filename)
}
{{< /highlight >}}

## The Easy Solution

The easiest way to check if we are currently executing on the main thread is using `NSThread.isMainThread()` - GCD lacks a similarly convenient API for checking if we are running on the main queue, so many developers use the `NSThread` API instead. Our updated function will look somewhat like this:

{{< highlight swift >}}
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
{{< /highlight >}}

This works in most cases, [until it doesn't](https://github.com/ReactiveCocoa/ReactiveCocoa/issues/2635#issuecomment-170215083). Here's the excerpt from the issue on the ReactiveCocoa repo:
![](https://raw.githubusercontent.com/Ben-G/HugoBlog/master/public/assets/mainqueue-mainthread/rac_issue_queue_thread.png)

**The underlying problem is that the `VektorKit` API is checking if it is being called on the main queue instead of checking that it is running on the main thread.** This issue has also been filed as a [radar](http://www.openradar.me/24025596).

**While every app will ever only have one main thread, it is possible for many different queues to execute on this one main thread.**

Calling an API from a non-main queue that is executing on the main thread will lead to issues if the library (like VektorKit) relies on checking for execution on the main queue.

It is surprisingly easy to get a non-main queue to execute on the main thread. While doing some research for this post I found a commit to `libdispatch` that [ensures that blocks dispatched with `dispatch_sync` are always executed on the current thread](https://libdispatch.macosforge.org/trac/changeset/156). This means if you use `dispatch_sync` to dispatch a block from the main queue to a concurrent background queue, the code executing on the background queue will actually be executed on the main thread. While this might not be entirely intuitive, it makes sense: since the main queue needs to wait until the dispatched block completed, the main thread will be available to process blocks from queues other than the main queue.

## The Safer Solution

Technically I think this is a MapKit / VektorKit bug, Apple's UI frameworks typically guarantee to work correctly when being called from the main thread, no part of the documentation mentions that code needs to be executed on the main queue.

However, now that we know that certain APIs rely not only on running on the main thread, but also on the main queue, it is safer to check for the current queue instead of checking for the current thread.

Checking for the current queue also makes better use of the abstraction that GCD provides over threading. Technically we shouldn't know/care that the main queue is a special kind of queue that is always bound to the main thread.

Unfortunately GCD doesn't have a very convenient API for checking for the queue we're currently running on (which most likely is the reason why many developers use `NSThread.isMainThread()` in the first place).

We need to use the `dispatch_queue_set_specific` function in order to associate a key-value pair with the main queue; later we can use `dispatch_queue_get_specific` to check for the presence of key & value. Here's the updated image function example:

{{< highlight swift >}}
private let mainQueueKey = UnsafeMutablePointer<Void>.alloc(1)
private let mainQueueValue = UnsafeMutablePointer<Void>.alloc(1)

// Associate a key-value pair with the main queue
dispatch_queue_set_specific(
    dispatch_get_main_queue(), 
    mainQueueKey, 
    mainQueueValue, 
    nil
)

func createImage(filename: String) -> UIImage? {
    var image: UIImage? = nil

    // Check for presence of key-value pair on current queue
    if (dispatch_get_specific(mainQueueKey) == mainQueueValue) {
        // if we found right value for key, execute immediately
        image = UIImage(contentsOfFile: filename)
        print("main queue")
    } else {
        // otherwise dispatch on main queue now
        dispatch_sync(dispatch_get_main_queue()) {
            image = UIImage(contentsOfFile: filename)
            print("not main queue")
        }
    }

    return image
}
{{< /highlight >}}

Both, key and value are simple `Void` pointers - we only need to use them for an equality check. 

The function above will now not only check that we're running on the main thread, but also ensure we're on the main queue.

## Conclusion

By combining GCD and Cocoa's `NSThread` API we are drilling through the abstraction that CGD should provide in the first place. APIs that fully rely on GCD and ignore the presence of the underlying threads can run into problems if you call them on the main thread but not the main queue. This means, especially when calling into other frameworks, we should prefer using `dispatch_queue_set_specific` and `dispatch_get_specific` to check if our code is running on the main queue over using `NSThread.isMainThread()`.

**Other Blog Posts:**

- @[krzyzanowskim](https://twitter.com/krzyzanowskim) has written a [great blog post about the relationship of threads, queues and runloops](http://blog.krzyzanowskim.com/2016/06/03/queues-are-not-bound-to-any-specific-thread/)
