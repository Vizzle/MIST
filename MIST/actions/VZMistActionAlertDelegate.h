//
//  VZMistActionAlertDelegate.h
//  Pods
//
//  Created by Sleen on 2017/6/27.
//
//

#import <Foundation/Foundation.h>

@interface VZMistActionAlertDelegate : NSObject

+ (instancetype)delegateWithBlock:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))block;

@end
