+++
date = "2014-06-03T22:24:54-08:00"
draft = false
title = "Arithmetic Expressions in Swift"
disqus_url = "http://blog.benjamin-encz.de/arithmetic-expressions-in-swift/"
slug = "arithmetic-expressions-in-swift"
aliases = ["/arithmetic-expressions-in-swift/"]
+++

While I still cannot fully understand how the release of a new programming language didn't leak before WWDC, most of us got surprised by the announcement of Apple's new Programming Language **Swift**.

Like most iOS Developers I immediately took a look at the new language. Most language details seem fairly straightforward - however, arithmetic expressions were the first small pitfall for me.

<!--more-->

If you for example try to run the following lines of code:

{{< highlight swift >}}
// assume margin needs to be of type Float
var margin :Float
var elements = 3

margin = CGRectGetWidth(self.view.frame) / elements
{{< /highlight >}}

You will receive a very technical error message (nearly as cryptic as the GCC error messages back in the old days):
> Could not find an overload for '/' that accepts the supplied arguments

What the Swift compiler is telling us, is that it cannot divide the `Float` on the the left side of the expression by the `Int` on the right side. According to the Language Reference Swift never implicitly converts types (page 5):

> “Values are never implicitly converted to another type. If you need to convert a value to a different type, explicitly make an instance of the desired type.”

You can solve this problem by explicitly initializing a `Float`:
{{< highlight swift >}}
margin = CGRectGetWidth(self.view.frame) / Float(elements);
{{< /highlight >}}

Similar to Java, all basic types have heavily overloaded constructors that allow us to initialize them with other types, here are the `CGFloat` initializers:

{{< highlight swift >}}
extension Float {
	init(_ v: UInt8)
	init(_ v: Int8)
	init(_ v: UInt16)
	init(_ v: Int16)
	init(_ v: UInt32)
	init(_ v: Int32)
	init(_ v: UInt64)
	init(_ v: Int64)
	init(_ v: UInt)
	init(_ v: Int)
}
{{< /highlight >}}

Complex arithmetic expressions may get a little bit less readable in future.
