//
//  VZMistActionBlockTarget.m
//  Pods
//
//  Created by Sleen on 2017/6/27.
//
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
