+++
date = "2014-05-28T22:24:54-08:00"
draft = false
title = "Objective-C: Accessing backing iVars of properties in subclasses"
+++

Most Objective-C developers have a fairly good understanding of properties and instance variables and how these two work together.

Today I want to discuss an interesting case that will force you to understand the details of the relationship between instance variables and properties. In case you already know these details, this remains an interesting example of how complicated Objective-C can be every once in a while.

##Our Scenario

Let's assume we want to create a very simple **ClassA** with a property called `age` of type `NSInteger`:

	@interface ClassA : NSObject

	@property (assign, nonatomic) NSInteger age;

	@end
 
And a **ClassB** that inherits from **ClassA**.

We want to initialize the `age` from within the `init` method in *ClassA.m*. As per best practice [we don't want to access the property in the initializer method](http://stackoverflow.com/questions/5932677/initializing-a-property-dot-notation/5932733#5932733) but want to use the auto synthesized instance variable instead:

	@implementation ClassA

    - (instancetype)init {
        self = [super init];
        
        if (self) {
            _age = 6;
        }
        
        return self;
    }
    
    @end
    
So far, so simple. Now let's assume that **Class B** wants to override the initializer (and again we want to avoid accessing a property!):
	
    @implementation ClassB

    - (instancetype)init {
        self = [super init];
        
        if (self) {
            _age = 3; // <- compile error 
        }
        
        return self;
    }
    
    @end

Unfortunately this will result in a **compile error**. Bummer! 

The instance variable `_age` is synthesized in *ClassA.m* and therefore is not visible in *ClassB.m*. 

How could we fix this?

##Synthesize in ClassB.m ? 

This one of the solutions that I have seen around on the web. If `_age` is not available in *ClassB.m* because it is synthesized in *ClassA.m*, why don't we add a synthesize to *ClassB.m* to make `_age` visible there, too?

    @implementation ClassB1
    
    // add synthesize statement to make _age visible
    @synthesize age = _age;
    
    - (instancetype)init {
        self = [super init];
        
        if (self) {
            _age = 3;
        }
        
        return self;
    }
    
    @end
    
Indeed, this will resolve the compile error! Just to be sure that this is a valid solution, let's add some simple tests:

    @implementation ClassB1
    
    @synthesize age = _age;
    
    - (instancetype)init {
        self = [super init];
        
        if (self) {
            _age = 3;
            
            NSLog(@"ClassB1 _age: %d", _age);
            NSLog(@"ClassB1 self.age: %d", self.age);
            NSLog(@"ClassB1 super.age: %d", super.age);
    
        }
        
        return self;
    }
    
    @end

And here is the trimmed console output after initializing `ClassB1`:

>  ClassB1 _age: 3
>
>  ClassB1 self.age: 3
>  
>  ClassB1 super.age: 6

**Wow.** This is not the behaviour we want! We are overriding the `init` method and setting `_age` to "6" but when asking for the `age` on our super class we receive "3"?

Why does this happen? By adding a `synthesize` statement to *ClassB1.m* we're creating an entirely **new** instance variable that happens to be called *_age* as well, but other than the name has nothing to do with the *_age* instance variable declared in *ClassA1.m*. The properties of *ClassA1* and *ClassB1* are now operating on different instance variables. 

**Still wonder why this is horrible?** Take a look at this little test in the `init` method of *ClassA1.m*:

	_age = 6;
    NSLog(@"ClassA1 self.age: %d", self.age);
    NSLog(@"ClassA1 _age: %d", _age);

The trimmed output:

>	ClassA1 self.age: 0
>
>   ClassA1 _age: 6

**Yikes!** When accessing `self.age` *ClassA* is actually accessing the `_age` instance variable that is declared in *ClassB.m* and stores an entirely different value than  the `_age` instance variable available to *ClassA.m*. Now that we know the extent of the mess - how do we go about fixing it?

~~Scratch this approach~~, and move on to option number two.

##Declare in ClassA.h ?

We now know that we cannot synthesize / declare the `_age` instance variable in *ClassB.m* because we will create a new instance variable instead of using the one of our super class *ClassA*. 

In order to make the auto synthesized variable `_age` visible for *ClassB* we can explicitly declare the instance variable in *ClassA.h*:

    @interface ClassA2 : NSObject {
    	NSInteger _age;
    }
    
    @property (assign, nonatomic) NSInteger age;
    
    @end

Now *ClassB* will know that `_age` exists by importing *ClassA.h*:

    @implementation ClassB2
    
    - (instancetype)init {
        self = [super init];
        
        if (self) {
            _age = 3;
            
            NSLog(@"ClassB1 _age: %d", _age);
            NSLog(@"ClassB1 self.age: %d", self.age);
            NSLog(@"ClassB1 super.age: %d", super.age);
            
        }
        
        return self;
    }
    
    @end

That does the job - no compile errors! What about the logs? (Note: ClassA uses the same test `init` method as in the first approach).

> ClassA2 self.age: 6

> ClassA2 _age: 6

> ClassB2 _age: 3

> ClassB2 self.age: 3

> ClassB2 super.age: 3

Now this looks right! First *ClassA* gets initialized and gets the same result for `_age` and `self.age`. Then we override the value of `_age` setting it to "3" in *ClassB* and can see that `_age`, `self.age`, `super.age` all return consistent values.

**Nice!** This is a working solution. However, it has one asthetic downside. We are now exposing an instance variable in our header file (**ClassA.h**) that is not actually part of the interface of our class (the instance variable is *protected* and cannot be accessed by other classes that aren't a subclass of *ClassA*).

Let's take a look at a third solution.

##Use a class extension in a separate header file!

We now know that the `_age` instance variable needs to be part of the interface of *ClassA* in order for subclasses to be able to access it. 

A neat way in Objective-C to extract certain parts of the interface that are only relevant to subclasses is creating a [Class Extension](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/CustomizingExistingClasses/CustomizingExistingClasses.html) in a seperate header file.

In solution number three the interface of *ClassA* is nice and clean:

    @interface ClassA3 : NSObject
    
    @property (assign, nonatomic) NSInteger age;
    
    @end
    
The `_age` instace variable is now declared in  a seperate header called *ClassA3_Protected.h*:

    @interface ClassA3 () {
        @protected
        NSInteger _age;
    }
    
    @end

Since instance variables in class extensions are *private* by default we need to explicitly declare the `_age` variable to be *protected*.

Now we can import this class extension into *ClassB3.m*  to get access to the `_age` variable:

    #import "ClassB3.h"
    #import "ClassA3_Protected.h"
    
    @implementation ClassB3
    
    - (instancetype)init {
        self = [super init];
        
        if (self) {
            _age = 3;
            
            NSLog(@"ClassB3 _age: %d", _age);
            NSLog(@"ClassB3 self.age: %d", self.age);
            NSLog(@"ClassB3 super.age: %d", super.age);
            
        }
        return self;
    }
    
    @end
    
No compile errors and no unnecessary cluttered interface file! What about the logs? (Note: ClassA uses the same test `init` method as in the the two previous approaches):

> ClassA2 self.age: 6

> ClassA2 _age: 6

> ClassB2 _age: 3

> ClassB2 self.age: 3

> ClassB2 super.age: 3

Great! This is the same output as in attempt number two. Everything is working as expected and we have a clean interface file only containing the property.

**This little example shows how complex some Objective-C language details are and how important it can be to undertand them.**

You can find the code examples used throughout this tutorial in the [GitHub repository for this blogpost](https://github.com/Ben-G/Property_InstanceVariables_Inheritance).