+++
date = "2015-02-19T22:24:54-08:00"
draft = false
title = "Breaking Swift with NSObject and Generics"
+++

Today, while trying to implement a generic data source in Swift, I ran into my first Swift compiler segmentation fault, yay (looking at [Open Radar](http://openradar.appspot.com/search?query=segmentation+fault+swift) there seem to be many out there)!

Here's what I was trying to implement

    public class ArrayDataSource<T> : NSObject {
    
      private var array: Array<T>
      
      public init(array:Array<T>) {
        self.array = array
      }
    }
    
    
    extension ArrayDataSource : UITableViewDataSource {
      public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
      }
      
      public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
      }
    }
    
A class that takes an array and implements `UITableViewDataSource` using the content of that array (an idea that's discussed in [objc.io issue #1](http://www.objc.io/issue-1/lighter-view-controllers.html)). 

#The Error

As you can see I didn't get very far before running into the compiler error. When you compile the above code (in Xcode 6.1.1 or Xcode 6.3) you'll see the following error message:

    Segmentation Fault 11: While emitting IR for source file /Users/benjaminencz/Development/Private/OSS/ListKitDemo/ListKit/ArrayDataSource.swift
    
Along with a nice stack trace from swift compiler:

![](https://dl.dropboxusercontent.com/u/13528538/Blog/Swift_Crash.png)

#Finding a generic reproducable example

Since this issue exists in both Xcode 6.1.1 and Xcode 6.3 I wanted to file a bug report to make sure this gets resolved in future. I played around with different ways to fix the issue, here are two simple ones that worked:

- Move the conformance to the `UITableViewDataSource` protocol into the class definition instead of the class extension
- Remove the generic type from `ArrayDataSource`

To actually file a bug report I needed to come up with a generalized, short piece of code that can reproduce the issue. After trying multiple combinations I found this to be the one that describes the problem best:

	public class D<T>: NSObject {}

	extension D: NSObjectProtocol {}

These two lines are enough code to cause the segmentation fault. The underlying issue seems to be a combination of subclassing from `NSObject`, using generics and conforming to `NSObjectProtocol` in a class extension while the actual implementation of `NSObjectProtocol` happens through inheritance of `NSObject`. 

I couldn't get this minimalistic example to break with any other combination of protocols and subclassing, it seems to be a problem specific to `NSObject`. If you find a more general case that causes the segmentation fault, I'd love to hear from you.

For now I have filed a bug report with Apple (19889552) and an [Open Radar Issue](http://openradar.appspot.com/19889552).