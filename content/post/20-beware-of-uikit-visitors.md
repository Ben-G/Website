+++
date = "2016-04-27T22:24:54-08:00"
draft = true
title = "Beware the UIKit Visitors!"
slug = "beware-the-uikit-visitors"
disqus_url = "http://blog.benjamin-encz.de/post/beware-the-uikit-visitors/"
+++

~~Yesterday~~ Two weeks ago we identified a performance regression in the PlanGrid app, when entering a view that dynamically adds a large amount of subviews.

I was able to reproduce this issue with the following lines of code:

```swift
override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.view.tintColor = .blueColor()

        for i in 1..<10000 {
            let view = UIView()
            self.view.addSubview(view)
        }
    }
```
The above example is obviously extreme, but it reveals an interesting performance issue: when setting a `tintColor` on a parent view, and not setting an explicit color on child views the performance of `addSubview` reduces itself drastically with a large amount of added subviews.

Here's what we could identify within Instrument's time profiler:
![](https://dl.dropboxusercontent.com/u/13528538/Blog/UITintColorVisitor/tint-color-visitor-highlight.png)

A majority of the time is adding subviews is spent within `[_UITintColorVisitor _visitView:]`. In this example it's 64% of the time; and the proportion only increases with the amount of subviews we're adding (Adding 10,000 views takes a little more than 3 minutes on the latest iPad Pro).

We like our custom tint color; but not enough to justify such an impact on performance. **By deactivating the custom tint color we bring the overall run time of `viewDidAppear` from our example project from over 700ms down to ~10ms.**

The same affect can be accomplished by specifying the `tintColor` on each view we're adding, which stops the expensive `_UITintColorVisitor` from stopping by.

## Digging into UIKit

Finding a workaround for this issue is only half of the fun. Let's try to find out what is causing these poor performance characteristics in the first place. We can start by taking a closer look at the time profiler output:

![](https://dl.dropboxusercontent.com/u/13528538/Blog/UITintColorVisitor/focus-tint-color-visitor.png)

We can see that the app doesn't spend too much time in `[_UITintColor _visitView]` itself. The majority of the time is consumed by `objc_msgSend` which simply indicates that this method is being called very, very often. Further, we're spending a lot of time in `[NSArray containsObject:]` which means that the array might be accessed too often in the first place, or that a data structure that is more efficient for lookups should be used instead of an array (e.g. a dictionary or a set).

### Breakpoints in Framework Functions

We can start by setting a breakpoint within the `[_UITintColor _visitView]` method; that will give us an idea of how often that method is called.

We can do that by setting a breakpoint early in our program to bring up the lldb console (alternatively we could use lldb from the terminal). Then we can enter the following command to set a breakpoint:

```
(lldb) b -[_UITintColorVisitor _visitView:]
```
Now we can continue execution; soon we should trap into our breakpoint. Checking how often this method is called, I quickly identified that the amount of calls grows with the amount of subviews we have added. As a next step I wanted to see which views exactly are being visited. For that we need to dive into a little bit of assembly code.

### Inspecting the Assembly Code

When stepping into the breakpoint in `-[_UITintColorVisitor _visitView:]` you are greeted with a cryptic wall of assembly code. I started out with very barebones knowledge of understanding/investigating complex assembly code, but this bug forced me to learn some tricks that hopefully are useful to you as well!

#### Configuring for 32-Bit

As a first step, let's ensure that our app runs in **32-Bit** mode in the simulator. This architecture is known as **x86_32**. We choose to run the app in 32-Bit mode since x86_32 has a simpler way of passing function arguments (which will come in handy shortly). In Xcode 7 you can run on x86_32 by selecting the *iPad 2* simulator.

With this setup in place, we can now inspect which views are visited from within our breakpoint in `-[_UITintColorVisitor _visitView:]`. Looking at the method signature we can see that this method takes on argument: the view that is being visited. That's the information that we would like to inspect further. In addition to that argument every method call in Objective-C receives `self` as the first argument and the `selector` as the second argument.

#### Printing Function Arguments in Assembly

By using [this handy reference](https://www.clarkcox.com/blog/2009/02/04/inspecting-obj-c-parameters-in-gdb/) we can look up where these arguments are stored when a method is called (the reference is old and mentions `gdb` instead of `lldb`, but the info is still up to date.). The order of these arguments is part of what we call a "calling convention". It states for i386 (which is equivalent to x86_32) arguments are passed as follows:

- Before prolog:
	- *($esp+4n) ➡ arg(n)	
- After prolog:
	- *($ebp+8+4n) ➡ arg(n)
	
Without getting into too much detail at this point: the "prolog" is a sequence at the beginning of a function call that configures the stack pointer and different stack variables. The variable locations for our function arguments are different before and after the prolog. All arguments are offset from the base address that is stored in the `esp` register.

For now we'll use the addresses before the prolog, since we'll access the arguments as soon as we trap into our breakpoint at the beginning of the `-[_UITintColorVisitor _visitView:]` method.

When we reach that breakpoint we can print all 3 arguments to our function call as following:

```
(lldb) po *(id *)($esp+4)
<_UITintColorVisitor: 0xc502540>

(lldb) po *(SEL *)($esp+8)
"_visitView:"

(lldb) po *(id *)($esp+12)
<UIView: 0xc131830; frame = (0 0; 768 1024); autoresize = W+H; tintColor = UIDeviceRGBColorSpace 0 0 1 1; layer = <CALayer: 0xc1176d0>>
```	

Now we can use this new ability to print the visited view every single time we step into our breakpoint: `po *(id *)($esp+12)`.

Using this technique I identified that after a new subview is added, the parent view and all of its children are passed to calls of `-[_UITintColorVisitor _visitView:]`. This means the complexity of adding a subview with no tint color to a parent view with a tint color is O(n^2) - for each added view UIKit will iterate all of its siblings.

Why exactly is that happening in that case? I have not yet been able to track it down definitely, but I have a bunch more clues that I'd like to share.

#### Guessing Rather Than Giving Up

Since we want to know why the `_UITintColorVisitor` is called so frequently, it makes sense to start by investigating the backtrace. We can do this as well with an lldb command that we can invoke while halted at the breakpoint:

```
(lldb) bt
* thread #1: tid = 0x156ea9, 0x00e4b61c UIKit`-[_UITintColorVisitor _visitView:], queue = 'com.apple.main-thread', stop reason = breakpoint 9.1
  * frame #0: 0x00e4b61c UIKit`-[_UITintColorVisitor _visitView:]
    frame #1: 0x00e4bfbb UIKit`_UIViewVisitorEntertainVisitors + 107
    frame #2: 0x00e4af30 UIKit`_UIViewVisitorRecursivelyEntertainDescendingVisitors + 162
    frame #3: 0x00e4a8ca UIKit`_UIViewVisitorEntertainDescendingTrackingVisitors + 705
    frame #4: 0x00e4a2be UIKit`_UIViewVisitorEntertainHierarchyTrackingVisitors + 58
    frame #5: 0x00a9ce3f UIKit`__45-[UIView(Hierarchy) _postMovedFromSuperview:]_block_invoke + 268
    frame #6: 0x005b1440 Foundation`-[NSISEngine withBehaviors:performModifications:] + 150
    frame #7: 0x005b491c Foundation`-[NSISEngine withAutomaticOptimizationDisabled:] + 48
    frame #8: 0x00a9cce4 UIKit`-[UIView(Hierarchy) _postMovedFromSuperview:] + 521
    frame #9: 0x00aac7f1 UIKit`-[UIView(Internal) _addSubview:positioned:relativeTo:] + 2367
    frame #10: 0x00a9acc8 UIKit`-[UIView(Hierarchy) addSubview:] + 56
    frame #11: 0x00002be9 CopyOnWriteClosures`ViewController.viewDidAppear(animated=false, self=0x0c72cce0) -> () + 825 at ViewController.swift:40
    frame #12: 0x00002cbf CopyOnWriteClosures`@objc ViewController.viewDidAppear(Bool) -> () + 63 at ViewController.swift:0
	
	// ...
	
    frame #27: 0x009dfeb9 UIKit`UIApplicationMain + 160
    frame #28: 0x00004411 CopyOnWriteClosures`main + 145 at AppDelegate.swift:12
    frame #29: 0x0291ca25 libdyld.dylib`start + 1
(lldb) 
```
Up until `frame #11` we're only seeing code that is necessary to set up the example project. `frame #10` is the actual starting point for our investigation. It is called whenever a new subview is added and it eventually results in a call to the `_UITintColorVisitor`. What is interesting is that `addSubview` is only ever called on the parent view of an added view but the `_UITintColorVisitor` is called with all of the subviews of that parent view. The cause of this problem must lie somewhere between `frame #11` and `frame #0`.

Looking at the full stack trace we can identify that the `_UITintColorVisitor` is called in response to the `


Thanks a lot to Russ Bishop who tracked down this issue together with me. He has also filed a radar: (fingers crossed).