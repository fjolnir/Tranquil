@interface HelloView : UIView {
    BOOL _hasMoved;
    NSUInteger _touchCount;
}
@end

@implementation HelloView
- (void)drawRect:(NSRect)dirtyRect
{
    UIColor *bgColor;
    NSString *text;
    if(_hasMoved) {
        bgColor = [UIColor colorWithRed: [@0.0 randUpTo: @1.0]
                                  green: [@0.0 randUpTo: @1.0]
                                   blue: [@0.0 randUpTo: @1.0]];
        text = @"ZOMG!";
    } else {
        bgColor = [UIColor blackColor];
        if(_touchCount > 0)
            text = [NSString stringWithFormat:@"Touched %ld times!", _touchCount];
        else
            text = @"Hello world!";
    }
    [bgColor set];
    [[UIBezierPath bezierPathWithRect: dirtyRect] fill];

    [[UIColor whiteColor] set];
    [text drawAtPoint:(CGPoint) {10, 20} withFont:[UIFont systemFontOfSize: 24]];
}
@end

