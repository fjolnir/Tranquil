#import "TQBridgeSupport.h"
#import "../Runtime/TQNumber.h"
#import "../Runtime/TQRuntime.h"
#import <objc/runtime.h>
#import "bs.h"

static void _parserCallback(bs_parser_t *parser, const char *path, bs_element_type_t type,
                            void *value, void *context)
{
    TQBridgeSupport *bs = (id)context;
    //NSLog(@"Encountered %d in %s", type, path);
    switch(type) {
        case BS_ELEMENT_STRUCT:
        break;
        case BS_ELEMENT_CFTYPE:
        break;
        case BS_ELEMENT_OPAQUE:
        break;
        case BS_ELEMENT_CONSTANT:
        break;
        case BS_ELEMENT_STRING_CONSTANT: {
            bs_element_string_constant_t *str = (bs_element_string_constant_t*)value;
            NSLog(@"StrConst %s=>%s  ns? %d", str->name, str->value, str->nsstring);
        } break;
        case BS_ELEMENT_ENUM:
        break;
        case BS_ELEMENT_FUNCTION:
        break;
        case BS_ELEMENT_FUNCTION_ALIAS:
        break;
        case BS_ELEMENT_CLASS:
        break;
        case BS_ELEMENT_INFORMAL_PROTOCOL_METHOD:
        break;
        default:
            NSLog(@"Unknown BridgeSupport object");
    }
}
@implementation TQBridgeSupport

- (BOOL)loadFramework:(NSString *)aFrameworkPath
{
    bs_parser_t *parser = bs_parser_new();
    char bsPath[1024];
    const char *frameworkPath = [aFrameworkPath fileSystemRepresentation];
    bool found = bs_find_path(frameworkPath, bsPath, 1024);
    if(!found)
        return NO;
    char *error = nil;
    bool parsed = bs_parser_parse(parser, bsPath, frameworkPath, BS_PARSE_OPTIONS_LOAD_DYLIBS, 
                                  &_parserCallback, (void*)self, &error);
    if(!parsed) {
        if(error)
            NSLog(@"BridgeSupport error: %s", error);
        bs_parser_free(parser);
        return NO;
    }
    bs_parser_free(parser);
    return YES;
}
@end
