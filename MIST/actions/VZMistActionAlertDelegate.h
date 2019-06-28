//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VZMistActionAlertDelegate : NSObject

+ (instancetype)delegateWithBlock:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))block;

@end
