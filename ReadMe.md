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
    alternatives = ["Objective-C", "Ruby", "Nu", "Perl", "Python"]
    alternatives each: `alternative | "Tranquil is nicer than #{alternative}" print`
    "Or so I hope at least." print

### Reduction

    sum = (0 to: 1000000) reduce: `obj, accum=0 | obj+accum`

### Multiple assignment

    a, b = b, a  \ Swap b&a

### Calculate fibonacci numbers (In a not-so-performant manner)

    fib = `n | n > 1 ? fib(n-1) + fib(n-2) : n`
    fib(10) print

### Evaluate a regular expression

    if /foo[a-z]+/i matches: "Foobar"
    	"Foobar starts with foo." print

### Using the OpenGL & GLUT APIs

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

### Talking to Cocoa

    nsapp = NSApplication sharedApplication

    \ Create the menubar
    menuBar     = NSMenu new
    appMenuItem = NSMenuItem new
    menuBar addItem: appMenuItem
    nsapp setMainMenu: menuBar
    
    \ Add the Application menu & the quit item
    appMenu      = NSMenu new
    quitMenuItem = NSMenuItem alloc initWithTitle: "Quit #{NSProcessInfo processInfo processName}"
                                           action: "terminate:"
                                    keyEquivalent: "q"
    appMenu addItem: quitMenuItem
    appMenuItem setSubmenu: appMenu
    
    \ Create a window
    win = NSWindow alloc initWithContentRect: [[400, 400], [300, 200]]
                                   styleMask: NSTitledWindowMask
                                     backing: NSBackingStoreBuffered
                                       defer: no;
                                    setTitle: "Tranquil!";
                                        self
    win makeKeyAndOrderFront: nil
    
    \ Create a little view
	#TestView < NSView {
	    - init {
	        super init
	        self#gradient = NSGradient alloc initWithStartingColor: NSColor redColor
	                                                  endingColor: NSColor yellowColor
	        ^self
	    }
	    - drawRect: dirtyRect {
	        NSColor cyanColor set
	        self#gradient drawInRect: dirtyRect angle: 45
	    }
	}

    
    view = TestView new; setFrame: (win contentView bounds); self
    win#contentView = view
    
    \ Start the app
    nsapp setActivationPolicy: NSApplicationActivationPolicyRegular
    nsapp activateIgnoringOtherApps: yes
    nsapp run
