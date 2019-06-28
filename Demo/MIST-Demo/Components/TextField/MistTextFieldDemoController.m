//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistTextFieldDemoController.h"

@implementation MistTextFieldDemoController

- (void)onEvent:(id)eventName body:(NSDictionary *)body {
    NSLog(@"EVENT NAME: %@\nBODY: %@", eventName, body);
}

@end
