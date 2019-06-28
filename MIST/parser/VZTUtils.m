//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTUtils.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <objc/runtime.h>

#if TARGET_OS_IPHONE
#ifdef __LP64__

@interface VZTSystemVersion : NSObject
+ (CGFloat)systemVersion;
@end
@implementation VZTSystemVersion
static CGFloat vzt_systemVersion;
+ (void)load {
    vzt_systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
}
+ (CGFloat)systemVersion {
    return vzt_systemVersion;
}
@end

#endif
#endif

NSString *vzt_stringValue(id obj)
{
    if (!obj) {
        return @"";
    }
    if ([obj isKindOfClass:[NSNumber class]] && (strcmp([obj objCType], @encode(BOOL)) == 0 || [obj objCType][0] == 'c')) {
        return [obj boolValue] ? @"true" : @"false";
    }
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    return [obj description];
}

BOOL vzt_boolValue(id obj)
{
    return !obj ? NO : [obj isKindOfClass:[NSNumber class]] ? [obj boolValue] : !!obj;
}

BOOL vzt_isEqual(id a, id b)
{
    if (a && b) {
        return [a isEqual:b];
    } else if ((!a || [a isKindOfClass:[NSNumber class]]) && (!b || [b isKindOfClass:[NSNumber class]])) {
        return [a doubleValue] == [b doubleValue];
    }

    return NO;
}

// 解决使用 NSInvocation 调用 -[NSString floatValue] 返回值错误的问题
NSMethodSignature *_vzt_fixSignature(NSMethodSignature *signature)
{
#if TARGET_OS_IPHONE
#ifdef __LP64__
    typedef struct {
        double d;
    } vzt_double;
    typedef struct {
        float f;
    } vzt_float;

    if (VZTSystemVersion.systemVersion < 7.1) {
        BOOL isReturnDouble = (strcmp([signature methodReturnType], "d") == 0);
        BOOL isReturnFloat = (strcmp([signature methodReturnType], "f") == 0);

        if (isReturnDouble || isReturnFloat) {
            NSMutableString *types = [NSMutableString stringWithFormat:@"%s@:", isReturnDouble ? @encode(vzt_double) : @encode(vzt_float)];
            for (int i = 2; i < signature.numberOfArguments; i++) {
                const char *argType = [signature getArgumentTypeAtIndex:i];
                [types appendFormat:@"%s", argType];
            }
            signature = [NSMethodSignature signatureWithObjCTypes:[types UTF8String]];
        }
    }
#endif
#endif
    return signature;
}

id vzt_invokeMethod(id target, SEL selector, NSArray *parameters)
{
    Method method;
    if (class_isMetaClass(object_getClass(target))) {
        method = class_getClassMethod(target, selector);
    } else {
        method = class_getInstanceMethod([target class], selector);
    }

    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    signature = _vzt_fixSignature(signature);
    if (signature.numberOfArguments - 2 != parameters.count) {
        NSLog(@"method '%@' requires %lu arguments, but %lu provided", NSStringFromSelector(selector), (unsigned long)signature.numberOfArguments - 2, (unsigned long)parameters.count);
        return nil;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    [invocation setTarget:target];
    for (int i = 0; i < parameters.count; i++) {
        id value = parameters[i];
        if (value == [VZTNull null]) value = nil;
        const char *paramType = [signature getArgumentTypeAtIndex:i + 2];
        char prefix = paramType[0];
        if (prefix == 'r' || prefix == 'n' || prefix == 'N' || prefix == 'o' || prefix == 'O' || prefix == 'R' || prefix == 'V') {
            prefix = paramType[1];
        }

#define VZT_FORWARD_PARAM(TYPE_CHAR, TYPE, SELECTOR)      \
    case TYPE_CHAR: {                                     \
        TYPE SELECTOR = [value SELECTOR];                 \
        [invocation setArgument:&SELECTOR atIndex:i + 2]; \
        break;                                            \
    }

        switch (prefix) {
            VZT_FORWARD_PARAM('c', char, charValue);
            VZT_FORWARD_PARAM('i', int, intValue);
            VZT_FORWARD_PARAM('s', short, shortValue);
            VZT_FORWARD_PARAM('l', long, longValue);
            VZT_FORWARD_PARAM('q', long long, longLongValue);
            VZT_FORWARD_PARAM('C', unsigned char, unsignedCharValue);
            VZT_FORWARD_PARAM('I', unsigned int, unsignedIntValue);
            VZT_FORWARD_PARAM('S', unsigned short, unsignedShortValue);
            VZT_FORWARD_PARAM('L', unsigned long, unsignedLongValue);
            VZT_FORWARD_PARAM('Q', unsigned long long, unsignedLongLongValue);
            VZT_FORWARD_PARAM('f', float, floatValue);
            VZT_FORWARD_PARAM('d', double, doubleValue);
            VZT_FORWARD_PARAM('B', BOOL, boolValue);
            VZT_FORWARD_PARAM('*', const char *, UTF8String);
            case '@': // @        An object (whether statically typed or typed id)
            case '#': // #        A class object (Class)
                [invocation setArgument:&value atIndex:i + 2];
                break;
            case ':': // :        A method selector (SEL)
            {
                SEL sel = NSSelectorFromString(value);
                [invocation setArgument:&sel atIndex:i + 2];
                break;
            }
            case '{': // {name=type...}        A structure
                if ([value isKindOfClass:[NSValue class]]) {
                    if (strcmp(paramType, [value objCType]) == 0) {
#define VZT_FORWARD_NSVALUE_PARAM(type, selector) \
                        if (strncmp(#type, paramType + 1, sizeof(#type) - 1) == 0) { \
                            struct type v = [value selector]; \
                            [invocation setArgument:&v atIndex:i + 2]; \
                            break; \
                        }
#define VZT_FORWARD_NSVALUE_PARAM1(type) VZT_FORWARD_NSVALUE_PARAM(type, type##Value)
#if TARGET_OS_IPHONE
                        VZT_FORWARD_NSVALUE_PARAM1(CGPoint);
                        VZT_FORWARD_NSVALUE_PARAM1(CGRect);
                        VZT_FORWARD_NSVALUE_PARAM1(CGSize);
                        VZT_FORWARD_NSVALUE_PARAM1(CGAffineTransform);
                        VZT_FORWARD_NSVALUE_PARAM1(CATransform3D);
                        VZT_FORWARD_NSVALUE_PARAM1(UIEdgeInsets);
                        VZT_FORWARD_NSVALUE_PARAM1(CGVector);
                        VZT_FORWARD_NSVALUE_PARAM1(UIOffset);
#else
                        VZT_FORWARD_NSVALUE_PARAM(CGPoint, pointValue);
                        VZT_FORWARD_NSVALUE_PARAM(CGSize, sizeValue);
                        VZT_FORWARD_NSVALUE_PARAM(CGRect, rectValue);
                        VZT_FORWARD_NSVALUE_PARAM(NSEdgeInsets, edgeInsetsValue);
#endif
                        VZT_FORWARD_NSVALUE_PARAM(_NSRange, rangeValue);
                    }
                }
                break;
            case '[': // [array type]        An array
            case '(': // (name=type...)        A union
            case 'b': // bnum        A bit field of num bits
            case '^': // ^type        A pointer to type
            case '?': // ?        An unknown type (among other things, this code is used for function pointers)
            default:
                NSLog(@"argument type of method '%@' not supported", NSStringFromSelector(selector));
                break;
        }
    }
    [invocation invoke];

    const char *returnType = [signature methodReturnType];
    char prefix = returnType[0];
    if (prefix == 'r' || prefix == 'n' || prefix == 'N' || prefix == 'o' || prefix == 'O' || prefix == 'R' || prefix == 'V') {
        prefix = returnType[1];
    }
    if (prefix == 'v') {
        return nil;
    }

#define VZT_FORWARD_RETURN_VALUE(TYPE_CHAR, TYPE) \
    case TYPE_CHAR: {                             \
        TYPE returnValue;                         \
        [invocation getReturnValue:&returnValue]; \
        return @(returnValue);                    \
    }

    switch (prefix) {
        VZT_FORWARD_RETURN_VALUE('c', char);
        VZT_FORWARD_RETURN_VALUE('i', int);
        VZT_FORWARD_RETURN_VALUE('s', short);
        VZT_FORWARD_RETURN_VALUE('l', long);
        VZT_FORWARD_RETURN_VALUE('q', long long);
        VZT_FORWARD_RETURN_VALUE('C', unsigned char);
        VZT_FORWARD_RETURN_VALUE('I', unsigned int);
        VZT_FORWARD_RETURN_VALUE('S', unsigned short);
        VZT_FORWARD_RETURN_VALUE('L', unsigned long);
        VZT_FORWARD_RETURN_VALUE('Q', unsigned long long);
        VZT_FORWARD_RETURN_VALUE('f', float);
        VZT_FORWARD_RETURN_VALUE('d', double);
        VZT_FORWARD_RETURN_VALUE('B', BOOL);
        case '*': // *        A character string (char *)
        {
            char *returnValue;
            [invocation getReturnValue:&returnValue];
            return [NSString stringWithUTF8String:returnValue];
        }
        case '@': // @        An object (whether statically typed or typed id)
        case '#': // #        A class object (Class)
        {
            __unsafe_unretained id returnValue;
            [invocation getReturnValue:&returnValue];
            return returnValue;
        }
        case '^': // ^type        A pointer to type
        {
            void *returnValue;
            [invocation getReturnValue:&returnValue];
            return (__bridge id)returnValue;
            break;
        }
        case '{': // {name=type...}        A structure
        {
#define VZT_FORWARD_NSVALUE_RETURN_VALUE(type, selector) \
            if (strncmp(#type, returnType + 1, sizeof(#type) - 1) == 0) { \
                struct type r; \
                [invocation getReturnValue:&r]; \
                return [NSValue selector:r]; \
            }
#define VZT_FORWARD_NSVALUE_RETURN_VALUE1(type) VZT_FORWARD_NSVALUE_RETURN_VALUE(type, valueWith##type)
#if TARGET_OS_IPHONE
            VZT_FORWARD_NSVALUE_RETURN_VALUE1(CGPoint);
            VZT_FORWARD_NSVALUE_RETURN_VALUE1(CGRect);
            VZT_FORWARD_NSVALUE_RETURN_VALUE1(CGSize);
            VZT_FORWARD_NSVALUE_RETURN_VALUE1(CGAffineTransform);
            VZT_FORWARD_NSVALUE_RETURN_VALUE1(CATransform3D);
            VZT_FORWARD_NSVALUE_RETURN_VALUE1(UIEdgeInsets);
            VZT_FORWARD_NSVALUE_RETURN_VALUE1(CGVector);
            VZT_FORWARD_NSVALUE_RETURN_VALUE1(UIOffset);
#else
            VZT_FORWARD_NSVALUE_RETURN_VALUE(CGPoint, valueWithPoint);
            VZT_FORWARD_NSVALUE_RETURN_VALUE(CGSize, valueWithSize);
            VZT_FORWARD_NSVALUE_RETURN_VALUE(CGRect, valueWithRect);
            VZT_FORWARD_NSVALUE_RETURN_VALUE(NSEdgeInsets, valueWithEdgeInsets);
#endif
            VZT_FORWARD_NSVALUE_RETURN_VALUE(_NSRange, valueWithRange);
            break;
        }
        case ':': // :        A method selector (SEL)
        case '[': // [array type]        An array
        case '(': // (name=type...)        A union
        case 'b': // bnum        A bit field of num bits
        case '?': // ?        An unknown type (among other things, this code is used for function pointers)
        default:
            NSLog(@"return type of method '%@' not supported", NSStringFromSelector(selector));
            break;
    }
    return nil;
}


@implementation VZTNull

+ (instancetype)null
{
    static VZTNull *null;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        null = [[VZTNull alloc] init];
    });
    return null;
}

@end
