//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VZMistActionBlockTarget : NSObject

@property (nonatomic, strong) void(^block)();

+ (instancetype)targetWithBlock:(void(^)())block;

@end
