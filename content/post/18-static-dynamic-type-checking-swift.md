+++
date = "2016-04-08T22:24:54-08:00"
draft = true
title = "Compile time vs. Run-time Type Checking in Swift"
slug = "compile-time-vs-runtime-type-checking-swift"
disqus_url = "http://blog.benjamin-encz.de/post/static-dynamic-type-checking-swift/"
+++

At some point, when learning how to use Swift's type system, it is important to understand that Swift (like many other languages) has two different forms of type checking: static and dynamic. Today I want to briefly discuss the difference between them and why headaches might arise when we try to combine them.

Static type checking occurs at compile time and dynamic type checking happens at runtime. Each of these two stages come with a different toolset.

##Compile Time Type Checking

Compile time type checking (or static type checking) operates on the Swift source code. The Swift compiler looks at explicitly stated and inferred types and ensures correctness of our type constraints.

A trivial example of static type checking is this:
```swift
let text: String = ""
let number: Int = text
```

Based on the source code the static type checker can decide that `text` is not of type `Int` - therefore it will raise a compile error.

Swift's type checker can do a lot more powerful things, e.g. veryfiying generic constraints:

```swift
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
// Compile Error: "cannot invoke 'printHumanName' with an argument list of type '(Car)'"
printHumanName(Car())
```

In this case, as in the above, all type verification happens solely based on the source code. The swift compiler can verify which types match the generic constraints of the `printHumanName` function; and for ones that don't it can emit a compiler error.

Since Swift's static type system offers these powerful tools we try to verify as much as possible at compile time. However, in same cases, runtime type verification is necessary.

##Runtime Type Checking

In some unfortunate cases, relying on static type checking is not possible. The most frequent case in which this occurs is when reading data from an outside resource (network, db, etc.) - in that case we often don't have the ability to store Swift type information along with the data itself. This issue can also arise in places where we need to use type erasure (e.g. when using collections with heterogeneous types).

This means instead of being able to *define* a type statically, we need to *verify* a type dynamically, at run-time. This is what all popular JSON parsing libraries do. 

Here we rely on the run time type information that Swift provides (which is an instances metatype and its protocol conformances). The only tools we have available for runtime type checking is casting via `is` and `as`. As we will see shortly, this type of casting is a lot less powerful than static type checking.

In many basic scenarios however, dynamic type checking allows to integrate types that are unknown at compile time with our statically checked Swift code:

```swift
func takesHuman(human: HumanType) {

}

var unknownData: Any = User()

if let unknownData = unknownData as? HumanType {
    takesHuman(unknownData)
}
```

If we are simply casting to a single protocol, or a concrete type, we are fine. If we try to fullfull complex, compile time type constraints at runtime, we run into some issues...

##Combining the Two

Continuing the `HasName`, `HumanType` example from above, let's assume we have received data from a network request, and we need to call the `printHumanName` method - if the dynamically detected type allows us to do that.

We know that our type needs to conform to two different protocols in order to be eligible as argument for the `printHumanName` function, so let's check for that dynamically:

```swift
var unknownData: Any = User()

if let unknownData = unknownData as? protocol<HumanType, HasName> {
    // Compile Error: "cannot invoke 'printHumanName' with an argument list of type '(protocol<HasName, HumanType>)'"
    printHumanName(unknownData)
}
```
The type check in the above example actually works correctly. The body of the `if let` block is only called for types that conform to our two expected protocols. However, we cannot convey this to the compiler. The compiler expects a *concrete* type (one that exists at compile time) that conforms to `HumanType` and `HasName`. All we can offer is a dynamically verified type.

At this point we have two different workarounds: 

- Cast to a concrete type
- Provide a second implementation of `printHumanName` without generic constraints

The concrete type solution would look something like this:

```swift
if let user = unknownData as? User {
    printHumanName(user)
} else if let visitor = unknownData as? Visitor {
    printHumanName(visitor)
}
```

Not beatiful; but it might the best possible solution in some cases.

A solution that involves rewriting `printHumanName` might look like this (though there are many other possible solutions):

```swift
func _printHumanName(thing: Any) {
    if let hasName = thing as? HasName where thing is HumanType {
        print(hasName)
    } else {
        fatalError("Provided Incorrect Type")
    }
}

_printHumanName(unknownData)
```

In this second solution we have substituted the compile time constraints for a runtime check. We cast the `Any` type to the protocol that allows us to access the relevant information (`HasName`) and we include an `is` check to verify that the type is one that conforms to `HumanType`.

This way we have offered a second implementation that will run code dynamically, if an arbitrary type matches our protocol requirements.

##Conclusion

The examples above are extremely simplified, but I hope they demonstrate the issues that can arise from differences in compile-time and run-time type checking. The key takeaway is that **we cannot cast a an argument dynamically, in order call a function that has generic constraints**.

To improve this situation in future, Swift would need to introduce a way to cast to dynamically created type constraints in a way that is compatible with statically checked constraints. One could imagine a syntax similar to this one:

```swift
if let <T: HumanType, HasName> value = unknownData as? T {
	printHumanName(value)
}
```

I know too little about compilers to know if this is feasible at all and I don't know of any languages that provide such type of bridges between static and dynamic type checking. I would assume that the cost of implementing this is huge, compared to the benefits it would provide to a very small part of a codebase.

For now it is helpful to understand this limitation and thus to perform as much type checking as possible during compile time.

I want to finish this post with a fabolous quote from @AirspeedVelocitySwift:

> Runtime type checking and compile-time generics are like steak and ice-cream – both are nice but mixing them is a bit weird. - @AirspeedVelocitySwift [Source: StackOverflow](http://stackoverflow.com/questions/28124684/swift-check-if-generic-type-conforms-to-protocol)
