//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistIndicatorTemplateController.h"


@implementation MistIndicatorTemplateController

- (void)load
{
    [self updateState:@{ @"loading" : @YES }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateState:@{ @"loading" : @NO }];
    });
}

@end
