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

#### Let the Guesswork begin

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
Up until `frame #11` we're only seeing code that is necessary to set up the example project. `frame #10` is the actual starting point for our investigation. It is called whenever a new subview is added and it eventually results in a call to the `_UITintColorVisitor`. 

What is interesting is that `addSubview` is only ever called on our root view, but the `_UITintColorVisitor` is called for all of the subviews of that root view. The cause of this problem must lie somewhere between `frame #11` and `frame #0`.

At this point it was not obvious to me why all views were being caused to be visited; at the very end of the next section I might have a likely answer to that question...

#### Digging Deeper

Since I hit a dead end in identifying why all subviews in the view hierarchy were constantly being revisited, I decided to investigate another interesting aspect about this problem that profiler had revealed.

Earlier we identified that about 25% of the total time is taken up in calls to `[NSArray containsObject:]` which is called as part of the implementation of `[_UITintColorVisitor visitView:]`. I have used [Hopper Disassembler](http://www.hopperapp.com/) to try to understand why that's the case. Hopper has a handy feature that can generate pseudo code from a disassembled binary, which makes it somewhat easier to try and grasp the control flow of a program (if, like me, you're mostly unfamiliar with assembly code).

Here's what the relevant pseudo code looks like:

![](https://dl.dropboxusercontent.com/u/13528538/Blog/UITintColorVisitor/visit-view-pseudo-code.png)

As part of stepping through the assembly code I have identified a few things that are relevant to this snippet:

- One `_UITintColorVisitor` instance is used to visit all views (at least in this simple example with only one view hierarchy)
- The `_UITintColorVisitor` has a few properties that are persisted between the different invocations of `visitView:`. Here's an overview of all properties found in Hopper:
	- ![](https://dl.dropboxusercontent.com/u/13528538/Blog/UITintColorVisitor/tint-color-visitor-properties.png)
	
From stepping through the assembly code and investigating different registires I could identify that in the above pseudo code `eax` refers to the `_originalVisitedView` and `edi` refers to the view that is currently being visited.

This means, that as soon as a `_UITintColorVisitor` has an original visited view (which is true after it visited it's first view), the outlined code checks if the `subviews` array of the `originalVisitedView` contains the currently visited view. This check scans the full array of subviews; in cases where the `originalVisitedView` is our root view, the cost of this operation grows linearly with the amount of added subviews.

I investigated this further by creating another breakpoint in UIKit at the point where this check takes place. When disassembling the 32-Bit slice of UIKit and running the app in 32-Bit mode, the adress offsets align nicely. Based on the `loc_4956fd` in Hopper I created the new breakpoint like this:

```
b 0xe4b6fd
```
(By creating a breakpoint in `-[_UITintColorVisitor visitView:]` I could compare the assembly & addresses in the debugger and in Hopper and identify that the addresses match up when replacing the `495` in the hopper address with `0xe4b`). 

Within the breakpoint I printed both the `eax` register and the `_originalVisitedView` of `self` (which is stored in the `ebx` register):

```
(lldb) po $eax
<UIView: 0xc131830; frame = (0 0; 768 1024); autoresize = W+H; tintColor = UIDeviceRGBColorSpace 0 0 1 1; layer = <CALayer: 0xc1176d0>>

(lldb) po [$ebx valueForKey:@"_originalVisitedView"]
<UIView: 0xc131830; frame = (0 0; 768 1024); autoresize = W+H; tintColor = UIDeviceRGBColorSpace 0 0 1 1; layer = <CALayer: 0xc1176d0>>
```

With this approach I identified that with the current sample code, `eax` **always refers to the root view**. This means we are iterating over all subviews of the root view, N times for each subview that is added. 

I'm no expert in complexity analysis but it appears that the total cost of `[_UITintColor visitView:]` sums up to `n^2`:

(**n** invocations of `[_UITintColor visitView:]`) * (**n** cost of iterating all subviews) where **n** = amount of added subviews

**But why do we have these two code paths outlined above in the first place**? Why do we need to check if the currently visited view is a subview of the original visited view?

In both cases, whether it is a subview or not, we end up calling: ` ___34-[_UITintColorVisitor _visitView:]_block_invoke`. In the case of the currently visited view being a subview of the original visited view, we pass two arguments to the block, in the other case we pass only one.

By double-clicking onto the block in Hopper we can jump into the called code; it looks as following:

![](https://dl.dropboxusercontent.com/u/13528538/Blog/UITintColorVisitor/called-block.png)

In this piece of code `ebx` refers to the `UIView` instance that is being visited and `*(esi + 0x14)` refers to the tint color visitor.

Using the address translation technique from earlier I decided to create the following breakpoint to jump into this block:

```
(lldb) b 0xe4b7ee
```
The code seems to switch over the `_reasons` property of the `[_UITintColorVisitor]` and some properties of the visited view.

After stepping through the prolog we can investiage the relevant values:

```
po [*(id *)($esi+0x14) valueForKey:@"_reasons"]
1
```
The `_reasons` property seems to store a bitmask value. Our bitmask is set to `1` which means that the first block will run if the views `_interactionTintColor` is `nil`.

Inside of this block we finally might find the magical key to solving this puzzle:

```
[ebx _setAncestorDefinesTintColor:eax];
```

Here UIKit is marking this view, noting that its parent is defining a tint color. I'm assuming that this flag is what registers this view in some way to be visited by the `_UITintColorVisitor`, since we are passing it as an argument to the `_setAncestorDefinesTintColor` method.

The big question remains why this is flag is set every single time the view is visited and not only in cases where the subview has moved in the view hierarchy or when the parent view changes its tint color - but that mistery will most likely remain unsolved.

This also solves the big question of the two code paths in the piece of code that calls into this block that we examined earlier:

![](https://dl.dropboxusercontent.com/u/13528538/Blog/UITintColorVisitor/visit-view-pseudo-code.png)

If the currently visited view is not a child view of the original visited view, we don't pass a second argument to this block; which is equivalent to passing `nil`. This means that `ebx` will be `nil`, which in turn means we will never call `[ebx _setAncestorDefinesTintColor:eax];`.

# Conclusion

When I started out diving into this issue I was almost entirely clueless about how to interpret disassembled code; and now I still mostly am. However, I learned a few very handy tricks along the way:

- I learned how to set breakpoints in private methods & and at any address within the assembly code.
- I learned about the x86_32 and Objective-C calling conventions, e.g. which arguments are stored in which registers.
- I learned that the addresses in Hopper match the addresses in the actual framework code (besides a base pointers offset depending on where UIKit is loaded into memory). In hindsight this sounds obvious but it definitely was not the case when starting out. [This article](http://www.bartcone.com/new-blog/2014/11/26/hopper-lldb-for-ios-developers-a-gentle-introduction) was very helpful in getting more comfortable with working with lldb in UIKit alongside of Hopper.

These three tools allowed me to explore the code paths & relevant variables a lot faster which in turn made it a lot easier (yet still hard) to get a grasp of what was going on.

In the end I didn't find a definite answer on how this issue could be fixed, but I found a lot of clues about how the current visitor pattern is implemented and I think I got fairly close to the underlying issue.

Most importantly I learned how to be more efficient at exploring the inner workings of closed source frameworks which will surely come in handy in future! Attempting to reverse engineer code can be very intimidating and the learning curve is really steep. I hope some day when I have a better grasp myself I can share a beginner friendly guide on all of this!

---

Thanks a lot to Russ Bishop who tracked down the original issue together with me. He has also filed a radar (fingers crossed)!
