//
//  NSString+VZTExtension.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "NSString+VZTExtension.h"


@implementation NSString (VZTExtension)

- (NSString *)vzt_trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// deprecated: use `substring` instead
- (NSString *)vzt_sub:(NSUInteger)start string:(NSUInteger)length
{
    return [self substringWithRange:NSMakeRange(start, length)];
}

- (NSString *)vzt_substring:(NSUInteger)start:(NSUInteger)length
{
    return [self substringWithRange:NSMakeRange(start, length)];
}

// deprecated: use `replace` instead
- (NSString *)vzt_replace:(NSString *)replace with:(NSString *)with
{
    return [self stringByReplacingOccurrencesOfString:replace withString:with];
}

- (NSString *)vzt_replace:(NSString *)replace:(NSString *)with
{
    return [self stringByReplacingOccurrencesOfString:replace withString:with];
}

- (NSInteger)vzt_find:(NSString *)str
{
    NSUInteger index = [self rangeOfString:str].location;
    return index == NSNotFound ? -1 : index;
}

- (NSArray *)vzt_split:(NSString *)separator
{
    return [self componentsSeparatedByString:separator];
}

@end
