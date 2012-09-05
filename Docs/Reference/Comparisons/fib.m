#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) {
    __block double (^fib)(double n);
    fib = ^(double n) {
        return n <= 1 ? n : fib(n - 1.0) + fib(n - 2.0);
    };
    fib(35);
    return 0;
}