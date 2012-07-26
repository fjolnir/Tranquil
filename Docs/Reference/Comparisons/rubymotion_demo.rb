class HelloView < UIView
    def drawRect(rect)
        if @moved
            bgColor = begin
                red, green, blue = rand(100), rand(100), rand(100)
                UIColor colorWithRed(red/100.0, green:green/100.0, blue:blue/100.0, alpha: 1.0)
            end
            text = "ZOMG!"
        else
            bgColor = UIColor.blackColor
            text = @touches ? "Touched #{@touches} times!" : "Hello RubyMotion!"
        end
        bgColor.set
        UIBezierPath.bezierPathWithRect(rect).fill
        UIColor.whiteColor.set
        text.drawAtPoint(CGPointMake(10, 20), withFont:UIFont.systemFontOfSize(24))
    end
end
