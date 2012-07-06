(class Foo is NSObject
    (+ (id)fib:(id)n is
       (2)
    )
)

(NSLog "hmm %@" (Foo fib:25))
        
