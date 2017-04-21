//
//  MistMapDemoController.m
//  MIST
//
//  Created by wuwen on 2017/2/27.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistMapDemoController.h"


@implementation MistMapDemoController

- (void)onEventWithName:(NSString *)eventName body:(id)body
{
    NSLog(@"Map view event: { name: %@, \nbody - %@ }", eventName, body);
}

@end
