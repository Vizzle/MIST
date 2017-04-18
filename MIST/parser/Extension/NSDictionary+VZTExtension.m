//
//  NSDictionary+VZTExtension.m
//  O2OMist
//
//  Created by lingwan on 16/9/4.
//  Copyright © 2016年 Alipay. All rights reserved.
//

#import "NSDictionary+VZTExtension.h"


@implementation NSDictionary (VZTExtension)

- (NSDictionary *)vzt_set:(NSString *)key value:(id)value
{
    NSMutableDictionary *mutableDict = self.mutableCopy;
    mutableDict[key] = value;
    return mutableDict;
}

@end
