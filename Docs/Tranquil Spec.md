# Tranquil

## Basic Syntax

	\ A backslash outside a string starts a comment
	
	\ Reserved Keywords
	if
	then
	else
	while
	until
	and
	or
	import
	async
	wait
	break   \ Prematurely terminates a loop
	skip    \ Skips to the end of the current iteration of a loop
	nil     \ Represents an empty value (`no` is a synonym)
	valid   \ Represents non-nilness, for use in cases where the actual object value is not of concern (`yes` is a synonym)
	self    \ Available inside method blocks
	super   \ Available inside method blocks as a message receiver
	        \ responds to messages as defined by the current class's superclass
	...     \ Array of passed variadic arguments
	nothing \ A constant representing 'nothingness' or 'absence of value'
	
	\ Built-in Operators
	||  \ Or:  Evaluates to the first non-nil expression: (123 || nil) == 123      (Can be chained)
	&&  \ And: Evaluates to the last expression if all are non-nil:  (1 && 2) == 2 (Can be chained)
	
	\ Variables		
	a = b \ Variables are local in scope
	      \ (Must begin with a lowercase letter, as uppercase names are reserved for classes and values imported from C headers)
	a, b = 1, 2 \ Comma separated operands can be used for multiple assignment
	a, b = b, a \ The right hand sides are evaluated before the assignment, so swapping values works
	a, b = nil  \ If there are fewer operands on the right hand side the last one is used for the missing ones
	
	\ Weak references
	a = ~b \ Assigns a to a weak reference to b. (Concept explained later)
	
	\ Collection literals (Arrays & Dictionaries)
	anArray = [ a, b, c ]                           \ Initialises an array containing 3 elements
	aDict   = { key => value, anotherKey => value } \ Initializes a dictionary
	
	\ Blocks
	aBlock = { ..body.. } \ A block. Defines scope (Empty braces: `{}` constitute an empty dictionary, not an empty block)
	aBlockWith = { arg0, arg1 | ^arg0 } \ A block that takes two arguments
	                                    \ and returns its first argument as-is (The last statement in a block is implicitly
	                                      returned so the `^` is optional in this case)
	aBlock = { arg=123 |  ..statements.. } \ Assignment in the argument list indicates a default value for that argument
	`..expression..` \ A single expression block; recommended when embedding short blocks in other expressions.
	
	^..expression.. \ Returns the value of `expression`
	^^..expression.. \ Same as above but, returns from the lexical parent of the block. (Explained in "Non-local returns")
	
	
	\ Block calls
	aBlock()                         \ Calls a block with no arguments
	aBlock(something, somethingElse) \ Calls a block with a two arguments
	aBlock { ..statements.. }        \ A valid callee followed by a literal block, is equivalent to a call with a single block argument
	
    \ Macros (Called the same way as a block would)
    *Choice { cond, a, b | cond ? a ! b }  \ A contrived example
	
	\ Flow control
	if ..expression.. {      \ Executes the passed literal block if the expression is non-nil
		..statements..       \ (The braces can be omitted if the block contains only one statement)
	} else if ..expression.. {
		..statements..
	} else {
		..statements..
	}
	if ..expression.. then ..statement.. \ If you infix the expression & action with `then` you can type a single statement without wrapping in a block.

	unless ..expression.. {  \ Executes the passed literal block if the expression is nil
		..statements..
	} else {
		..statements..
	}
	
	while ..expression.. {  \ Executes the passed literal block repeatedly while the expression is non-nil
		..statements..      \ or a break statement is encountered
		                    \ a skip statement jumps back to the top of the loop
	}
	until ..expression.. {  \ Executes the passed literal block repeatedly until the expression is non-nil
		..statements..      \ skip&continue work like in while
	}
	
	
	\ Postfix form of the operators above is also supported(With the obvious exception of `else`); for example:
	done = yes if percentage >= 100
	done = tryAgain() until done

	\ Ternary operator
	..condition.. ? ..expression.. ! ..expression..
	
	\ Objects
	
	@Klass < Object {
	    message: argument         \ Sends `message:` to the class after it is created
	    
		+ withObject: obj {                   \ Class method ('self' refers to the class itself)
			instance = super new  \ Calls superclass's implementation (which in this case, creates the instance)
			instance object = obj   \ Sets an instance variable
			^instance               \ Returns the instance
		}
		
		- aMethodTaking: a and: b {  \ Instance method taking two arguments ('self' refers to an instance of Klass)
			@ivar = a + b            \ Returns the value of `#ivar` after setting it to `a + b`
		}
		
		- aMethodWith: arg1 [andOptionalArgument: arg2 = "default value"] { \ Wrapping trailing selector/argument pairs in brackets
		    "2 arguments were passed" print if arg2 ~= "default value"      \ that they're optional.
		}
	}
	
	\ Instance variables (Only accessible within methods)
	@instanceVar = 123  \ @ prefix denotes instance variable
	
	\ Passing messages to objects
	instance = Klass new
	instance aMethod: 123 and: 456
	instance aMethod: 123. \ To explicitly terminate a message you use a period
	
	instance aMethod: 123; anotherMethod: 456 \ A semicolon can be used to separate multiple messages to the same receiver
	                                          \ This is referred to as "cascading"
    instance method = 123 \ Assigning to a unary message is equivalent to calling the setter variant of that method
                          \ in this case `instance setMethod: 123`
	
	\ Regular expressions
	regexp = /[.]*/              \ Regular expressions are delimited by forward slashes
	/[foo...]/ matches: "foobar" \ Checks an expression against a string by sending it `matches:`
	
	\ String interpolation
	a = "expression"
	b = "A string with an embedded «a»."  \ Evaluates to "A string with an embedded expression."
	
	\ Immutable strings / Symbols
	a = #string
	b = #"constant string with spaces"
	
	\ Importing other files
	import "..filename.."  \ Imports `filename`.
	                       \ (import statements must appear at the beginning of the
	                       \ file, since they are evaluated at compile-time)
	import "AppKit"        \ You can also import Objective-C headers.
	                       \ In this case the header AppKit.h in AppKit.framework is read.
	                       
    \ Concurrency
    async ..expression..        \ Executes `expression` asynchronously
    var = async ..expression..  \ Assigns the `var` to a "promise" which will point to the result of `expression` when it has finished running.
    wait                        \ Waits for any asynchronous operations created in the current block to finish
    wait(5)                     \ Waits for 5 seconds, if all operations finish in time, it returns `valid` otherwise `nil`

    whenFinished ..block..      \ Executes `block` when all asynchronous operations created in the current block are finished, without blocking.
                                \ (`block` is executed on the program's main thread)
    lock ..expression.. { \ Acquires a lock on the result of `expression`. If one has already been taken, it waits.
        ..statements..
    }
    
    \ Memory management
    collect { ..statements.. } \ Releases all memory used by the statements within the
                               \ literal block, as soon as it's over. (Usually  memory is released when the containing block returns)


## Blocks

A block is ..a block of code. It is either used as a function or a method. (A method is simply a block that is executed in response to a message)

By default a block returns `nil`. To return a value the `^` symbol is prefixed to the expression to return.

All arguments are optional and if no default value is specified, `nil` is used.

### Variadic blocks
If in a block one wishes to accept an arbitrary number of argument, he can use the special '...' argument to do so, its value is an array of arguments which you can iterate over. (... must be the last argument specified)

	variadicBlock = { ... |
		... each: `arg | arg print`
	}
	
	variadicBlock("foo", "bar", "baz")
	\ Outputs:
	\ foo
	\ bar
	\ baz

### Non-local returns
Non-local are a very powerful feature that allow blocks to not only return from themselves, but also from the block that created them.
This is best illustrated by an example:

    a = {
        b = {                
            ^123
        }
        b()
        ^456
    }
    a() print \ This prints 456
    
    a = {
        b = {
            ^^123
        }
        b()
        ^456
    }
    a() print \ This prints 123
    
A common use case is for error handlers, or for returning inside looping blocks (such as arguments to each:).

    find = `needle| haystack each: { obj | ^^obj if obj == needle }`
    
    ^HTTP connectTo: "example.com" onError: { err |
        "Couldn't connect! (Error was: «err»)" print
        ^^nil
    }

## Macros

A macro can be thought of as an inline block; it gets expanded to it's contents at compile time.
This means that a macro usage incurs no runtime cost, does not evaluate it's arguments until they're
actually used and that they can not capture values from their lexical scope (since that would make no sense)
They can (and do) however reference variables in their expansion scope; this is both useful and dangerous.
Arg
    
    *Choice `cond, a, b | cond ? a ! b`  \ A contrived example
    var = Choice(var == something, foo(), bar()) \ Expanded to `var == something ? foo() ! bar()` at
                                                 \ compile time; meaning that foo() & bar() will not be
                                                 \ evaluated unless the condition indicates they should
                                                 \ Had you used a block, both would have been evaluated
                                                 \ before it was called, which is obviously not correct
                                                 \ in this case.

                                                     
    *CaptureDemo(foo) `baz = [foo, bar]`
    foo = 123
    bar = 456
    CaptureDemo(0)
    baz == [0, 456] \ At the expansion point, variables called both `foo`&`bar` exist, however
                    \ the argument of the same name shadows `foo` => 0 is used rather than 123
                    \ The variable `baz` is then declared directly in the expansion scope.

## Flow Control

Flow control blocks are different from standard blocks in that they are statements only, and can therefore not be used as expressions. They also execute within the parent block (Unlike standard blocks which have their own execution context) which means they do not create a new scope; and that if one returns from inside a flow control block, the parent block is returned from.


## Objects

There is only one type, the object.

### Classes
Classes are named objects that can be instantiated.

### Inheritance

	\ Defines a useless subclass of SuperKlass
	#Klass < SuperKlass {
	}

### Methods
Methods are blocks that are executed in response to a message.

### Self
When a block is called as a result of a message to an object (object method: 123.) the `self` variable is implicitly set to that object. (Assigning to `self` is discouraged)

### Super
When a block is called as a result of a message to an object, the `super` keyword can be used as a message receiver to call the current object's superclass's implementation of a method (Even if the object's class has overridden it).

### Nothing
`nothing` represents the absence of value. Which is importantly not the same as `nil`. `nothing` is used for uses where you need there to be a difference between an empty value, and no value. For example if you call a block passing `nothing` as an argument, then the block will receive the default value for that parameter, not the `nothing` object you passed.

### Operator methods

Operator methods are methods for which the colon after the method name is optional (a + b as opposed to a +: b) and operator precedence is applied. The available ones are:

```
Meaning          |  Operator  | Resulting message    Notes
---------------- | ---------- | ------------------ | -----
Equality         |  ==        | isEqualTo:         |
Inequality       |  ~=        | notEqualTo:        |
Addition         |  +         | add:               | 
Subtraction      |  -         | subtract:          |
Negation         |  -         | negate             | Prefix operator
Multiplication   |  *         | multiply:          | 
Division         |  /         | divideBy:          | 
Modulo           |  %         | modulo:            |
Less than        |  <         | isLesserThan:      |
Greater than     |  >         | isGreaterThan:     |
Lesser or equal  |  <=        | isLTETo:           |
Greater or equal |  >=        | isGTETo:           |
Exponent         |  ^         | pow:               |
Index            |  []        | at:                | Postfix operator (a[b])
Index assign     |  []=       | set:to:            | Postfix operator (a[b] = c)
```


#### Example

	#Klass {
		- +: b {
			^self plus: b
		},
		- -: b {
			^self subtract: b
		}
	}
	
	var = instanceOfKlass - something \ Equivalent to: var = instanceOfKlass subtract:something
	
	#NSString {
		- +: b `self stringByAppendingString: b`
	}
	#TQNumber {
        - []: i {
            max = self log floor
            t = (self / 10^(max-i)) floor
            ^t - (t/10) floor * 10
        }
    }
	a = "foo"+"bar" \ == "foobar"
	b = 1234.5[4]   \ == 5
	

### Operator assignments

The +,-,* and / operators can also be used in assignment form, that is:

	a += b \ Shorthand for a = a+b
	a *= b \ Shorthand for a = a*b
	\ etc..

## Weak references

Usually when assigning to a variable, or using one in a block, you want the value in question to be kept around for as long as the variable/block does. But there are cases where this can cause an issue called a "reference cycle":

	c ref = a
	a ref = b
	b ref = a
	
	c ref = nil

in the example above, `a` & `b` both hold references to the other, and `c` holds one to `a`. Then at the end, `c`'s reference is removed. One would assume that since `a` & `b` are now unreachable, that they would be deallocated. However this is not the case. Because they still hold a reference to each other, the runtime can't know that they are in fact unreachable. We can fix this by instead writing the previous example as follows:

	c ref = a
	a ref = b
	b ref = ~a
	
	c ref = nil

Now `b` holds a "weak" reference to `a`. That means that it does not hold on to `a`, so when `a` has no other remaining references, it is deallocated and `b`'s reference is set to `nil`, breaking the cycle.

A good way of knowing when to use weak references is to think about object references as ownership. If `a` "owns" `b` then `a` should hold a strong reference to `b`, but because `b` is the owned object, if it for some reason must have a reference to `a`, it should hold a weak one:

	#Klass {
		- new {
			super new
			#someBlock = {
				~self someMethod
			}
			^self
		}
		- startUpdating {
			PeriodicUpdater callBlockPeriodically: #someBlock
		}
	}

In this example we had a block that is stored in an instance variable of `Klass`. This block was being used to periodically call a method on `self` but because this block is owned by the `Klass` instance, we use a weak reference to `self` in order to not cause the block to complete a cyclical strong reference between it and `self`.

## Concurrency

Using the `async` keyword, an expression can be executed asynchronously. If one wishes to execute multiple expressions and then wait for all of them to finish, the `wait` keyword is used.

`async` is a statement and can not be used for example as a message parameter (`obj foo: async block()` **is not ok**). With one exception: assignment. `var = async ..expression..` is valid, and simply sets `var` to the result of `expression` once it has finished executing.

    \ This example is rather contrived; the cost of an async is higher than of the fib call. But in a perfect world this is how you'd write a recursive parallel fibonacci finder.
    fib = { n |
        if n > 1 {
            a = async fib(n-1)
            b = fib(n-2)
            wait            
            ^a + b
        }
        ^n
    }

The following example shows a block that spawns a few operations and returns immediately. Then when the operations are finished, updateUI() is called on the program's main thread.
    
    #Array {
        - mapInParallel: lambda {
			self[i] = async lambda(self[i]) until i++ == self count - 1
		}
	}
    executeOperations = {
        async [1,2,3,4] mapInParallel: `i | expensiveOp(i)`
        whenFinished { updateUI() }
    }

### Promises

A promise is an object that forwards all messages to the object that it is resolved to; and errors out if one attempts to send a message to it before it is resolved.

    myPromise = async {
        usleep(500)
        ^123
    }
    myPromise method \ myPromise still has not been resolved => crash
    Usleep(1000)
    myPromise method \ The block has finished executing at this point => message sent successfully
    
    \ (The correct way of doing the above would be to either send `isFulfilled` or `waitTillFulfilled` to the promise before attempting to use it)


## Examples

### Error handling

    #MyClass {
        + doSomethingWith: obj [onError: errorHandler] { \ The error handler should be optional in case the caller does not care to handle it
            errorHandler call unless doIt(obj)
        }
    }
    MyClass doSomethingWith: 123 onError: { "An error occurred while processing 123!" print }

### Fibonacci

    fibonacci = { index, curr=0, succ=1 |
        num = curr + succ 
        if index > 2 then ^fibonacci(index - 1, succ, num) else ^num
    }
    fib = fibonacci(50) \ Calculate the 50th number in the fibonacci sequence


### Map/Reduce

	#Iterator {
		- map: lambda {
			^self reduce: { obj, accum=[] |
				^accum push: lambda(obj); self
			}
		}
	
		- reduce: lambda {
			accum = lambda(self next)
			accum = lambda(self next, accum) until self isEmpty?
			^accum
		}
	
		- map: mapLambda reduce: reduceLambda {
			self map: mapLambda; reduce: reduceLambda
		}
	
		- next     `nil`   \ Implemented in subclasses
		- isEmpty? `valid` \ Implemented in subclasses
	}
	
	sum = [1,2,3] reduce: `n, sum=0| sum + n`
	\ Sum now equals 0+1+2+3 = 6
