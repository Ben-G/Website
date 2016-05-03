+++
date = "2016-05-03T10:24:54-08:00"
draft = false
title = "Decoding Heterogeneous Collections in Swift"
slug = "decoding-heterogeneous-collections-in-swift"
disqus_url = "http://blog.benjamin-encz.de/post/deserializing-heterogeneous-types-in-swift/"
+++

The problem of decoding Swift types from an outside data source, such as JSON, has been mostly solved. Since Swift's release we've seen more than a dozen popular JSON mapping libraries pop up.

However, most of the libraries I've seen so far deal with decoding individual types, not entire collections of heterogeneous types.

<!--more--> 

We define how a JSON object representing a user can be mapped to a `User` type, as in this example:

{{< highlight swift >}}
struct User: Deserializable {
    static let typeIdentifier = "user"

    let name: String
    let age: Int

    static func decode(json: AnyObject) throws -> User {
        return try User(
            name: json => "name",
            age: json => "age"
        )
    }
}
{{< /highlight >}}

This approach requires the developer to know that a certain piece of JSON will ever only contain user objects.

But how can we handle heterogeneous collections like the following one?

```
 [
  {
      "type" : "user",
      "name" : "test",
      "age"  : 99
  },
  {
      "type"  : "car",
      "color" : "green"
  },
  {
      "type" : "phone",
      "model" : "iPhone"
  },
  {
      "type"  : "car",
      "color" : "yellow"
  },
  {
      "type" : "phone",
      "model" : "Anroid Device"
  }
]
```

In this example we have three different types: "user", "car" and "phone", that can occur anywhere throughout the JSON array. In order to use one of the JSON mapping libraries we would need to inspect each individual element in this list, identify it's type, and then call the initializer of the respective Swift type.

## Dynamically Mapping JSON Entities and Types

In Objective-C it would be fairly easy to solve this problem automatically. We can rely on the Objective-C runtime to dynamically look up a class by its name and create the relevant instance for each entity we find in the JSON array.

In Swift we cannot rely on these run time mechanisms, but we can still create a mapping between a JSON type and a Swift type.

The first step is to introduce a protocol for all types that can be deserialized with our new mechanism. These types will need to fulfill two requirements:

1. They need to be able to be initialized with a JSON entity
2. They need to provide a `typeIdentifier` string that we can use to match the "type" identifier from our JSON example above.

Here's what the protocol looks like in my example:

{{< highlight swift >}}
protocol Deserializable: Decodable {
    static var typeIdentifier: String { get }
}
{{< /highlight >}}

Note that I'm relying on the [Decodable](https://github.com/Anviking/Decodable) JSON mapping library to require the JSON initializer for me via the `Decodable` protocol.

Each of the individual types will now implement this protocol. Here's an example for the `User` type:

{{< highlight swift >}}
struct User: Deserializable {
    static let typeIdentifier = "user"

    let name: String
    let age: Int

    static func decode(json: AnyObject) throws -> User {
        return try User(
            name: json => "name",
            age: json => "age"
        )
    }
}
{{< /highlight >}}

This is mostly the regular JSON mapping code we're familiar with. The only addition is the static `typeIdentifier` member that tells us what this type is called in the JSON array.

We also implement this protocol for the other types represented in the JSON array (`Car`and  `Phone`) but I will spare you the details of that...

**Now to the interesting part.** We need a component that can take the entire, heterogeneous,  array of JSON objects, can iterate over all of them and create the correct Swift instances based on the types it finds.

For this example I've called the type `Deserializer`. Here's what it looks like:

{{< highlight swift >}}
struct Deserializer {
    private var modelLookupTable: [String : Deserializable.Type] = [:]

    init(models: [Deserializable.Type]) {
        // Store all types in lookup table
        for model in models {
            self.modelLookupTable[model.typeIdentifier] = model
        }
    }

    func deserialize(json: [[String : AnyObject]]) -> [Deserializable] {
        var parsedModels: [Deserializable] = []

        // Iterate over each entity in the JSON array
        for jsonEntity in json {
            // Find metatype for this entity
            guard let type = jsonEntity["type"] as? String else { continue }
            guard let modelMetatype = modelLookupTable[type] else { continue }

            // Call initializer on the metatype
            if let model = try? modelMetatype.decode(jsonEntity) {
                parsedModels.append(model)
            }
        }

        return parsedModels
    }
}
{{< /highlight >}}

This type gets initialized with an array of model metatypes (`[Deserializable.Type]`). This is necessary in order for the component to know which types can appear within the JSON array it will deserialize. Since we cannot dynamically look up types at runtime, we need to require a developer to manually provide all the types as part of the `Deserializer` setup.

We now store these types in a `modelLookupTable`. This is a simple dictionary that maps from the types `typeIdentifier` to the metatype itself. We will use this lookup table within the `deserialize` method.

The `deserialize` method takes a JSON array and returns a heterogenous list of `Deserializable` models. The implementation iterates over each entity in the JSON array. It extracts the "type" property from each entity and uses that string to find the relevant metatype in our `modelLookupTable`. If we can find a Swift type that matches the JSON type identifier then we will proceed and try to `decode` that type with the current `jsonEntity`.
If the decoding works successfully, we add the instantiated type to the `parsedModels` array.
At the end of the `deserialize` function we return the list of decoded models.

With all this in place, we can now create an instance of the deserializer and use it:

{{< highlight swift >}}
let deserializer = Deserializer(models: [User.self, Car.self, Phone.self])
let models = deserializer.deserialize(jsonArray)

print(models)
{{< /highlight >}}

The printed output will now be a list of the different instances that have been decoded:

```
[User(name: "test", age: 99), Car(color: "green"), Phone(model: "iPhone"), Car(color: "yellow"), Phone(model: "Anroid Device")]
```

I hope this concept is useful to some other Swift developers as well. You can find a playground with the full example code on [GitHub](https://github.com/Ben-G/Decoding-Heterogeneous-Collections-Swift/blob/master/Decodable.playground/Contents.swift).
