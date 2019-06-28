//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistSegmentedControlDemoController.h"
#import <UIKit/UIKit.h>


@implementation MistSegmentedControlDemoController

- (id)initialState
{
    return @{ @"items" : @[ @"one", @"two", @"three" ],
              @"selectedSegmentedIndex" : @(UISegmentedControlNoSegment) };
}

- (void)onChanged:(id)eventName body:(NSDictionary *)body
{
    [self updateState:@{ @"selectedSegmentedIndex" : body[@"selectedSegmentedIndex"] }];
}

@end
