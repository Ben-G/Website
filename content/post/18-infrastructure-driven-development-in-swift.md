+++
date = "2016-04-08T22:24:54-08:00"
draft = true
title = "Infrastructure Driven Development in Swift"
slug = "infrastructure-drive-development-in-swift"
disqus_url = "http://blog.benjamin-encz.de/post/infrastructure-drive-development-in-swift/"
+++

Most blog posts about Swift (including my own) discuss language features on a micro level, they demonstrate syntax and provide isolated examples. Today I want to provide some insight into how Swift has changed the architecture of my overall code, in particular I want to discuss the idea of what I'm going to call *Infrastructure Driven Development*.

<!--more-->

##What is Infrastructure Driven Development?

Swift has provided us with a powerful type system. That type system allows us to express constraints in code. Type information & constraints combined enable powerful new ways of code sharing.

Instead of making heavy use of subclassing, Swift enables us to share code through generic types, protocols and extensions.

The idea of *Infrastructure Driven Development* is to use these capabilities to implement core functionality that can be shared between various types within a codebase (or even across projects). The core guidelines for the approach are the following:

- Strictly separate behavior from data
- Allow data to declaratively *configure* shared behaviour

To demonstrate the idea I want to dive into a practical example: implementing file downloads for a list of documents. The first piece of common infrastructure would be a `FileDownloader` type, that might look somewhat like this:

```swift
final class FileDownloader {
    func downloadFile(fromURL: NSURL, toFilesystemURL: NSURL, completion: (Bool) -> Void) {
        // TODO:
    }
}
```



##Notes:

- This is different than sharing behavior through protocol extension