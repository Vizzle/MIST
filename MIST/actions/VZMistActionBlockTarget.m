//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZMistActionBlockTarget.h"

@implementation VZMistActionBlockTarget

+ (instancetype)targetWithBlock:(void (^)())block {
    VZMistActionBlockTarget *target = [VZMistActionBlockTarget new];
    target.block = block;
    return target;
}

- (void)invoke {
    self.block();
}

@end
