# Tranquil

Tranquil is a programming language built on top of LLVM & the Objective-C Runtime.

It aims to provide a more expressive & easy to use way to write Mac (and soon, iOS) Apps.

Tranquil is still extremely experimental and you shouldn't use it for anything other than fun for now. But to me at least, it is a lot of fun to play with.

## How to build and run

The following will install Tranquil into ~/Tranquil (And two dependencies into /usr/local).

    > curl -fsSkL https://raw.github.com/fjolnir/Tranquil/master/Tools/install.sh | /bin/zsh
    > ~/Tranquil/build/tranquil -h

## Learning the language

To learn more about Tranquil you should read the [specification](https://github.com/fjolnir/Tranquil/blob/master/Docs/Tranquil%20Spec.md) and check out the [tests](https://github.com/fjolnir/Tranquil/blob/master/Tests).

But here're a couple of examples:

### Array iteration

```st
    alternatives = ["Objective-C", "Ruby", "Nu", "Perl", "Python"]
    alternatives each: `alternative | "Tranquil is nicer than #{alternative}" print`
    "Or so I hope at least." print
```

### Reduction

```st
    sum = (0 to: 1000000) reduce: `obj, accum=0 | obj+accum`
```

### Message chaining (Without having to return self from every method you write)

```st
    var = Character new; setName: "Deckard"; setOccupation: "Blade Runner"; self
```

### Multiple assignment

```st
    a, b = b, a  \ Swap b&a
```

### Calculate fibonacci numbers (In a not-so-performant manner)

```st
    fib = `n | n > 1 ? fib(n-1) + fib(n-2) : n`
    fib(10) print
```

### Evaluate a regular expression

```st
    if /foo[a-z]+/i matches: "Foobar"
        "Foobar starts with foo." print
```

### Using the OpenGL & GLUT APIs

```st
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

```st
	nsapp = NSApplication sharedApplication
	
	\ Create the menubar
	quitMenuItem = NSMenuItem new; setTitle: "Quit #{NSProcessInfo processInfo processName}";
	                              setAction: "terminate:";
	                       setKeyEquivalent: "q";
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