//
//  MistTextViewDemoController.m
//  MIST
//
//  Created by wuwen on 2017/3/2.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistTextViewDemoController.h"

@implementation MistTextViewDemoController

- (void)onEvent:(id)eventName body:(NSDictionary *)body {
    NSLog(@"EVENT NAME: %@\nBODY: %@", eventName, body);
}

@end
