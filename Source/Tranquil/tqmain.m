// this is the standard initializer for statically compiled tranquil programs.
#import <Tranquil/Runtime/TQRuntime.h>

extern id __tranquil_root();

int main(int argc, char **argv)
{
    @autoreleasepool {
        TQInitializeRuntime(argc, argv);
        __tranquil_root();
    }
    return 0;
}
