//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistMapDemoController.h"


@implementation MistMapDemoController

- (void)onEventWithName:(NSString *)eventName body:(id)body
{
    NSLog(@"Map view event: { name: %@, \nbody - %@ }", eventName, body);
}

@end
