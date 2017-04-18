//
//  VZDataStructure.h
//  MIST
//
//  Created by moxin on 2016/12/6.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

#define __IsStringValid(_str) (_str && [_str isKindOfClass:[NSString class]] && ([_str length] > 0))
#define __IsArrayValid(_array) (_array && [_array isKindOfClass:[NSArray class]] && ([_array count] > 0))
#define __IsDictionaryValid(__dic) (__dic && [__dic isKindOfClass:[NSDictionary class]] && ([__dic count] > 0))

static inline NSString *__vzString(id value, NSString *defaultString)
{
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *num = (NSNumber *)value;
        return [num stringValue];
    }

    return defaultString;
}

static inline NSString *__vzStringDefault(id value)
{
    return __vzString(value, nil);
}

static inline NSString *__vzEncodedString(id value)
{
    NSString *str = __vzString(value, nil);

    NSString *encodedString = (NSString *)
        CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (CFStringRef)str,
                                                                  NULL,
                                                                  (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                  kCFStringEncodingUTF8));

    return encodedString;
}

static inline NSString *__vzDecodeString(id value)
{
    NSString *decodedString = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)value, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));

    return decodedString;
}


static inline int __vzInt(id obj, int defaultValue)
{
    if (!obj) {
        return defaultValue;
    }

    if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSString class]])
        return [obj intValue];

    return defaultValue;
}

static inline double __vzDouble(id obj, double defaultValue)
{
    if (!obj) {
        return defaultValue;
    }

    if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSString class]])
        return [obj doubleValue];

    return defaultValue;
}

static inline float __vzFloat(id obj, float defaultValue)
{
    if (!obj) {
        return defaultValue;
    }

    if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSString class]])
        return [obj floatValue];


    return defaultValue;
}

static inline BOOL __vzBool(id obj, BOOL defaultValue)
{
    if (!obj) {
        return defaultValue;
    }

    if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSString class]]) {
        return [obj boolValue];
    }
    return defaultValue;
}


static inline NSArray *__vzArray(id obj, NSArray *defaultValue)
{
    if (!obj) {
        return defaultValue;
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        return obj;
    }
    return defaultValue;
}


static inline NSDictionary *__vzDictionary(id obj, NSDictionary *defaultValue)
{
    if (!obj) {
        return defaultValue;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return obj;
    }
    return defaultValue;
}
