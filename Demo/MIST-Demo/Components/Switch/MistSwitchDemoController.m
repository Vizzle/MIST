//
//  Copyright © 2016年 Vizlab. All rights reserved.
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
