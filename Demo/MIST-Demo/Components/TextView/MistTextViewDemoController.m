//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistTextViewDemoController.h"

@implementation MistTextViewDemoController

- (void)onEvent:(id)eventName body:(NSDictionary *)body {
    NSLog(@"EVENT NAME: %@\nBODY: %@", eventName, body);
}

@end
