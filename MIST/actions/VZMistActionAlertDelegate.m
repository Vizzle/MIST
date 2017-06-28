//
//  VZMistActionAlertDelegate.m
//  Pods
//
//  Created by Sleen on 2017/6/27.
//
//

#import "VZMistActionAlertDelegate.h"

@implementation VZMistActionAlertDelegate
{
    void(^block)(UIAlertView *alertView, NSInteger buttonIndex);
}

+ (instancetype)delegateWithBlock:(void (^)(UIAlertView *, NSInteger))block {
    VZMistActionAlertDelegate *delegate = [VZMistActionAlertDelegate new];
    delegate->block = block;
    return delegate;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    block(alertView, buttonIndex);
}

@end
