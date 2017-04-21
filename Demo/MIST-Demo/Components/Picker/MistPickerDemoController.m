//
//  MistPickerDemoController.m
//  MIST
//
//  Created by wuwen on 2017/3/2.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistPickerDemoController.h"

@implementation MistPickerDemoController

- (id)initialState {
    return @{@"items": @[@"Monday", @"Tuesday", @"Wensday", @"Thursday", @"Friday", @"Saturday", @"Sunday"],
             @"selectedIndex": @4};
}

- (void)onPickerChanged:(id)eventName body:(NSDictionary *)body {
    [self updateState:@{@"selectedIndex": body[@"selectedIndex"]}];
}

@end
