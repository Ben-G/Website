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

### A Simple Example

Let's take a look at a simple example to explore the benefits of declarative programming. In our app we haven a `Post` type. Posts might reference images. When we download a post we also want to download the images for this post. Here's what the type looks like:

```swift
struct Post {
	let url: URL
	let photoUrls: [URL]
}
```

We now might write a function that can download posts and the photos they are referencing. Here's some pseudo-style code of a synchronous download function:

```swift 
func downloadPost(post: post) -> (Post, [UIImage]) {
	let post = downloader.get(post.url)
	var images: [UIImage] = []
	
	for photo in photos {
		images += downloader.get(photo.url)
	}
	
	return (post, images)
}
```

This code is not declarative, we need to spell out exactly how

Declarative programming allows us to build high level abstractions that are specific to our problem domain. These abstractions allow us to constrain the set of of valid operations to a minimum. This results in an easy to use API and systems 



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