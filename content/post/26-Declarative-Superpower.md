+++
date = "2016-08-10T10:24:54-08:00"
draft = false
title = "The Power of Declarative Programming"
slug = "power-of-declarative-programming"
disqus_url = "http://blog.benjamin-encz.de/post/power-of-declarative-programming/"
+++

Separating the *what* from the *how* is one of the main principles I've applied when writing (Swift) code in the last two years. This idea of is often referred to as *declarative programming*[^1].

Higher order functions, such as `map` and `filter` are often used to demonstrate the better signal-to-noise ratio, however I think they fail to demonstrate the power & scope of declarative programming. How we iterate over or manipulate lists doesn't have a large impact on our overall code design.

**To me the idea of declarative programming is extremely powerful - in my (limited) experience as a developer no design principal has gotten closer to a silver bullet.**[^2]

I've mostly used declarative programming in two different ways:

- Allow code to express an intent without providing an implementation
- Allow code to extend generic behavior through configuration

## Allow Code to Express an Intent Without Providing an Implementation

I first encountered this approach when exploring Flux/Redux. One core principal of the Flux pattern is that Actions are used to describe intents while the implementation of these intents lives in Stores.

If you're building a view that provides a signout button, the only responsibility of your view will be to dispatch an action describing that a user should be logged out. A simplified version of this code might look like this:

```swift
func logoutButtonTapped() {
	dispatcher.dispatch(LogoutUserAction(currentUser))
}
```

When using Flux you are creating an application specific DSL in the form of Actions. When you're building a view you can use these actions without having any understanding of how they are implemented. This approach forces you to separate concerns.

We use the idea of separating intent from implementation extensively in the PlanGrid app. We are currently implementing a new version of our client-server sync code. As part of this we have built an API for changing client side data. Our view layer doesn't need to be aware of client-server sync at all. Instead the view layer should only be able to express the intent to make changes to a piece of data in our app. With our new API our models provide a `mutate` method through which models can be changed. When mutated models are subsequently saved, our generic persistence layer writes them to the database and generates the necessary network requests to update the server side models with our local changes.

By moving to this design we got a couple of benefits: 

- We provide a single well defined API for modifying, persisting and syncing client side models.
- We reduced redundant calls to our API client and made the API client a hidden implementation detail for all of our view code
- We enabled future improvements to our sync code. By separating the intent from implementation we can now perform optimizations in our generic sync code. E.g. we can batch multiple changes into a single API request. This was not possible when the view code was calling the API client directly

## Allow Code to Extend Generic Behavior Through Configuration



---

In my experience declarative programming (applied to an entire application) brings the following benefits:

- **Separation of concerns**
	- The parts of the code that are written in a declarative style only declare an intent, without having any understanding of the underlying implementation. Separation of concerns happens naturally.
- **Less repeated code**
	- A declarative system shares a common implementation. Most of the code is configuration. No risk of repeating implementation details. Goes hand in hand with separation of concerns.
- **Exceptional API design**
	- Declarative APIs allow consumers to configure an existing implementation instead of providing their own one.  	
- **Readability**
	- Signal to noise ratio of declarative code is great!	 	

In this post I want to show that the idea of declarative programming applies to a much larger scope of problems and can have a huge, positive impact on an entire codebase.

## Why Declarative Programming?

The idea is fundamental to programming itself. High level languages enable us to use declarative descriptions, e.g. assigning a value to a variable, without caring about implementation details such as memory allocation and copy instructions.

Less frequently we use declarative programming to build abstractions that are specific to our applications. When used, the goal of these abstractions is to strictly constrain the set of valid operations a developer can define. This results in an API that is easier to understand while also reducing the potential for introducing bugs.

In many ways abstractions that rely on declarative programming are similar to [DSLs](https://en.wikipedia.org/wiki/Domain-specific_language).

A lot of my work at PlanGrid involves refactoring code to make it easier to scale up to a larger team of developers. Onboarding new developers is easiest when common patterns and architectural decisions are well defined. At the very least they should be documented and supported by example implementations. **Ideally they should be baked into the codebase**. By applying the idea of declarative APIs we try to create **templates that can only be implented in one way.** As a positive side effect our codebase is become more homogeneous as larger portions are implemented using these templates.

<!--more-->

## Declarative APIs in Swift

In programming, being a fairly informal field in practice, most ideas can be expressed best using examples. Let's take a look at how we refactored syncing data from a server within the PlanGrid app. 

- Also mention signal to noise ratio (better than in imperative code)

# Ideas

- Capturing info in leafs of application
- Provide implementation at heart of app
- heart can "see" all information from leafs and make smart decisions based on them
- leafs get separation of concerns - they declare an intent without understanding/duplicating implementation code
- Code reads like XML?
- Think closest I've got to a silver bullet


[^1]: I'll use this term even though its [definition is disputed](https://existentialtype.wordpress.com/2013/07/18/what-if-anything-is-a-declarative-language/).
[^2]: I know, there is ["No Silver Bullet"](https://en.wikipedia.org/wiki/No_Silver_Bullet).