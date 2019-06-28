//
//  Copyright © 2016年 Vizlab. All rights reserved.
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
