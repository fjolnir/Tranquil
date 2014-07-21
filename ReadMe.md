# Tranquil

Tranquil is a programming language built on top of LLVM & the Objective-C Runtime.

It aims to provide a more expressive & easy to use way to write Mac and iOS Apps.

It's features include:

* Compatibility with C/ObjC headers, meaning that there is no need to create special bindings for C APIs.
* Automatic memory management.
* Line by line debugging. (Using LLDB or GDB) — *still under development, but breaking on, and stepping over source lines is supported*
* Dynamic Typing.
* Language level concurrency support.
* String interpolation.
* Multiple assignment.
* Message cascading.
* Unlimited number range.
* Unicode through&through (変数=123 works fine)
* Good performance, even at this extremely early stage.
* And more..

However, Tranquil is still extremely experimental and you shouldn't use it for anything other than exploration and learning.

## How to build and run

The simplest way of getting started is to use the binary [installer](http://d.asgeirsson.is/UGKR). Everything will be placed into `/usr/local/tranquil` (Requires Xcode 5.1 to be installed)

If you wish to contribute, you can use the install script instead which checks out the latest source and sets up the development environment.

    > curl -fsSkL https://raw.github.com/fjolnir/Tranquil/master/Tools/install.sh | /bin/zsh
    > /usr/local/tranquil/bin/tqrepl

**Note:** OS X ≥ 10.7 or iOS ≥ 5 is required to run compiled tranquil programs. 10.9 is required to compile.

## Learning the language

To learn more about Tranquil you should read the [specification](https://github.com/fjolnir/Tranquil/blob/master/Docs/Tranquil%20Spec.md) and check out the [tests](https://github.com/fjolnir/Tranquil/blob/master/Tests).

You can also talk to me directly by visiting [#tranquil](irc://irc.freenode.net/tranquil) on irc.freenode.net.

And here're a couple of examples:

### Print a Mandelbrot fractal

```
mandelbrot = { x, y, bailout=16, maxIter=1000 |
    cr, ci = y-0.5, x
    zi, zr = 0
 
    maxIter times: {
        temp = zr*zi
        zr2, zi2 = zr^2, zi^2
        zr = zr2 - zi2 + cr
        zi = 2*temp + ci
        ^^no if zi2 + zr2 > bailout
    }
    ^yes
}
 
(-1 to: 1 withStep: 1/40) each: { y |
    (-1 to: 1 withStep: 1/40) each: { x |
        (mandelbrot(x, y) ? #● ! #◦) printWithoutNl
    }
    #"" print
}
```

### Iterate an array

```
alternatives = ["Objective-C", "Ruby", "Nu", "Perl", "Python"]
alternatives each: `alternative | "Tranquil is nicer than «alternative»" print`
"Or so I hope at least." print
```

### Reduce

```
sum = (0 to: 1000000) reduce: `obj, accum=0 | obj+accum`
```

### Do two things at the same time

```
a = async foo()
b = bar()
whenFinished {
    "a is «a» and b is: «b»" print
}
```

### Chain messages (Without having to return self from every method you write)

```
var = Character new setName: "Deckard"; setOccupation: "Blade Runner"; self
```

### Do multiple assignment

```
a, b = b, a  \ Swap b&a
```

### Return non-locally

```
a = {
    b = {
        ^^123
    }
    b()
    ^321
}
a() print \ This prints '123'
```

### Calculate fibonacci numbers (In a not-so-performant manner)

```
fib = `n | n > 1 ? fib(n-1) + fib(n-2) ! n`
fib(10) print
```

### Make a database query (Using [DatabaseKit](http://github.com/fjolnir/DatabaseKit))

    import "DatabaseKit"
    db = DB withURL: "sqlite://data/database.sqlite"
    query = db[#aTable] select: #field; where: { #anotherField => aValue }
    val   = query[#field]
    
    \ We can write that more concisely as:
    val   = table[{ #anotherField => aValue }][#field]
    
### Create a Web Server (Using [HTTPKit](http://github.com/fjolnir/HTTPKit))

    import "HTTPKit"
    HTTP new handleGet: "/"
                  with: `connection| "Hello World!"`;
          listenOnPort: 8080
               onError: `"Unable to start server" print`
    
### Evaluate a regular expression

```
"Foobar starts with foo." print if /foo[a-z]+/i matches: "Foobar"
```

### Use the OpenGL & GLUT APIs

```
import "GLUT" \ This simply reads in your GLUT.h header. No bindings are required.

GlutInit(0, nil)
GlutInitDisplayMode(GLUT_DOUBLE)
GlutInitWindowSize(640, 480)
GlutInitWindowPosition(200, 200)
GlutCreateWindow("Tranquil is cool as beans!")

GlClearColor(0, 0, 0, 0)
GlScalef(0.4, 0.4, 0.4)

GlutDisplayFunc({
    GlRotatef(0.1, 0, 1, 0)
    GlClear(GL_COLOR_BUFFER_BIT)
    GlColor3f(0, 1, 0)
        GlutWireDodecahedron()
    GlColor3f(1, 1, 1)
        GlutWireTeapot(0.7)
    GlutSwapBuffers()
})

lastX, lastY = 0
GlutMotionFunc({ x, y |
    dx, dy = lastX - x, lastY - y
    GlRotatef(dx, 0, 1, 0)
    GlRotatef(dy, 1, 0, 0)
    lastX, lastY = x, y
})

GlutIdleFunc(GlutPostRedisplay)
GlutMainLoop()
```
