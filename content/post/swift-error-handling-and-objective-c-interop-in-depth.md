+++
date = "2015-07-23T22:24:54-08:00"
draft = false
title = "Swift Error Handling and Objective-C Interop in Depth"
+++

For the impatient reader:

#TL;DR

- The `ErrorType` protocol has hidden requirements that are automatically fullfilled if you use an `enum` to implement the protocol
- Objective-C methods can only be translated to Swift's error handling mechanism if they return Objective-C objects or boolean values
- Swift will invoke the `catch` block if the Objective-C method returns `nil`/`false`, independent of whether an `NSError` was produced or not
- If an Objective-C method produces an `NSError` *and* returns a value the `catch` blocks is not invoked and the error cannot be retrieved
- [GitHub project with examples](https://github.com/Ben-G/FunWithErrors)

#Fun With Errors

Recently I've spent some time looking into the new error handling mechanism in Swift in depth. I've especially focused on its interoperability with Objective-C which is documented fairly lightly as of now (Xcode 7 Beta 4). 

It started with the following lines of code, in which I tried to experiment with creating a custom error type using a `struct` (instead of the canonical example in which we use an `enum`):

    struct MyErrorType: ErrorType {
      var errorDetails: String
    }

This results in the following compiler error:

`Type 'MyErrorType' does not conform to protocol 'ErrorType'`.

That was pretty surprising, given that the protocol definition for `ErrorType` in Xcode looks like this:

	protocol ErrorType {
	}
	
##Hidden Protocol Requirements

The error message revealed two hidden protocol requirements:

![image](https://www.dropbox.com/s/rlx8vruu9ecdqko/error.png?dl=1)

This means the actual protocol definition for `ErrorType` looks like this:

	protocol ErrorType {
		var _domain: String
		var _code: Int
	}
	
When using an `enum` to define a custom `ErrorType` these fields are automatically generated and populated (this is discussed in WWDC 2015 Session 402, 08:20 min).

These two fields, `domain` and `code`, are also provided by `NSError`, so I assume these fields are primarily used for compatibility with Objective-C.

You might wonder how these fields are populated when using a custom `ErrorType`?

Me too! So let's create this simple error type:

	enum MyError: ErrorType {
	  case BasicError, FatalError
	}
	
And write a throwing function:

	func badFunction() throws {
	  throw B.FatalError
	} 

Along with a catch block to print the `_code` and `_domain` members of the error:

    do {
      try badFunction()
    } catch let error as MyError {
      print("domain: \(error._domain) code:\(error._code)")
    } catch {
      
    }
    
This is the result that you will see in the console:

	domain: FunWithErrors.MyError code: 1
	
The `_domain` member matches the module name in which the custom `ErrorType` was defined and the `_code` matches the raw enum value (`BasicError` = 0, `FatalError` = 1).

Nothing too exciting here, but an interesting look under the covers. Next, let's see how Objective-C's `NSError` works with Swift's error handling.

##Throwing From Objective-C

Let's build the simplest throwing Objective-C method following this rule in the documentation:

> If the last non-block parameter of an Objective-C method is of type `NSError **`, Swift replaces it with the throws keyword, to indicate that the method can throw an error.

###Methods That Return `void`

This is a simple Objective-C class that has a method that should throw:

	@interface ErrorProducer : NSObject
	
	+ (void)doWithError:(NSError**)error;
	
	@end
	
However, when calling this method from Swift we need to provide an `NSErrorPointer` and the method does not throw:

![image](https://www.dropbox.com/s/zz8ev7j00vxz21k/doesntThrow.png?dl=1)

For some reason the automatic translation promised by Swift is not working in this case.

After mutating the method signature multiple times, I found out that the method is **only translated to Swift's error handling mechanism if it returns an Objective-C object or a boolean value**. 

###Methods That Return Objective-C Objects or Boolean Values

This method for example:

	+ (NSString *)provideStringWithError:(NSError**)error;
	
Can be used from Swift as expected:

![image](https://www.dropbox.com/s/dqoauugwun16t4k/doesThrow.png?dl=1)

So let's provide a simple implementation for this method to see how we can catch the thrown `NSError` in Swift:

	+ (NSString *)provideStringWithError:(NSError**)error {
	  if (error) {
	    *error = [NSError errorWithDomain:@"FunWithErrors" code:0 userInfo:nil];
	  }
	  
	  return @"";
	}

And on the call side we provide a `do/catch` block:

	do {
	  try ErrorProducer.provideString()
	} catch let error as NSError {
	  print("domain: \(error.domain) code: \(error.code)")
	}
	
If you run this code Swift code... **nothing will be printed to the console!** The catch block will never be reached.

It seems that the return value of an empty string (`@""`) is indicating that the method returned successfully, even though an error was assigned to the error pointer.

If we change the implementation of the Objective-C method to return `nil`, the `catch` block is invoked correctly:

	+ (NSString *)provideStringWithError:(NSError**)error {
	  if (error) {
	    *error = [NSError errorWithDomain:@"FunWithErrors" code:0 userInfo:nil];
	  }
	  
	  return nil;
	}

From Swift's perspective this makes sense. Every Swift function that `throws` will return to the caller without providing the expected return value. In Objective-C however, `NSError` is sometimes used as an *additional* return value indicating that some minor issue occurred, while the main return value could still be created as expected. **In my understanding these `NSError` instances cannot be retrieved from Swift.** It will be interesting to see if and how existing Objective-C frameworks will be modernized to accomodate for this.

There's one more interesting case I want to look at: It almost seems like the return value is the most important factor for determining whether an Objective-C method throws or not. What happens if we return `nil` without assigning an `NSError` to the error pointer?

	+ (NSString *)provideNilStringNoErrorWithError:(NSError**)error {
	  return nil;
	}
	
This indeed throws as well! Swift provides us with an instance of `_SwiftNativeNSError`, the `domain` of the produced error is `Foundation._GenericObjCError` and the `code` is 0.

As was pointed out to me, the Cocoa documentation on error handling in Objective-C discusses this emphasis on the return value of a method that can error out:

> When dealing with errors passed by reference, it’s important to test the return value of the method to see whether an error occurred, as shown above. Don’t just test to see whether the error pointer was set to point to an error.

Source: [Programming with Objective-C | Dealing with Errors](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/ErrorHandling/ErrorHandling.html)

##Summary

As of today (Xcode 7 Beta 4) the interopability between Swift's error handling and Objective-C is lacking some documentation. Here are some interesting findings discussed throughout the blog post:

- Objective-C methods can only be translated to Swift's error handling mechanism if they return Objective-C objects or boolean values
- Swift will invoke the `catch` block if the Objective-C method returns `nil`/`false`, independent of whether an `NSError` was produced or not
- If an Objective-C method produces an `NSError` *and* returns a value, the `catch` blocks is not invoked and the error cannot be retrieved

You can find a small project that contains all of the examples used in this blog post [on GitHub](https://github.com/Ben-G/FunWithErrors).

*Thanks [@warrenm](https://twitter.com/warrenm) for providing feedback and improving this post!*

You can [find me on twitter](https://twitter.com/benjaminencz), too.