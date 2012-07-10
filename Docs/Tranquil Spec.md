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
self   \ Available inside method blocks
super  \ Available inside method blocks as a message receiver
       \ that calls methods as defined by the current class's superclass
...    \ Array of passed variadic arguments
valid  \ Represents non-nilness, for use in cases where the actual object is not important

\ Variable assignment
a = b \ Variables are local in scope
      \ Variables must begin with a lowercase letter, as uppercase names
      \ are reserved for classes

\ Arrays & Dictionaries
anArray = #[ a, b, c ]                          \ Initialises an array containing 3 elements
aDict  = #{ key => value, anotherKey => value } \ Initializes a dictionary

\ Blocks

aBlock = { ..body.. } \ A block. Defines scope
aBlockWith = { arg0, arg1 | ^arg0 } \ A block that takes two arguments
                                    \ and returns its first argument as-is
aBlock = { arg=123 |  ..statements.. } \ Assignment in the argument list indicates a default value
                                       \ for that argument
`expression` \ Equivalent to { ^expression }


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
	+ new {                   \ Class method ('self' refers to the class itself)
		instance = super new  \ Calls superclass's implementation (which in this case, creates the instance)
		instance#ivar = 123   \ Sets instance variable
		^instance             \ Returns the instance
	}
	- aMethod: a and: b {     \ Instance method taking two arguments ('self' refers to an instance of Klass)
		^self#ivar = a + b    \ Returns the value of self#ivar after setting it to a+b
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

\ String interpolation
a = "variable"
b = "A string with an embedded #{a}." \ Evaluates to "A string with an embedded variable."
```

## Blocks

A block is ..a block of code. It is either used as a function or a method. (A method is simply a block that is executed in response to a message)

By default a block returns `nil`. To return a value the `^` symbol is prefixed to the expression to return.

All arguments are optional and if no default value is specified, `nil` is used.

### Variadic blocks
If in a block one wishes to accept an arbitrary number of argument, he can use the special '...' argument to do so, its value is an array of arguments which you can iterate over. (... must be the last argument specified)

```
variadicBlock = { ... |
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

Operator methods are methods for which the colon after the method name is optional (a + b as opposed to a +: b) and operator precedence is applied. The available ones are:

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
Left shift       |  <<        | <<:                |
Right shift      |  >>        | >>:                |
Concatenation    |  ..        | ..:                |
Exponent         |  ^         | ^:                 |
Index            |  []        | []:                | Postfix operator (a[b])
Index assign     |  []=       | []=::              | Postfix operator (a[b] = c)
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
		- ..: b `self stringByAppendingString: b`
	}
	#TQNumber {
		- ..: b {
			multiplier = 10^(log(10, b) ceil) \ This is pseudo code, the log() block is not implemented
			^self*multiplier + b
		}
	}
	print("%@ %@", "foo".."bar", 1..2) \ outputs 'foobar 12'
	

### Operator assignments

The +,-,* and / operators can also be used in assignment form, that is:

	a += b \ Shorthand for a = a+b
	a *= b \ Shorthand for a = a*b
	\ etc..

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
	
		- reduce: lambda {
			accum = lambda(self next)
			until self isEmpty?
				accum = lambda(self next, accum)
			^accum
		}
	
		- map: mapLambda reduce: reduceLambda {
			(self map: mapLambda) reduce: reduceLambda
		}
	
		- next     `nil`   \ Implemented in subclasses
		- isEmpty? `valid` \ Implemented in subclasses
	}
	
	sum = #[1,2,3] reduce:`n, sum=0| sum + n`
	\ Sum now equals 0+1+2+3 = 6
	