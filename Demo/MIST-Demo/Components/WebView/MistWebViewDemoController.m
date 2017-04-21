//
//  MistWebViewDemoController.m
//  MIST
//
//  Created by wuwen on 2017/2/28.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistWebViewDemoController.h"


@implementation MistWebViewDemoController


- (void)onStartLoading:(id)event body:(NSDictionary *)body
{
    NSLog(@"%@", [NSString stringWithFormat:@"%@\n%@", event, body]);
}

- (void)onFinishLoading:(id)event body:(NSDictionary *)body
{
    NSLog(@"%@", [NSString stringWithFormat:@"%@\n%@", event, body]);
}

- (void)onLoadingError:(id)event body:(NSDictionary *)body
{
    NSLog(@"%@", [NSString stringWithFormat:@"%@\n%@", event, body]);
}

@end
