# Tranquil
#### Programming language for live coding – *Just brainstorming*

## Basic Syntax

```
\ A backslash outside a string is a comment 
¥ The Yen sign can also be used (See Japanese keyboard layouts to understand why)

\ Keywords
yes
no
nil
self
super

{
	a=b
	block = {
		a:foo.
	}
	return block
}

\ Variable assignment
a = b \ Variables are local in scope
      \ Variables must begin with a lowercase letter, as uppercase names
      \ are reserved for classes

\ Arrays & Dictionaries
anArray = #[ a, b, c ] \ Initialises an array containing 3 elements
aDict  = #{ key = value, anotherKey = value } \ Initialises a dictionary

\ Blocks

aBlock = { ..body.. } \ A block. Defines scope
aBlockWith = { :arg0 and: arg1 | ..body.. } \ A block that takes two arguments
                                            \ (First argument is always anonymous)                                            aBlock = { :arg0 :arg1 :arg2 |  ..body.. } \ A block that only takes anonymous arguments
aBlock = { :&arg |  ..body.. } \ Prefixing an argument with & indicates that rather than evaluating it,
                               \ a block with it as it's body should be passed
aBlock = { :arg=123 |  ..body.. } \ Assignment in the argument list indicates a default value
                                  \ for that argument


\ Block calls

aBlock()                            \ Calls a block with no arguments
aBlock(something, somethingElse) \ Calls a block with a two arguments

\ Objects

class Klass < Object
	+ new {               \ Class method
		self = super new. \ Calls superclass method
		self#ivar = 123   \ Sets instance variable
		return: self.
	}
	- aMethod: a and: b { \ Instance method taking two arguments
		#ivar = a + b     \ Shorthand for self#ivar
	}
end

\ Passing messages to objects
instance = Klass new
instance aMethod: 123 and: 456
instance aMethod: 123. \ To explicitly terminate a message you use a period

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
	}
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

* nil
* yes
* no


### Classes
Classes are named objects that can be instantiated.

### Inheritance

```
\ Defines a subclass of SuperKlass
class Klass < SuperKlass
end
```

### Self
When a block is called as a result of a message to an object (object method: 123.) the `self` keyword implicitly points to that object.

### Operator methods

Operator methods are methods that follow this calling syntax: a <operator> b. The available ones are:

```
Meaning          |  Operator  | Resulting message    Notes
---------------- | ---------- | ------------------ | -----
Equality         |  ==        | isEqual:           | Default implementation is a simple pointer comparison
Inequality       |  !=        |                    | Syntax sugar for !(a == b) so you can not actually define it
Addition         |  +         | add:               | 
Subtraction      |  -         | subtract:          | Usable as a prefix operator as well (-a not a - b)
Multiplication   |  *         | multiply:          | 
Division         |  /         | divide:            | 
Less than        |  <         | compare:           |
Greater than     |  >         | compare:           |
Lesser or equal  |  <=        | compare:           |
Greater or equal |  >=        | compare:           |
Index            |  []        | valueForKey:       | Postfix operator (a[b])
Index assign     |  []=       | setValue:forKey:   | Postfix operator (a[b] = c)

\ Example
class Klass
	+: b {
		self plus: b
	},
	[]: key {
		self lookUp: key
	}
end
```

## Examples

### Flow control
```
class Object
	- if: ifBlock else: elseBlock {
		ifBlock()
	}
	- unless: unlessBlock else: elseBlock {
		elseBlock()
	}
	<snip>
end

class Nil
	- if: ifBlock else: elseBlock {
		elseBlock()
	}
	- unless:unlessBlock else:elseBlock {
		unlessBlock()
	}
end
```

### Fibonacci
```
fibonacci = { :index :last=1 :beforeLast=0 |
	num = last + beforeLast			
	(index > 0) if: {
		fibonacci: --index :num :last.
	} else: {
		num
	}
}

fib = fibonacci(50) \ Calculate the 50th number in the fibonacci sequence
```