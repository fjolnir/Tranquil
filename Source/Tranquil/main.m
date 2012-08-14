#import "TQProgram.h"

void printHelpAndExit(int status)
{
    printf("Usage: tranquil [options] [program path]\n");
    printf("-h    Show this help message\n");
    printf("-d    Print debugging information (Including the llvm assembly output)\n");
    exit(status);
}

int main(int argc, char **argv)
{
    @autoreleasepool {
    BOOL showDebugOutput = NO;
    char *inputPath = NULL;

    char *arg;
    for(int i = 1; i < argc; ++i) {
        arg = argv[i];
        if(arg[0] == '-') {
            if(strcmp(arg, "-d") == 0) showDebugOutput = YES;
            else if(strcmp(arg, "-h") == 0) printHelpAndExit(0);
            else {
                fprintf(stderr, "Unknown argument %s\n", arg);
                printHelpAndExit(1);
            }
        } else
            inputPath = arg;
    }

    TQProgram *program = [TQProgram programWithName:@"Root"];
    program.shouldShowDebugInfo = showDebugOutput;
    NSString *script;
    if(inputPath)
        script = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:inputPath] encoding:NSUTF8StringEncoding error:nil];
    else {
        NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
        NSData *inputData = [NSData dataWithData:[input readDataToEndOfFile]];
        script = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] autorelease];
    }
    [program executeScript:script error:nil];
    }
    return 0;
}
