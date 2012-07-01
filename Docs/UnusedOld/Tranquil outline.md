# Tranquil
#### Programming language for live coding – *Just brainstorming*

## Basic Syntax

```
\ A backslash outside a string is a comment 

\ Keywords
yes
no
nil
self
super

\ Variable assignment
a = b \ Variables are local in scope

\ Blocks

aBlock = { ..body.. } \ A block. Defines scope
aBlockWith = { :arg0 and: arg1 | ..body.. } \ A block that takes two arguments
                                            \ (First argument is always anonymous)
aBlock = { :arg0 :arg1 :arg2 |  ..body.. } \ A block that only takes anonymous arguments
aBlock = { :&arg |  ..body.. } \ Prefixing an argument with & indicates that rather than evaluating it,
                               \ a block with it as it's contents should  be created.
aBlock = { :arg=123 |  ..body.. } \ An assignment in the argument list indicates a default value
                                  \ for that argument


\ Block calls

aBlock. \ Calls a block with no arguments
aBlockWith: "something" and: "something else". \ Calling a block using named arguments
                                               \ (Names do not need to be unique)
aBlock: arg0 :arg1 :arg2. \ Calls a block passing in 3 anonymous arguments

aBlock: arg1 :(bar.methodWith: arg1 and: arg2.). \ To nest block calls you must wrap the
                                                 \ nested calls in parentheses

\ Objects

\ When initially defining an object, you only define the messages it responds to.
\ Member variables are not a part of the initialization statement.
simpleObject = [
	aMethod { :a and: b | \ Defines a message that the object responds to
                         \ 	(In this case aMethod:and:)
		\ Body
	}
]

\ Passing messages to objects
simpleObject aMethod: 123 and: 456.

\ Accessing member variables
obj#member = 123
a = obj#member
```

## Blocks

A block is ..a block of code. It is either used as a function or a method.

By default a block returns `nil`. To return a value the `return` keyword is used.

### Variadic blocks
If in a block one wishes to access arguments beyond those defined by the block constructor, he can use the special '...' variable to do so, it is an array of pairs which you can iterate.

```
variadicBlock = {
	... each: { :pair |
		print pair.name + " -> " + pair.value.
	}.
}

variadicBlock: "foo" bar: "baz" :"baaz".
\ Outputs:
\ variadicBlock => foo
\ bar => baz
\ nil => baaz
```

## Objects

There is only one type, the object.

### Built in objects

* Object – The root class. Implements inheritance
	* String
	* Number
	* Array
	* Dictionary
* nil
* yes
* no

### Self
When a block is called as a result of a message to an object (object method: 123.) the `self` keyword implicitly points to that object.

### Metaobjects
An object can be associated with a so called meta object. What this means is that when a message that the object does not respond to is called, it is forwarded to it's metaobject. This enables a form of inheritance.

### Inheritance
The built-in `Object` implements the necessary functionality for inheritance.

```
\ To create a new class you would send the extend: message to Object,
\ which returns a new object that can be instantiated.
Klass = Object extend: [ name -> block anotherName -> block ].
anObj = Klass new.
```

### Operator methods

Operator methods are methods that follow this calling syntax: a <operator> b. The available ones are:

```
Meaning          |  Operator  | Notes
---------------- | ---------- | -----
Equality         |  ==        | Default implementation is a simple pointer comparison
Inequality       |  !=        | Syntax sugar for !(a == b) so you can not actually define it
Addition         |  +         | 
Subtraction      |  -         | Usable as a prefix operator as well (-a not a - b)
Multiplication   |  *         |
Division         |  /         |
Less than        |  <         |
Greater than     |  >         |
Lesser or equal  |  <=        |
Greater or equal |  >=        |
Bitwise AND      |  &         |
Bitwise OR       |  |         |
Bitwise NOT      |  ~         |
Bitwise XOR      |  ^         |
Bitwise LSHIFT   |  <<        |
Bitwise RSHIFT   |  >>        |
Index            |  []        | Postfix operator (a[b])
Index assign     |  []=       | Postfix operator (a[b] = c)

\ Example
klass = [
	+ -> { b |
		self plus: b.
	},
	[] -> { :key |
		self lookUp: key.
	}
]
```

## Examples

### Flow control
```
Object = [
	if -> { :ifBlock else: elseBlock |
		ifBlock.
	}
	unless -> { :unlessBlock else: elseBlock |
		elseBlock.
	}
	<snip>
]

nil = Object.extend: [
	if -> { :ifBlock else: elseBlock |
		elseBlock.
	}
	unless -> { :unlessBlock else: elseBlock |
		unlessBlock.
	}
]
```

### Fibonacci
```
fibonacci = { :index :last=1 :beforeLast=0 |
	num = last + beforeLast			
	(index > 0) if: {
		fibonacci: --index :num :last.
	} else: {
		num
	}.
}

fib = fibonacci: 50. \ Calculate the 50th number in the fibonacci sequence
```