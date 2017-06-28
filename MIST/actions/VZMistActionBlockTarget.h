//
//  VZMistActionBlockTarget.h
//  Pods
//
//  Created by Sleen on 2017/6/27.
//
//

#import <Foundation/Foundation.h>

@interface VZMistActionBlockTarget : NSObject

@property (nonatomic, strong) void(^block)();

+ (instancetype)targetWithBlock:(void(^)())block;

@end
