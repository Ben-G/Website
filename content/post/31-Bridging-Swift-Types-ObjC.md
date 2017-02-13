+++
date = "2017-02-12T22:24:54-08:00"
draft = false
title = "Bridging Swift Types to Objective-C"
slug = "bridging-swift-types-to-objective-c"
disqus_url = "http://blog.benjamin-encz.de/post/bridging-swift-types-to-objective-c/"
+++

At PlanGrid we started adopting Swift prior to the 1.0 release. Despite the tooling problems you're probably familiar with, we're still excited Swift users and have written almost all new code in since the summer of 2014 in Swift. We are doing that within a large legacy codebase so more than 50% of our application code is still in Objective-C.

<!--more-->

Throwing an `@objc` onto our new Swift types would have been the easiest way to interop with Objective-C. However, many Swift features aren't bridgable and we quickly noticed that this approach would water down our Swift code to Objective-C with a different syntax (no structs, enums with associated values, default arguments, etc.).

## A Recipe for Bridging Swift Types

We decided to create separate types that would be responsible for bridging our Swift types to Objective-C. These types wrap around the Swift types and take care of translating language concepts where necessary.

We came up with a simple recipe for creating these bridged types:

1. Create a new type called `_ObjC{type_name}` and rename that type for Obj-C using the `@objc` annotation.
2. Create an initializer that takes the Swift type.
3. Create a public read, private write property to store the underlying Swift type.
4. Expose getters, setters and methods that reflect the members of the underlying Swift type and implement them by calling to the underlying Swift type.
5. If the type needs to have an initializer thats visible in Objective-C implement that initializer by constructing the underlying Swift type.

## Bridging Example

Let's take a look at an example of bridging Swift types to Objective-C with the method described above. Below we have a shopping cart type and a checkout options type.

In this example we wouldn't be able to expose the type to Objective-C, because enums with associated types can't be bridged. 

{{< highlight swift >}}

enum CheckoutOption {

    case creditCard(Int)
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

Since we're anticipating our entire codebase to move to Swift over time, we shouldn't compromise our new types for bridgability. Instead, let's create a wrapper type:

{{< highlight swift >}}

@objc(ShoppingCart)

final class _ObjCShoppingCart: NSObject {

    private (set) var shoppingCart: ShoppingCart

    init(items: [String]) {

        self.shoppingCart = ShoppingCart(items: items)

    }

    var items: [String] {

        get {

            return shoppingCart.items

        }

        set {

            self.shoppingCart.items = newValue

        }

    }

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