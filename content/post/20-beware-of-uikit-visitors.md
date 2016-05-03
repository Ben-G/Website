+++
date = "2016-04-27T22:24:54-08:00"
draft = true
title = "Beware the UIKit Visitors!"
slug = "beware-the-uikit-visitors"
disqus_url = "http://blog.benjamin-encz.de/post/beware-the-uikit-visitors/"
+++

Yesterday we identified a performance regression in the PlanGrid app, when entering a view that dynamically adds a large amount of subviews.

I was able to reproduce this issue with the following lines of code:

```swift
// In AppDelegate:
self.window?.tintColor = .redColor()

// In UIViewController:
override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    for i in 1..<1000 {
        let view = UIView()
        self.view.addSubview(view)
    }
}
```
The above example is obviously extreme, but it reveals an interesting performance issue.

Long story short, here's what we could identify within Instrument's time profiler:
![](https://dl.dropboxusercontent.com/u/13528538/Blog/UITintColorVisitor/tint-color-visitor-highlight.png)

A majority of the time is adding subviews is spent within `[_UITintColorVisitor _visitView:]`. In this example it's 64% of the time; and the proportion only increases with the amount of subviews we're adding (Adding 10,000 views takes a little more than 3 minutes on the latest iPad Pro).

We like our custom tint color; but not enough to justify such an impact on performance. **By deactivating the custom tint color we bring the overall run time of `viewDidAppear` from our example project from over 700ms down to ~10ms.**

The same affect can be accomplished by specifying the `tintColor` on each view we're adding, which stops the expensive `_UITintColorVisitor` from stopping by.

##How Could this Happen?

Finding a workaround for this issue is only half of the fun. Let's try to find out what exactly is causing these poor performance characteristics. We can start by taking a closer look at the time profiler output:

![](https://dl.dropboxusercontent.com/u/13528538/Blog/UITintColorVisitor/focus-tint-color-visitor.png)

We can see that the app doesn't spend too much time in `[_UITintColor _visitView]` itself. The majority of the time is consumed by `objc_msgSend` which simply indicates that this method is being called very, very often. Further, we're spending a lot of time in `[NSArray containsObject:]` which means that the array might be accessed too often in the first place, or that a data structure that is more efficient for lookups should be used instead of an array (e.g. a dictionary or a set).

```assembly
loc_4956fd:
    stack[2023] = edi;
    if ([[eax subviews] containsObject:stack[2023]] != 0x0) {
            eax = ebx->_changedSubview;
            if (eax != 0x0) {
                    if (eax == edi) {
                            ___34-[_UITintColorVisitor _visitView:]_block_invoke(__NSConcreteStackBlock, edi);
                    }
            }
    }
    else {
            ___34-[_UITintColorVisitor _visitView:]_block_invoke(__NSConcreteStackBlock, edi, stack[2023]);
    }
    goto loc_49575a;
```

Thanks a lot to Russ Bishop who tracked down this issue together with me. He has also filed a radar: (fingers crossed).