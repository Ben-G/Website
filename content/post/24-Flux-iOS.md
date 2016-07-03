+++
date = "2016-06-14T10:24:54-08:00"
draft = false
title = "Real World Flux Architecture on iOS"
slug = "real-world-flux-ios"
disqus_url = "http://blog.benjamin-encz.de/post/real-world-flux-ios/"
+++

About half a year ago we started adopting the Flux architecture in the PlanGrid iOS app. This post will discuss our motivation for transitioning from traditional MVC to Flux and will share the experience we have gathered so far.

<!--more-->

## Why We Transitioned Away from MVC

To put our decision into context I want to spend a few paragraphs describing some of the challenges the PlanGrid app faces. Some of them are somewhat unique to enterprise software, others might apply to most iOS apps. 

### We Have All the State

PlanGrid is a fairly complex iOS app. It allows users to view blueprints and to collaborate on them using different types of annotations, issues and attachments.

An important aspect of the app is that it is offline first. Users can interact with all features in the app, whether they have an internet connection or not. This means that we need to store a lot of data & state on the client. We also need to enforce a subset of the business rules locally (e.g. which annotation can a user delete?).

Lastly, while the PlanGrid app runs on both iPad and iPhone, its UI is optmized to make use of the larger available space on tablets. This means that unlike many iPhone apps we often present multiple view controllers at a time. These view controllers tend to share a decent amount of state.

### The State of State Management

All of this means that our app puts a lot of effort into managing state. Any mutation within the app results in more or less the following steps:

1. Update local data
2. Update UI
3. Update database
4. Enqueue change that will be sent to server upon available network connection
5. **Notify other controllers about state change**

Though I plan on covering other aspects of our new architecture in future blog posts, I want to focus on the 5. step today. *How should we populate state updates in our app?* 

This is the billion dollar question of mobile app development. 

Most iOS engineers, including early developers of the PlanGrid app, come up with the following answers:

- Delegation
- KVO
- NSNotificationCenter
- Callback Blocks
- Using the DB as source of truth

All of these approaches can be valid in different scenarios. However, this menu of different options is a big source of inconsistencies in large codebases that have grown over multiple years.

### Freedom is Dangerous

Classic MVC only advocates the separation of data and its representation. With the lack of other architectural guidance, everything else is left up to individual developers.

For the longest time the PlanGrid app (like most iOS apps) didn't have a defined pattern for state management. 

Many of the existing state management tools such as delegation and blocks tend to create dependencies between components that might not be desirable - two view controllers quickly can become tightly couple in an attempt to share state updates with each other. 

Other tools, such as KVO and Notifications, create invisible dependencies. Using them in a large codebase can quickly lead to code changes that cause unexpected side effects. It is far to easy for a controller to observe details of the model layer which it shouldn't be interested in.

Thorough code reviews & style guides can only do so much, many of these architectural issues start with small inconsistencies and take a long time to evolve into serious problems. With well defined patterns in place it is a lot easier to detect deviations early.

### An Architectural Pattern for State Management

One of our most important goals during refactoring the PlanGrid app was putting clear patterns & best practices in place. This would allow future features to be written in a more consistent way and make onboarding of new engineers a lot more efficient.

State management was one of the largest sources of complexity in our app, so we decided to define a pattern that all new features could use going forward.


## A Brief Intro to Flux

## Addressing Concerns

### What About UIKit?

### What About Onboarding New Developers?

### Integrating with Existing Code

## 6 Months In

## Conclusion

