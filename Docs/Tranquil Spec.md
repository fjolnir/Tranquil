# Tranquil

## Basic Syntax

```
\ A backslash outside a string is a comment 
¥ The Yen sign can also be used (See Japanese keyboard layouts to understand why)

\ Keywords
if
else
while
until
break
skip
nil    \ Represents 'nothing'
yes    \ Evaluates to 1.0
no     \ Evaluates to nil
self   \ Available inside method blocks
super  \ Available inside method blocks as a message receiver
       \ that calls methods as defined by the current class's superclass
...    \ Array of passed variadic arguments

\ Variable assignment
a = b \ Variables are local in scope
      \ Variables must begin with a lowercase letter, as uppercase names
      \ are reserved for classes

\ Arrays & Dictionaries
anArray = #[ a, b, c ]                          \ Initialises an array containing 3 elements
aDict  = #{ key => value, anotherKey => value } \ Initializes a dictionary

\ Blocks

aBlock = { ..body.. } \ A block. Defines scope
aBlockWith = { arg0, arg1 | ..body.. } \ A block that takes two arguments
aBlock = { &arg |  ..statements.. } \ Prefixing an argument with & indicates that rather than evaluating it,
                              \ a block with it as it's body should be passed
aBlock = { arg=123 |  ..statements.. } \ Assignment in the argument list indicates a default value
                                 \ for that argument
`expression` \ Equivalent to {^expression}


\ Block calls

aBlock()                         \ Calls a block with no arguments
aBlock(something, somethingElse) \ Calls a block with a two arguments

\ Flow control
 
if ..expression.. {      \ Executes the passed literal block if the expression is non-nil
	..statements..
} else if ..expression.. {
	..statements..
} else {
	..statements..
}

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

\ Objects

#Klass < Object {
	+ new {               \ Class method
		super new.        \ Calls superclass method
		self#ivar = 123   \ Sets instance variable
		^self             \ Returns self
	}
	- aMethod: a and: b {  \ Instance method taking two arguments
		^self#ivar = a + b \ Returns the value of self#ivar after setting it to a+b
	}
}

\ Passing messages to objects
instance = Klass new
instance aMethod: 123 and: 456
instance aMethod: 123. \ To explicitly terminate a message you use a period

\ Accessing member variables
obj#member = 123
a = obj#member

\ Regular expressions
regexp = /[.]*/  \ Regular expressions are delimited by forward slashes
"foobar" matches? /[foo...]/
```

## Blocks

A block is ..a block of code. It is either used as a function or a method. (A method is simply a block that is executed in response to a message)

By default a block returns `nil`. To return a value the `^` symbol is prefixed to the expression to return.

### Variadic blocks
If in a block one wishes to access arguments beyond those defined by the block constructor, he can use the special '...' variable to do so, it is an array of pairs which you can iterate.

```
variadicBlock = {
	... each: { arg |
		print(arg)
	}
}

variadicBlock("foo", "bar", "baz")
\ Outputs:
\ foo
\ bar
\ baz
```

## Objects

There is only one type, the object.

### Built in objects

* nil
* yes
* no


### Classes
Classes are named objects that can be instantiated.

### Inheritance

```
\ Defines a useless subclass of SuperKlass
#Klass < SuperKlass {
}
```

### Self
When a block is called as a result of a message to an object (object method: 123.) the `self` variable is implicitly set to that object. (Assigning to `self` is discouraged)

### Operator methods

Operator methods are methods that follow this calling syntax: a <operator> b. The available ones are:

```
Meaning          |  Operator  | Resulting message    Notes
---------------- | ---------- | ------------------ | -----
Equality         |  ==        | ==:                |
Inequality       |  !=        | !=:                |
Addition         |  +         | +:                 | 
Subtraction      |  -         | -:                 |
Negation         |  -         | -                  | Prefix operator
Multiplication   |  *         | *:                 | 
Division         |  /         | /:                 | 
Less than        |  <         | <:                 |
Greater than     |  >         | >:                 |
Lesser or equal  |  <=        | <=:                |
Greater or equal |  >=        | >=:                |
Index            |  []        | []:                | Postfix operator (a[b])
Index assign     |  []=       | []=::              | Postfix operator (a[b] = c)

\ Example
#Klass {
	- +: b {
		^self plus: b
	},
	- -: b {
		^self subtract: b
	}
}

var = instanceOfKlass - something \ Equivalent to: var = instanceOfKlass subtract:something
```

## Examples

### Fibonacci
```
fibonacci = { index, curr=0, succ=1 |
	num = curr + succ
	if index > 2 {
		^fibonacci(index - 1, succ, num)
	}
	^num
}
fib = fibonacci(50) \ Calculate the 50th number in the fibonacci sequence
```

### Map/Reduce

	#Iterator {
		- map: lambda {
			^self reduce: { obj, accum=#[] |
				accum push lambda(obj)
				^accum
			}
		}
	
		- _reduce: lambda accumulator: accum {
			if self isEmpty? {
				^accum
			} else {
				accum = lambda(self next)
				^self _reduce:lambda accumulator:accum			}
		}
	
		- reduce: lambda {
			accum = lambda(self next)
			^self _reduce:result accumulator:accum
		}
	
		- map: mapLambda reduce: reduceLambda {
			(self map: mapLambda) reduce: reduceLambda
		}
	
		- next     `nil` \ Implemented in subclasses
		- isEmpty? `yes` \ Implemented in subclasses
	}
	
	sum = #[1,2,3] reduce:`n, sum=0| sum + n`
	\ Sum now equals 0+1+2+3 = 6
	