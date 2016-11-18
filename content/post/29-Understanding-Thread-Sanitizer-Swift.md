+++
date = "2016-11-18T22:24:54-08:00"
draft = false
title = "Understanding Data Race Detection by Implementing it in Swift"
slug = "understanding-data-race-detection-by-implementing-in-swift"
disqus_url = "http://blog.benjamin-encz.de/post/[.DS_Store](https://github.com/Ben-G/ThreadSanitizerSimulator/blob/full-implementation/.DS_Store)/"
+++

TL;DR: In order to learn more about how Thread Sanitizer's data race detection works I've implemented a very simple version in Swift. [You can find it on GitHub](https://github.com/Ben-G/DataRaceDetector).

---

We all know concurrency is hard. It's easy to make mistakes when attempting to synchronize access to shared resources and the resulting issues are often extremely hard to reproduce and debug.

So I was very excited when I learned about data race detection in LLVM's Thread Sanitizer in this year's WWDC Session 412.

Thread Sanitizer is a runtime analyzer that (among other things) detects the potential for data races. It ships with Xcode 8 and supports C++, Objective-C and Swift >= 3.0.

*(In case you haven't heard the term data race before: a data race is a condition in concurrent code where multiple threads read/write to/from a shared memory location without being synchronized by some locking mechanism. These races can lead to crashes or unexpected behavior).*

The astonishing aspect of Thread Sanitizer is that it detects the potential for data races without needing them to actually occur. This means you'll no longer need to run your app or your tests hundreds of times trying to reproduce data races.

**What's the secret sauce that makes this possible?**

Thread Sanitizer was originally developed by Google, and they published a paper that describes the algorithm in detail [here](http://static.googleusercontent.com/media/research.google.com/en//pubs/archive/35604.pdf) (if you're not a fan of reading dense papers that include formal logic, rather stick with this blog post and the Swift code on GitHub). 

The data race detection uses a general algorithm named [vector clock](https://en.wikipedia.org/wiki/Vector_clock). In WWDC Session 412 an Apple engineer does a great job at describing the general algorithm in simple terms. [Here's the relevant part of the session]([https://developer.apple.com/videos/play/wwdc2016/412/?time=993](https://developer.apple.com/videos/play/wwdc2016/412/?time=993).

**Here's the gist of how it works:** 

When run with Thread Sanitizer, LLVM instruments your code such that all accesses to memory locations are recorded. With this recording, Thread Sanitizer keeps track which memory locations have been accessed by which threads. 

Each thread stores a counter for each memory location (that's the *vector clock*) that gets increased every time the thread accesses the memory location. Whenever an access to a memory location occurs, the counter of the currently active thread is also stored in storage that is associated with the memory location. Thus the memory location has the latest values of the counters of all threads that have ever accessed it.

A thread does not only keep track of its own counter value; it also stores the counter values of all the other threads that are accessing the same memory location (in practice there's an upper bound to the amount of threads that are tracked to avoid excessive memory consumption). However, a thread only gets access to the counter values of other threads when a synchronization event occurs (i.e. when a mutex or a serial dispatch queue is used) before a value is accessed.

This aspect of the algorithm can be used to detect data races when a memory location is being accessed. The algorithm compares the counters for *all* threads that are stored alongside the memory location with the counters of all threads that are stored as part of the *currently active thread*. If any of the values are out of sync, we have detected the potential for a data race, since we can assume that the currently active thread has concurrently accessed a shared memory location without using a synchronization mechanism. 

This description skips over some details that you can find in my Swift implementation and its documentation.

**Implementation in Swift:**

As a fun little exercise that helped me understand this algorithm better, I've implemented a simplified [data race detection algorithm in Swift. You can find it on GitHub](https://github.com/Ben-G/DataRaceDetector). I've added test cases and a whole bunch of documentation, so that I'll be able to remember how this thing works a few weeks from now. If you're curious to learn more about the details of the algorithm they might be interesting to you, too!