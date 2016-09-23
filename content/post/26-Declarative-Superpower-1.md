+++
date = "2016-08-10T10:24:54-08:00"
draft = false
title = "The Power of Declarative Programming - Part 1: Separating Intent From Implementation"
slug = "power-of-declarative-programming-part-1"
disqus_url = "http://blog.benjamin-encz.de/post/power-of-declarative-programming/"
+++

In the last two years I've made extensive use of declarative programming in Swift. The term is a little overloaded and generally not well defined. Throughout a small series of blog posts I'll try to express what *declarative programming* means to me and why I think it's an extremely powerful tool.

These blog posts won't focus on the use of our beloved `map` & `filter` functions, but will instead discuss the idea of applying declarative programming to an entire software system.

<!--more-->

## Why Declarative Programming?

Let's get started with why I believe you should care about (my definition of) declarative programming. 

In my experience declarative programming, applied to an entire system, brings the following benefits:

- **Separation of concerns**
	- The parts of the code that are written in a declarative style only declare an intent, without having any understanding of the underlying implementation. Separation of concerns happens naturally.
- **Less repeated code**
	- A declarative system shares a common implementation. Most of the code is configuration. No risk of repeating implementation details.
- **Exceptional API design**
	- Declarative APIs allow consumers to configure an existing implementation instead of providing their own one. The API surface can be kept minimal.
- **Readability**
	- Signal to noise ratio of declarative code is great!

## What is Declarative Programming?

Now that we know why we should use this principle, it's time to understand what exactly I mean by declarative programming. Generally the term is ill-defined[^1]. I tend to go with the popular "definition":

> Declarative programming means separating the *what* from the *how*.

Practically most of my use of declarative programming principles falls into two categories:

- Allow code to express an intent without providing an implementation
- Allow code to extend generic behavior through configuration

We'll explore the first point in this post and leave the other for the follow up post.

## Separate Intent From Implementation

I first encountered this approach when exploring Flux/Redux. One core principal of the Flux pattern is that Actions are used to describe intents while the implementation of these intents lives in stores.

If you're building a view that provides a signout button, the only responsibility of your view will be to dispatch an action describing that a user should be logged out. A simplified version of this code might look like this:

```swift
func logoutButtonTapped() {
	dispatcher.dispatch(LogoutUserAction(currentUser))
}
```

When using Flux you are creating an application specific DSL in the form of Actions. When you're building a view you can use these actions without having any understanding of how they are implemented. This approach forces you to separate concerns.

We use the idea of separating intent from implementation extensively in the PlanGrid app. We are currently implementing a new version of our client-server sync code. As part of this we have built an API for changing client side data. 

Our view layer doesn't need to be aware of client-server sync at all. Instead the view layer is only able to express the intent to make changes to a piece of data in our app. With our new API our models provide a `mutate` method through which models can be changed. When mutated models are subsequently saved, our generic persistence layer writes them to the database and generates the necessary network requests to update the server side models with our local changes.

By moving to this design we got a couple of benefits: 

- We provide a single well defined API for modifying, persisting and syncing client side models.
- We reduced redundant calls to our API client and made the API client a hidden implementation detail for all of our view code.
- We enabled future improvements to our sync code. By separating the intent from implementation we can now perform optimizations in our generic sync code. E.g. we can batch multiple changes into a single API request. This was not possible when the view code was calling the API client directly.

In programming a lot of problems can be solved by an additional level of indirection. The indirection between intent and implementation enables a better separation of concerns and therefore makes it easier to change the implementation over time. 
By using a declarative intent, we can keep the API surface of our components at a minimum.

Here's a beautiful hand made drawing, visualizing the two approaches side-by-side:


At this point you might question my definition of declarative programming: **isn't this just a plain old method call**?

Yes, but so are `map` & `filter`. Whether or not I consider an API declarative just depends on the exact interface that is exposed. Does the interface leak implementation details? Or does it allow us to express an intent without knowing about how the implementation will fulfill it?



[^1]: I'll use this term even though its [definition is disputed](https://existentialtype.wordpress.com/2013/07/18/what-if-anything-is-a-declarative-language/).
[^2]: I know, there is ["No Silver Bullet"](https://en.wikipedia.org/wiki/No_Silver_Bullet).