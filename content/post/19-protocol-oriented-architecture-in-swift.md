+++
date = "2016-04-08T22:24:54-08:00"
draft = true
title = "Protocol Oriented Architecture in Swift"
slug = "protocol-oriented-architecture-in-swift"
disqus_url = "http://blog.benjamin-encz.de/post/protocol-oriented-architecture-in-swift/"
+++

The term *Protocol Oriented Programming* was introduced by Apple during WWDC, alongside with enhancements to Swift protocols. Most importantly Swift 2 introduced protocol extensions that can provide method implementations. Now protocols are no longer only used to define contracts & interfaces but are instead a valuable tool for code sharing. Many blog posts and talks have covered the idea of protocol oriented programming in detail - mostly using small and isolated examples. Today I want to discuss how protocol oriented programming can be used as an architectural tool for building a business layer in an app.

<!--more-->

##What is a Protocol Oriented Architecture?

The main idea of a protocol oriented architecture is to use generics, protocols and extensions to build out shared infrastructure within an app. This infrastructure consists of a common core of shared code & strict interfaces for parameterizing the infrastructure's behavior.

Luckily my drawing is a lot better than my writing; so I'll try to explain this with a little diagram:

![](https://dl.dropboxusercontent.com/u/13528538/Blog/ProtocolOrientedArchitecture/sketch.png)

Nevermind if you can't read any of the text - it's enough to understand the arrangement of these colored circles within the three different rings.

At the very center of this architecture we have what I call *Infrastructure* (yellow circles). These components provide most of the code in this architecture. They implement common tasks such as dealing with network requests or working with a local database.

The second ring (blue circles) consists of protocols. These protocols describe *capabilities*. These capabilities are linked to one or multiple pieces of infrastructure. The infrastructure layer looks through these protocols to get required information from concrete types. E.g. the persistence layer might need to know into which table of the database an object needs to be written. Each of the protocols in this second layer describe a well isolated capability; the finer the granularity the better.

The outer layer finally provides concrete types (green circles). These are the types that we use throughout the rest of the app (e.g. user objects, settings, cat images, you name it). These concrete types now adopt protocols from the second layer in order to take on *capabilities*. Can a `User` be synched with a web service? Then it should implement the `Syncable` protocol. Does a `Photo` require some image to be downloaded alongside its metadata? Then it should adopt the `HasBinaryAssets` protocol.

Because we have defined all of these capabilites as well isolated protocols our types can adopt many different capabilites at once.

Now you might wonder what makes this an architecture? After all it looks very similar to plain old protocol oriented programming.

One of the main differentiatiors is that our shared code does not live in protocol extensions, but instead it is in separate *infrastructure* types.

This approach makes it easier to compose capabilites & often makes it possible to share more code.

If we, for example define two different protocols `Persitable` and `Cachable` we might want to run specific code if one of our types adopts both protocols.

This approach brings a bunch of advantages:

- We strictly separate behavior from data, reducing redudant code
- We allow data to declaratively *configure* shared behaviour; this way we provide a way to configure shared behavior instead of re-implementing it

At [PlanGrid](http://www.plangrid.com/) we have used this approach to implement the entire business layer of our app. 

In this post I want to use a practical example to explain benefits and implementation details of a protocol oriented architecture.


##Notes:

- This is different than sharing behavior through protocol extension
- Instead of making heavy use of subclassing, Swift enables us to share code through generic types, protocols and extensions.

The idea of *Infrastructure Driven Development* is to use these capabilities to implement core functionality that can be shared between various types within a codebase (or even across projects). The core guidelines for the approach are the following:



To demonstrate the idea I want to dive into a practical example: implementing file downloads for a list of documents. The first piece of common infrastructure would be a `FileDownloader` type, that might look somewhat like this:

```swift
final class FileDownloader {
    func downloadFile(fromURL: NSURL, toFilesystemURL: NSURL, completion: (Bool) -> Void) {
        // TODO:
    }
}
```
