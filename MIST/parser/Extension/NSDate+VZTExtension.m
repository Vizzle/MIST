//
//  NSDate+VZTExtension.m
//  O2O
//
//  Created by Sleen on 16/4/21.
//  Copyright © 2016年 Alipay. All rights reserved.
//

#import "NSDate+VZTExtension.h"


@implementation NSDate (VZTExtension)

- (NSString *)vzt_format:(NSString *)format
{
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = format;
    return [f stringFromDate:self];
}

+ (NSString *)vzt_stringForTimeInterval:(NSTimeInterval)time
{
    int64_t t = time;
    return [NSString stringWithFormat:@"%02lld:%02lld:%02lld", t / 3600, (t / 60) % 60, t % 60];
}

@end
