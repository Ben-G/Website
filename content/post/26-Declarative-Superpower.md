+++
date = "2016-08-10T10:24:54-08:00"
draft = true
title = "The Power of Declarative Programming"
slug = "power-of-declarative-programming"
disqus_url = "http://blog.benjamin-encz.de/post/power-of-declarative-programming/"
+++

Separating the *what* from the *how*, often referred to as *declarative programming* is one of the few principles that I've used on a daily basis ever since switching to writing Swift full-time. 

The idea is fundamental to programming itself. High level languages enable us to use declarative descriptions, e.g. assigning a value to a variable, without caring about implementation details such as memory allocation and copy instructions.

Less frequently we use declarative programming to build abstractions that are specific to our applications. When used, the goal of these abstractions is to strictly constrain the set of valid operations a developer can define. This results in an API that is easier to understand while also reducing the potential for introducing bugs.

In many ways abstractions that rely on declarative programming are similar to [DSLs](https://en.wikipedia.org/wiki/Domain-specific_language).

A lot of my work at PlanGrid involves refactoring code to make it easier to scale up to a larger team of developers. Onboarding new developers is easiest when common patterns and architectural decisions are well defined. At the very least they should be documented and supported by example implementations. **Ideally they should be baked into the codebase**. By applying the idea of declarative APIs we try to create **templates that can only be implented in one way.** As a positive side effect our codebase is become more homogeneous as larger portions are implemented using these templates.

<!--more-->

## Declarative APIs in Swift

In programming, being a fairly informal field in practice, most ideas can be expressed best using examples. Let's take a look at how we refactored syncing data from a server within the PlanGrid app. 

- Also mention signal to noise ratio (better than in imperative code)
