+++
date = "2016-07-20T10:24:54-08:00"
draft = false
title = "Bridging Existentials & Generics in Swift 2"
slug = "bridging-existentials-generics-swift-2"
disqus_url = "http://blog.benjamin-encz.de/post/bridging-existentials-generics-swift-2/"
+++

We are back to another episode of discussing generics, protocols with associated types and some type system limitations in Swift 2. This time we will dive into an interesting workaround that the infamous [jckarter](https://twitter.com/jckarter) has taught me. We will also discuss how this workaround might become unnecessary through enhanced existential support in future Swift versions. But what are existentials anyway?

<!--more-->

## Existentials in Swift

Generally speaking existentials allow us to define type variables using type requirements. We can use these type variables throughout our program without knowing which concrete underlying type implements the requirements.

In Swift 2 the only way to define an existential type is using the `protocol<>` syntax ([which will be replaced with the `&` syntax in Swift 3](https://github.com/apple/swift-evolution/blob/master/proposals/0095-any-as-existential.md)).

By defining e.g. a function that takes an existential argument, we are able to use any members of the existential type without knowing which concrete type was passed to the function:

{{< highlight swift >}}
protocol Saveable {
    func save()
}

protocol Loadable {
    func load()
}

func doThing(thing: protocol<Saveable, Loadable>) {
    thing.save()
    thing.load()
}
{{< /highlight >}}

In many ways existentials are very similar to generics. Why would we choose one over the other? One of the advantages of existentials is that they allow for covariance, whereas generics in Swift are invariant. Here's how we can extend the existential example above to leverage the covariance support:

{{< highlight swift >}}
protocol Saveable {
    func save()
}

protocol Loadable {
    func load()
}

func doThing(thing: protocol<Saveable, Loadable>) {
    thing.save()
    thing.load()
}

class A: Saveable, Loadable {
    func save() {}
    func load() {}
}

class B: Saveable, Loadable {
    func save() {}
    func load() {}
}

// we can have a heterogenous list of types conforming to the existential type
let list: [protocol<Saveable, Loadable>] = [A(), B()]

for element in list {
    doThing(element)
}
{{< /highlight >}}



## Bridging Between Existentials and Generics

## Opening Existentials

## The Future is Bright

---

Interested in pushing the limits of Swift full-time? **[we're hiring](http://grnh.se/8fcutd)**.

---

Thanks a lot to [@zats](https://twitter.com/zats), [@kubanekl](https://twitter.com/kubanekl) and [@pixelpartner](https://twitter.com/pixelpartner) for reading drafts of this post!

**References**:

- [Flux](https://facebook.github.io/flux/) - Facebook's official Flux website including the original talk introducing it
- [Unidirectional Data Flow in Swift](https://realm.io/news/benji-encz-unidirectional-data-flow-swift/) - a talk I gave at Swift about Redux concepts and the original ReSwift implementation
- [ReSwift](https://github.com/reswift/reswift) - an implementation of Redux in Swift
- [ReSwift Router](https://github.com/ReSwift/ReSwift-Router) - a declarative router for ReSwift apps