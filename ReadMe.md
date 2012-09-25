# Tranquil

Tranquil is a programming language built on top of LLVM & the Objective-C Runtime.

It aims to provide a more expressive & easy to use way to write Mac (and soon, iOS) Apps.

It's features include:

* Compatibility with C/ObjC headers, meaning that there is no need to create special bindings for C APIs.
* Automatic memory management.
* Dynamic Typing.
* Language level concurrency support.
* String interpolation.
* Multiple assignment.
* Message cascading.
* Good performance, even at this extremely early stage.
* And more..

However, Tranquil is still extremely experimental and you shouldn't use it for anything other than fun for now. But to me at least, it is a lot of fun to play with.

## How to build and run

The following will install Tranquil into /usr/local/tranquil (Along with a few dependencies).

    > curl -fsSkL https://raw.github.com/fjolnir/Tranquil/master/Tools/install.sh | /bin/zsh
    > /usr/local/tranquil/bin/tqrepl

**Note:** OS X 10.8 is required. (10.7 & iOS ≥ 5 will be supported later)

## Learning the language

To learn more about Tranquil you should read the [specification](https://github.com/fjolnir/Tranquil/blob/master/Docs/Tranquil%20Spec.md) and check out the [tests](https://github.com/fjolnir/Tranquil/blob/master/Tests).

But here're a couple of examples:

### Array iteration

```
alternatives = ["Objective-C", "Ruby", "Nu", "Perl", "Python"]
alternatives each: `alternative | "Tranquil is nicer than #{alternative}" print`
"Or so I hope at least." print
```

### Reduction

```
sum = (0 to: 1000000) reduce: `obj, accum=0 | obj+accum`
```

### Do two things at the same time

```
a = async foo()
b = bar()
whenFinished {
    "a is #{a} and b is: #{b}" print
}
```

### Message chaining (Without having to return self from every method you write)

```
var = Character new; setName: "Deckard"; setOccupation: "Blade Runner"; self
```

### Multiple assignment

```
a, b = b, a  \ Swap b&a
```

### Calculate fibonacci numbers (In a not-so-performant manner)

```
fib = `n | n > 1 ? fib(n-1) + fib(n-2) ! n`
fib(10) print
```

### Make a database query (Using [DatabaseKit](http://github.com/fjolnir/DatabaseKit))

    import "DatabaseKit"
    db = DB withURL: "sqlite://data/database.sqlite"
    query = db[@aTable] select: @field; where: { @anotherField => aValue }
    val   = query[@field]
    
    \ We can write that more concisely as:
    val   = table[{ @anotherField => aValue }][@field]
    
### Create a Web Server (Using [WebAppKit](http://github.com/fjolnir/WebAppKit))

    import "WebAppKit"
    WAApplication applicationOnPort: 8080;
                          handleGET: "/"
                               with: `request, response | "Hello world"`;
                      waitAndListen
    
### Evaluate a regular expression

```
if /foo[a-z]+/i matches: "Foobar"
    "Foobar starts with foo." print
```

### Using the OpenGL & GLUT APIs

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

### Talking to Cocoa

```
import "AppKit"

nsapp = NSApplication sharedApplication

\ Create the menubar
quitMenuItem = NSMenuItem new; setTitle: "Quit #{NSProcessInfo processInfo processName}";
                              setAction: @terminate:;
                       setKeyEquivalent: @q;
                                   self
appMenu     = NSMenu new; addItem: quitMenuItem;   self
appMenuItem = NSMenuItem new; setSubmenu: appMenu; self
menuBar     = NSMenu new; addItem: appMenuItem;    self

nsapp setMainMenu: menuBar

\ Create a little view
#TestView < NSView {
    - init {
        #gradient = NSGradient alloc initWithStartingColor: NSColor redColor
                                               endingColor: NSColor yellowColor
        ^self
    }
    - drawRect: dirtyRect {
        #gradient drawInRect: dirtyRect angle: 45
    }
}
	
\ Create a window
win = NSWindow alloc initWithContentRect: [[0, 0], [300, 200]]
                               styleMask: (NSTitledWindowMask bitOr: NSResizableWindowMask)
                                 backing: NSBackingStoreBuffered
                                   defer: no;
                                setTitle: "Tranquil!";
                          setContentView: TestView new;
                                    self

\ Start the app
win makeKeyAndOrderFront: nil
nsapp setActivationPolicy: NSApplicationActivationPolicyRegular
nsapp activateIgnoringOtherApps: yes
nsapp run
```
