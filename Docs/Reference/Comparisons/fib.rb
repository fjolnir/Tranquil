def fib(n, a=0, b=1)
#    if n == 0 then
#        return a
#    else
#        return fib(n-1, b, a+b)
#    end
    if n < 2 then
        return n
    else
        return fib(n-1) + fib(n-2)
    end
end
p fib(35)

#fib = lambda { |n|
#    if n < 2 then
#        return n
#    else
#        return fib[n-1] + fib[n-2]
#    end
#}
#p fib[35]

