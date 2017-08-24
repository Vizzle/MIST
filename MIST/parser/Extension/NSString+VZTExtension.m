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
- (NSString *)vzt_sub:(NSInteger)start string:(NSUInteger)length
{
    return [self vzt_substring:start :length];
}

- (NSString *)vzt_substring:(NSInteger)length
{
    if (length >= 0) {
        return [self substringWithRange:NSMakeRange(0, length)];
    }
    else {
        return [self substringWithRange:NSMakeRange(self.length + length, -length)];
    }
}

- (NSString *)vzt_substring:(NSInteger)start :(NSUInteger)length
{
    if (start < 0) {
        start += self.length;
    }
    return [self substringWithRange:NSMakeRange(start, length)];
}

// deprecated: use `replace` instead
- (NSString *)vzt_replace:(NSString *)replace with:(NSString *)with
{
    return [self vzt_replace:replace :with];
}

- (NSString *)vzt_replace:(NSString *)replace :(NSString *)with
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
