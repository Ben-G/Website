+++
date = "2017-05-11T22:24:54-08:00"
draft = false
title = "A Simple Undo/Redo Implementation in Swift"
slug = "simple-undo-redo-swift"
disqus_url = "http://blog.benjamin-encz.de/post/simple-undo-redo-swift/"
+++

 `NSUndoManager` is a powerful API, but it is geared towards Objective-C code and relies on runtime features. This post demonstrates a simpler alternative that is better suitable for idiomatic Swift code.

<!--more-->

----

There are two fundamentally different ways to implement undo/redo:

- For every action, determine the counteraction and use it for the undo feature (`NSUndoManager` works this way)
- **Record the state of an entity before/after each action and implement undo as switching between these states**

The second approach can be a lot simpler. It can be implemented generically, since there is no need to generate a counteraction for each action. The approach also works naturally with code that uses Swift value types. 

Let's dive right into an example implementation.

## Example Implementation

Let's assume we want to implement undo/redo for annotations that are drawn onto a canvas.

![](Undo_Redo.png)

We're going to use the undo/redo approach in which we keep track of previous and current state for all annotations.

At the end of the post you'll find a link to the full implementation. In the next few paragraphs I will outline the most important aspects.

### Scaffolding

Here's a  simple Swift model for the annotation:

{{< highlight swift >}}

struct Annotation: Hashable, Equatable {
    let id: UUID
    var color: Color
    
    // ...
}
{{< /highlight >}}

We also have a state container that stores all the annotations that are currently on the canvas. Since this feature was implemented at PlanGrid where we use [Flux](http://blog.benjamin-encz.de/post/real-world-flux-ios/), we will also use a Flux store for this example. 

Besides storing all annotations, the store also has a reference to a database instance. The store keeps track of the in-memory state of all annotations on the canvas and it ensures that all changes are written to the database as well. To allow annotation changes, the store provides an interface for saving/deleting annotation (we'll get to the `isUndoRedo` argument in a moment). Lastly, the store keeps track of a stack of undo and redo steps.

{{< highlight swift >}}
class AnnotationStore {

    var db: DB
    var state: Set<Annotation> = []
    var undoStack: [UndoRedoStep<Annotation>] = []
    var redoStack: [UndoRedoStep<Annotation>] = []
    
    func save(annotation: Annotation, isUndoRedo: Bool = false) { 
    	// ...
    }
    
    func delete(annotation: Annotation, isUndoRedo: Bool = false) {
    	// ...
    }
}
{{< /highlight >}}

### Undo/Redo

Our Undo/Redo model is based on state changes. For each annotation that gets modified we keep track of the old and new value. This is the generic model we can use to describe an undo/redo step:

{{< highlight swift >}}
struct UndoRedoStep<T> {
    let oldValue: T?
    let newValue: T?
    
    /// Converts and undo step into a redo step and vice-versa.
    func flip() -> UndoRedoStep<T> {
        return UndoRedoStep(oldValue: self.newValue, newValue: self.oldValue)
    }
}
{{< /highlight >}}

The methods that save and delete annotations, record an `UndoRedoStep<Annotation>` for each change and place it on the undo stack:

{{< highlight swift >}}
  func save(annotation: Annotation, isUndoRedo: Bool = false) {
      // Don't record undo step for actions that are performed 
      // as part of undo/redo.
      if !isUndoRedo {
          // Fetch old value
          let oldValue = self.annotationById(annotationId: annotation.id)
          // Store change on undo stack
          let undoStep = UndoRedoStep(oldValue: oldValue, newValue: annotation)
          self.undoStack.append(undoStep)
    
          // Reset redo stack after each user action that is not an undo/redo.
          self.redoStack = []
      }
    
      // Replace old with new annotation
      self.state.remove(annotation)
      self.state.insert(annotation)
    
      self.db.saveAnnotation(annotation: annotation)
  }
{{< /highlight >}}

The deletion counterpart of this method is extremly similar, so I won't discuss it here.

Now that we keep track of all changes, we can implement the undo/redo feature.

{{< highlight swift >}}
func undo() {
        guard let undoRedoStep = self.undoStack.popLast() else {
            return
        }
    
        self.perform(undoRedoStep: undoRedoStep)
    
        self.redoStack.append(undoRedoStep.flip())
    }

func redo() {
    guard let undoRedoStep = self.redoStack.popLast() else {
        return
    }
    
    self.perform(undoRedoStep: undoRedoStep)
    
    self.undoStack.append(undoRedoStep.flip())
}
{{< /highlight >}}

The code here is very simple. We fetch the latest undo/redo action from the stack. We perform the change recorded in that step in a separate method that is shared between undo and redo. Then we append the inverted version of the change to the opposite stack (e.g. an undo action is flipped and placed on the redo stack).

The core of the undo/redo mechanism lives in the `perform(undoRedoStep:)` method.

{{< highlight swift >}}
func perform(undoRedoStep: UndoRedoStep<Annotation>) {
    // Switch over the old and new value and call a store method that
    // implements the transition between these values.
    switch (undoRedoStep.oldValue, undoRedoStep.newValue) {
    // Old and new value are non-nil: 
    // we can undo by updating annotation with old value.
    case let (oldValue?, newValue?):
        self.save(annotation: oldValue, isUndoRedo: true)
    // Undo a deletion (new value is nil, old value was non-nil)
    // by creating an annotation.
    case (let oldValue?, nil):
        // Our `save` implementation also handles creates, but depending
        // on your DB interface these might be separate methods.
        self.save(annotation: oldValue, isUndoRedo: true)
    // Undo a creation (old value is nil, new value is non-nil) 
    // by deleting an annotation.
    case (nil, let newValue?):
        self.delete(annotation: newValue, isUndoRedo: true)
    default:
        fatalError("Undo step with neither old nor new value makes no sense")
    }
}
{{< /highlight >}}

We look at the old and the new value of each change. Then we call a method on the store that replaces the formerly new value with the formerly old value; that is the step that performs the undo/redo. In general we need to handle three cases:

- Undo creation of an annotation: can be done via deletion
- Undo deletion of an annotation: can be done via creation
- Undo the modification of an annotation: can be done by replacing existing annotation with new one

The method above does this elegantly by leveraging Swift pattern matching.

The Store API now allows us to modify annotations and undo changes:

{{< highlight swift >}}
var annotation = Annotation(color: .red)
store.save(annotation: annotation) // annotation is red

annotation.color = .blue
store.save(annotation: annotation) // annotation is blue

store.undo()
print(store.annotations) // prints one annotation in "red"
{{< /highlight >}}


## Conclusion

That's all there is. By leveraging Swift's value types we can keep track of multiple versions of an entity. We can then implement undo/redo as switching between entity states. This has the advantage that we don't need to generate counteractions for all user actions.

I'm assuming in future we will see more alternatives to Cocoa APIs that are simpler and more suitable for Swift.

You can find a [Playground with a fully working example here](https://github.com/Ben-G/UndoRedoSwift).
