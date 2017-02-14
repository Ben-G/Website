+++
date = "2017-02-14T22:24:54-08:00"
draft = false
title = "Bridging Swift Types to Objective-C"
slug = "bridging-swift-types-to-objective-c"
disqus_url = "http://blog.benjamin-encz.de/post/bridging-swift-types-to-objective-c/"
+++

At PlanGrid we started adopting Swift prior to the 1.0 release. Despite the tooling problems you're probably familiar with, we're still excited Swift users and have written almost all new code since the summer of 2014 in Swift. We are doing that within a large legacy codebase so more than 50% of our application code is still in Objective-C. As in many projects Swift and Objective-C need to co-exist.

<!--more-->

Throwing an `@objc` onto our new Swift types would have been the easiest way to interop with Objective-C. However, many Swift features aren't bridgable and we quickly noticed that this approach would water down our Swift code to Objective-C code with a different syntax (no structs, enums with associated values, default arguments, etc.).

## A Recipe for Bridging Swift Types

We decided to create separate types that would be responsible for bridging our Swift types to Objective-C (and vice versa). These types wrap around the Swift types and take care of translating language concepts where necessary.

We came up with a simple recipe for creating these bridged types:

1. Create a new type called `_ObjC{type_name}` and rename that type for Objective-C using the `@objc` annotation.
2. Create an initializer that takes the Swift type.
3. Create a public read, private write property to store the underlying Swift type.
4. Expose getters, setters and methods that reflect the members of the underlying Swift type and implement them by calling to the underlying Swift type.
5. If the type needs to have an initializer thats visible in Objective-C implement that initializer by constructing the underlying Swift type.

## Bridging Example

Let's take a look at an example of bridging Swift types to Objective-C with the method described above. Below we have a shopping cart type and a checkout options type.

In this example we wouldn't be able to expose the type to Objective-C, because enums with associated types can't be bridged.

{{< highlight swift >}}
enum CheckoutOption {
  case creditCard(Int
  case paypal(String)
}

struct ShoppingCart {
  var checkoutOption: CheckoutOption?
  var items: [String]

  init(items: [String], checkoutOption: CheckoutOption? = nil) {
      self.items = items
      self.checkoutOption = checkoutOption
  }
}
{{< /highlight >}}

Since we're anticipating our entire codebase to move to Swift over time, we shouldn't compromise our new types for bridgeability. Instead, let's create a wrapper type:

{{< highlight swift >}}
@objc(ShoppingCart)
final class _ObjCShoppingCart: NSObject {
    // The underlying Swift type is stored in the bridged type. This way
    // Swift code that consumes the bridged Objective-C type can pull out and
    // use the underlying Swift type.  
    private (set) var shoppingCart: ShoppingCart

    init(items: [String]) {
        // All initializers construct the underlying Swift type
        self.shoppingCart = ShoppingCart(items: items)
    }

    // This initializer allows Swift code to create a bridged value and pass
    // it to Objective-C code.
    init(shoppingCart: ShoppingCart) {
        self.shoppingCart = shoppingCart
    }

    // Computed properties are implemented based on properties of the
    // underlying Swift type.
    var items: [String] {
        get {
            return shoppingCart.items
        }
        set {
            self.shoppingCart.items = newValue
        }
    }

    // Properties and methods can translate language features where needed.
    // E.g. turn enums with associated types into distinct Objective-C types.
    var checkoutOption: Any? {
        guard let checkoutOption = self.shoppingCart.checkoutOption else {
            return nil;
        }

        switch checkoutOption {
        case let .creditCard(ccNumber):
            return _ObjCCheckoutOptionCreditCard(ccNumber)
        case let .paypal(email):
            return _ObjCCheckoutOptionPaypal(email)
        }
    }

    // We can also provide convenience methods for Objective-C. Like the following
    // two methods that allow setting enums with associated values from Objective-C.

    func setCheckoutOptionToCreditCard(withCCNumber ccNumber: Int) {
        self.shoppingCart.checkoutOption = .creditCard(ccNumber)
    }

    func setCheckoutOptionToPayPal(withEmail email: String) {
        self.shoppingCart.checkoutOption = .paypal(email)
    }
}

@objc(CheckoutOptionCreditCard)
final class _ObjCCheckoutOptionCreditCard: NSObject {
    let creditCardNumber: Int

    init(_ ccNumber: Int) {
        self.creditCardNumber = ccNumber
    }
}

@objc(CheckoutOptionPaypal)
final class _ObjCCheckoutOptionPaypal: NSObject {
    let email: String

    init(_ email: String) {
        self.email = email
    }
}
{{< /highlight >}}

This example is pretty verbose, since we're expressing the cases of our enums
as Objective-C types. How thorough you want to map Swift types to Objective-C
will depend on your use case.

Now this type can be used from Objective-C:

{{< highlight objc >}}
ShoppingCart *cart = [[ShoppingCart alloc] initWithItems:@[@"TV", @"Book"]];
cart.items = @[@"TV"];
[cart setCheckoutOptionToPayPalWithEmail:@"test@test.com"];
{{< /highlight >}}

We could now pass this instance to Swift code and the receiver could use the
underlying Swift type, stored within the bridged type, with all of its rich language features.

The principles outlined above are also used for the Swift
Foundation overlay to create Swift wrappers around Objective-C types ([see Calendar.swift](https://github.com/apple/swift/blob/adc54c8a4d13fbebfeb68244bac401ef2528d6d0/stdlib/public/SDK/Foundation/Calendar.swift#L143-L150)).

Last September my friend Russ Bishop proposed exposing the `_ObjectiveCBridgeable` protocol as part of the standard library. That proposal has been deferred but if it's implemented it will further formalize a recipe for bridging types between Swift and Objective-C and potentially other languages?

> We agree that it would be valuable to give library authors the ability to bridge their own types from Objective-C into Swift using the same mechanisms as Foundation. However, we lack the confidence and implementation experience to commit to _ObjectiveCBridgeable in its current form as public API. In its current form, as its name suggests, the protocol was designed to accommodate the specific needs of bridging Objective-C object types to Swift value types. In the future, we may want to bridge with other platforms, including C++ value types or other object systems such as COM, GObject, JVM, or CLR. It isn't clear at this point whether these would be served by a generalization of the existing mechanism, or by bespoke bridging protocols tailored to each case. This is a valuable area to explore, but we feel that it is too early at this point to accept our current design as public API.

[Swift Evolution Proposal: Allow Swift types to provide custom Objective-C representations](https://github.com/apple/swift-evolution/blob/master/proposals/0058-objectivecbridgeable.md)
