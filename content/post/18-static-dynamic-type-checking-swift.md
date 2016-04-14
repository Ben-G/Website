+++
date = "2016-04-08T22:24:54-08:00"
draft = false
title = "Compile Time vs. Run Time Type Checking in Swift"
slug = "compile-time-vs-runtime-type-checking-swift"
disqus_url = "http://blog.benjamin-encz.de/post/static-dynamic-type-checking-swift/"
+++

At some point, when learning how to use Swift's type system, it is important to understand that Swift (like many other languages) has two different forms of type checking: static and dynamic. Today I want to briefly discuss the difference between them and why headaches might arise when we try to combine them.

<!--more-->

Static type checking occurs at compile time and dynamic type checking happens at run time. Each of these two stages come with a different, partially incompatible, toolset.

## Compile Time Type Checking

Compile time type checking (or static type checking) operates on the Swift source code. The Swift compiler looks at explicitly stated and inferred types and ensures correctness of our type constraints.

A trivial example of static type checking is this:
{{< highlight swift >}}
let text: String = ""
// Compile Error: Cannot convert value of 
// type 'String' to specified type 'Int'
let number: Int = text
{{< /highlight >}}

Based on the source code the static type checker can decide that `text` is not of type `Int` - therefore it will raise a compile error.

Swift's static type checker can do a lot more powerful things, e.g. verifying generic constraints:

{{< highlight swift >}}
protocol HasName {}
protocol HumanType {}

struct User: HasName, HumanType { }
struct Visitor: HasName, HumanType { }
struct Car: HasName {}

func printHumanName<T: protocol<HumanType, HasName>>(thing: T) {
    // ...
}

// Compiles fine:
printHumanName(User())
// Compiles fine:
printHumanName(Visitor())
// Compile Error: cannot invoke 'printHumanName' with an 
// argument list of type '(Car)'
printHumanName(Car())
{{< /highlight >}}

In this example, again, all of the type checking occurs ate compile time, solely based on the source code. The swift compiler can verify which types match the generic constraints of the `printHumanName` function; and for ones that don't it can emit a compile error.

Since Swift's static type system offers these powerful tools we try to verify as much as possible at compile time. However, in same cases, run time type verification is necessary.

## Run Time Type Checking

In some unfortunate cases, relying on static type checking is not possible. The most common example is reading data from an outside resource (network, db, etc.) - in that case we often don't have the ability to retrieve Swift type information along with the data itself. 

This means instead of being able to *define* a type statically, we need to *verify* a type dynamically, at run time.

When checking types at run time we rely on the type metadata stored alongside all Swift instances. The only tool we have available is casting via `is` and `as`. This is what all the different Swift JSON mapping libraries do - they provide a convenient API for dynamically casting an unknown type to one that matches a specified property.

In many scenarios dynamic type checking allows to integrate types that are unknown at compile time with our statically checked Swift code:

{{< highlight swift >}}
func takesHuman(human: HumanType) {}

var unknownData: Any = User()

if let unknownData = unknownData as? HumanType {
    takesHuman(unknownData)
}
{{< /highlight >}}

As in the example above, when we cast an unknown type to match a concrete argument type, we gain the ability to call that function with our casted type. 

However, if we try to use this approach to call a function that defines arguments as generic constraints, we run into issues...

## Combining Dynamic and Static Type Checking

Continuing the earlier `printHumanName` example, let's assume we have received data from a network request, and we need to call the `printHumanName` method - if the dynamically detected type allows us to do that.

We know that our type needs to conform to two different protocols in order to be eligible as argument for the `printHumanName` function. So let's check that requirement dynamically:

{{< highlight swift >}}
var unknownData: Any = User()

if let unknownData = unknownData as? protocol<HumanType, HasName> {
    // Compile Error: cannot invoke 'printHumanName' 
    // with an argument list of type '(protocol<HasName, HumanType>)'
    printHumanName(unknownData)
}
{{< /highlight >}}

The dynamic type check in the above example actually works correctly. The body of the `if let` block is only called for types that conform to our two expected protocols. However, we cannot convey this to the compiler. The compiler expects a *concrete* type (one that exists at compile time) that conforms to `HumanType` and `HasName`. All we can offer is a dynamically verified type.

There is no way to get this to compile (even though I will briefly touch on a possible future option in the conclusion of this post).

At this point we have two different workarounds: 

- Cast to a concrete type
- Provide a second implementation of `printHumanName` without generic constraints

The concrete type solution would look something like this:

{{< highlight swift >}}
if let user = unknownData as? User {
    printHumanName(user)
} else if let visitor = unknownData as? Visitor {
    printHumanName(visitor)
}
{{< /highlight >}}

Not beautiful; but it might the best possible solution in some cases.

A solution that involves rewriting `printHumanName` might look like this (though there are many other possible solutions):

{{< highlight swift >}}
func _printHumanName(thing: Any) {
    if let hasName = thing as? HasName where thing is HumanType {
        print(hasName)
    } else {
        fatalError("Provided Incorrect Type")
    }
}

_printHumanName(unknownData)
{{< /highlight >}}

In this second solution we have substituted the compile time constraints for a run time check. We cast the `Any` type to the protocol that allows us to access the relevant information, `HasName` and we include an `is` check to verify that the type is one that conforms to `HumanType`. We have established a dynamic type check that is equivalent to our generic constraint.

This way we have offered a second implementation that will run code dynamically, if an arbitrary type matches our protocol requirements.

This solution isn't nice either; but in practice I have used a similar approaches in cases where other code guarantees that the function will be called with the correct type, but there wasn't a way of expressing it within Swift's type system.

## Conclusion

The examples above are extremely simplified, but I hope they demonstrate the issues that can arise from differences in compile time and run time type checking. The key takeaways are: 

- Static type checking happens at compile time, dynamic type checking happens at run time
- The static type checker uses type annotations and constraints
- The dynamic type checker uses run time information and casting
- **We cannot cast a an argument dynamically, in order call a function that has generic constraints**.

Is there potential for adding support for this to Swift? I think we would need the ability to dynamically create & use a constrained metatype. One could imagine a syntax that looks somewhat like this:

{{< highlight swift >}}
if let <T: HumanType, HasName> value = unknownData as? T {
	printHumanName(value)
}
{{< /highlight >}}

I know too little about the Swift compiler to know if this is feasible at all. I would assume that the relative cost of implementing this is pretty large, compared to the benefits it would provide to a very small part of the average Swift codebase.

However, according to this [Stack Overflow answer](http://stackoverflow.com/questions/28124684/swift-check-if-generic-type-conforms-to-protocol) by [David Smith](https://twitter.com/Catfish_Man) Swift currently checks generic constraints at run time (unless the compiler generates specialized copies of a function for performance optimizations), so it seems like the idea of dynamically created constrained metatypes could, at least in theory, be possible.

For now it is helpful to understand this limitation, to perform as much type checking as possible during compile time and to be aware of the possible workarounds for the worst case.

I cannot finish this post without a fabulous quote from [@AirspeedSwift](https://twitter.com/AirspeedSwift):

> Runtime type checking and compile-time generics are like steak and ice-cream – both are nice but mixing them is a bit weird. 
- [Source: StackOverflow.com](http://stackoverflow.com/questions/28124684/swift-check-if-generic-type-conforms-to-protocol)

If you have corrections or general thoughts on this post, [I would love to hear from you](https://twitter.com/benjaminencz).