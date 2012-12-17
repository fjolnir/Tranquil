def fib(n)
    if n < 2 then
        return n
    else
        return fib(n-1) + fib(n-2)
    end
end
#fib = lambda { |n|
#    if n < 2 then
#        return n
#    else
#        return fib[n-1] + fib[n-2]
#    end
#}
#p fib
p fib(35)

