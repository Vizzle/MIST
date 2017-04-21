//
//  MistSwitchDemoController.m
//  MIST
//
//  Created by wuwen on 2017/2/27.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistSwitchDemoController.h"


@implementation MistSwitchDemoController

- (id)initialState
{
    return @{ @"switchOn" : @YES };
}

- (void)switchChanged:(id)event body:(NSDictionary *)body
{
    [self updateState:@{ @"switchOn" : body[@"on"] }];
}

@end
