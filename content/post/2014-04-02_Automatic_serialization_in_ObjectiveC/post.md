+++
date = "2014-04-02T22:24:54-08:00"
draft = false
title = "Automatic serialization in Objective-C"
disqus_url = "http://blog.benjamin-encz.de/seamless-serialization-objectivec/"
slug = "seamless-serialization-objectivec"
+++

Recently I worked on a tutorial that required me to serialize a large amount of objects. This is a common use case in many games - if the user quits the game and reopens it you want to restore the entire game state.

<!--more-->

![image](7U79T.png)

As you may know the `NSCoding` protocol is responsible for marking Objects to be encodable and decodable. Without using third party tools you need to implement `encodeWithCoder:` and `decodeWithCoder` manually. You need two lines of code for every property of your object, one for writing it and for reading it. It is nice that Cocoa provides the flexibility to do this manually, but honestly in most cases you just want to go with a default serialization.

In my case implementing the `NSCoding` protocol manually would have meant a boring afternoon and hundreds of lines of boilerplate code.

[Autocoding](https://github.com/nicklockwood/AutoCoding) to the rescue!

# Autocoding

[Autocoding](https://github.com/nicklockwood/AutoCoding) is a great little utility that makes serialization in Objective-C a breeze. It is a lightweight framework that adds a category to `NSObject`.

## Installation

Simply add *Autocoding.m* and *Autocoding.h* to your project.

## Example Usage

AutoCoding's category adds a very convenient `writeToFile:` method to `NSObject`. Once you added Autocoding to your project you can call it on basically any object (there are a few exceptions stated in detail on the GitHub page). Example of writing an object to disk:

	[gameModel writeToFile:persistencePath atomically:TRUE];

Reading a serialized file into an object is just as convenient:

    GameModel *gameModel = [GameModel objectWithContentsOfFile:persistencePath];

There are a lot of additional options, for example for excluding properties from being serialized, but for most applications it will stay this simple! An incredible improvement over writing hundreds of lines.

**Never write hundreds of lines of serialization code again!**
