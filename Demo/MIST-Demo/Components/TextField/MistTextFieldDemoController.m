//
//  MistTextFieldDemoController.m
//  MIST
//
//  Created by wuwen on 2017/3/2.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistTextFieldDemoController.h"

@implementation MistTextFieldDemoController

- (void)onEvent:(id)eventName body:(NSDictionary *)body {
    NSLog(@"EVENT NAME: %@\nBODY: %@", eventName, body);
}

@end
