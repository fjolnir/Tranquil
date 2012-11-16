import "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.0.sdk/System/Library/Frameworks/UIKit.framework/Headers/UIApplication.h"

#Delegate {
    - application: application didFinishLaunchingWithOptions: launchOptions {
        #win = UIWindow new; setFrame: UIScreen mainScreen bounds;
                   setBackgroundColor: UIColor redColor;
                           addSubview: (UILabel new; setText: "Hello, World!";
                                                   setCenter: [100, 100];
                                                   sizeToFit;
                                                        self);
                    makeKeyAndVisible;
                                 self
    }
}
UIApplicationMain(0, nil, nil, @Delegate)
