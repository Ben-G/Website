+++
date = "2016-02-25T22:24:54-08:00"
draft = false
title = "Validated: A Swift μ-Library for Somewhat Dependent Types"
disqus_url = "http://blog.benjamin-encz.de/validated-a-swift-m-library-for-somewhat-dependent-types/"
slug = "validated-a-swift-m-library-for-somewhat-dependent-types"
+++

Today I built & published a μ-library that makes it easier to leverage Swift's type checking system for program verification: [Validated](https://github.com/Ben-G/Validated).

<!--more-->

**Why?**

All Swift developers already use the type system to avoid basic type mismatches (e.g. passing an `Int` where a `String` is expected), this capability is built into the languge itself.

A type system can however help verifying more than just the abscence of these simple errors. This requires that developers express constraints and semantics of their programs in types. **`Validated` provides a simple way to lift requirements about values into the type system.**

Here's an example from the GitHub Readme:

You might have a function in your code that only knows how to work with a `User` value when the user is logged in. Usually you will implement this requirement in code & add documentation, but you don't have an easy way of expressing this invariant in the type signature:

```swift
/// Please ever only call with a logged-in user!
func performTaskWithUser(user: User) {
    precondition(
    	user.loggedIn,
    	"It is illegal to call this method with a logged out user!"
    )

	// ...
}
```

Using Validated you can quickly create a new type that describes this requirement in the type system. That makes it impossible to call the function with a logged-out user and it makes the method signature express your invariant (instead of relying on documentation):

```swift
func performTaskWithUser(user: LoggedInUser) {
	// ...
}
```

In short: `Validated` allows you to create new types, by taking existing types and adding validations to them. These new types can be used throughout your APIs to express expectations not only about types, but also about values.

I'm very interested in hearing whether this is useful to you & how it could be improved!

[To learn how to use this you should head to GitHub](https://github.com/Ben-G/Validated)!
