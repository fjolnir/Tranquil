#import <Tranquil/CodeGen/TQProgram.h>

void printHelpAndExit(int status)
{
    fprintf(stderr, "tranquil - The Tranquil interpreter\n");
    fprintf(stderr, "Usage: tranquil [options] [program path] [program arguments]\n");
    fprintf(stderr, "-h        Show this help message\n");
    fprintf(stderr, "-d        Print debugging information (Including the llvm assembly output)\n");
    fprintf(stderr, "-aot      Enable ahead of time compilation (Outputs LLVM IR to stdout)\n");
    exit(status);
}

int main(int argc, char **argv)
{
    @autoreleasepool {
        BOOL showDebugOutput   = NO;
        BOOL compileToFile     = NO;
        const char *inputPath  = NULL;
        const char *outputPath = "tqapp.bc";

        char *arg;
        NSMutableArray *scriptArgs = [NSMutableArray array];
        for(int i = 1; i < argc; ++i) {
            arg = argv[i];

            // Args after the script path are considered to be args to the script itself
            if(inputPath)
                [scriptArgs addObject:[NSString stringWithUTF8String:arg]];
            else if(arg[0] == '-') {
                if(strcmp(arg, "-d") == 0) showDebugOutput = YES;
                else if(strcmp(arg, "-h") == 0) printHelpAndExit(0);
                else if(strcmp(arg, "-aot") == 0)
                    compileToFile = YES;
                else if(strcmp(arg, "-o") == 0)
                    outputPath = argv[++i];
                else {
                    fprintf(stderr, "Unknown argument %s\n", arg);
                    printHelpAndExit(1);
                }
            } else
                inputPath = arg;
        }

        TQProgram *program          = [TQProgram programWithName:@"Root"];
        program.arguments           = scriptArgs;
        program.useAOTCompilation   = compileToFile;
        program.outputPath          = [NSString stringWithUTF8String:outputPath];
        program.shouldShowDebugInfo = showDebugOutput;
        NSString *script;
        if(inputPath)
            [program executeScriptAtPath:[NSString stringWithUTF8String:inputPath] error:nil];
        else {
            NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
            NSData *inputData = [NSData dataWithData:[input readDataToEndOfFile]];
            script = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] autorelease];
            [program executeScript:script error:nil];
        }
    }
    return 0;
}
