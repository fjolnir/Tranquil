// this is the standard initializer for statically compiled tranquil programs.
#import <Tranquil/Runtime/TQRuntime.h>
#import <Tranquil/Runtime/TQNumber.h>

extern id __tranquil_root();

int main(int argc, char **argv)
{
    @autoreleasepool {
        TQInitializeRuntime(argc, argv);
        id result = __tranquil_root();
        if([result isKindOfClass:[TQNumber class]])
            return [result intValue];
    }
    return 0;
}
