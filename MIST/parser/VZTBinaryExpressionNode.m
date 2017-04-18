//
//  VZTBinaryExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTBinaryExpressionNode.h"
#import "VZTUtils.h"


@implementation VZTBinaryExpressionNode

- (instancetype)initWithOperator:(NSString *) operator operand1:(VZTExpressionNode *)operand1 operand2:(VZTExpressionNode *)operand2
{
    if (self = [super init]) {
        _operator = operator;
        _operand1 = operand1;
        _operand2 = operand2;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    id value1 = [_operand1 compute:context];
    id value2 = [_operand2 compute:context];

    // subscript operation
    if ([@"[" isEqualToString:_operator]) {
        if (!value1) {
            return nil;
        } else if ([value1 isKindOfClass:[NSArray class]]) {
            if (![value2 isKindOfClass:[NSNumber class]]) {
                NSLog(@"only numbers are allowed to access an array, but '%@' was provided", [value2 class]);
                return nil;
            }
            NSUInteger index = [value2 unsignedIntegerValue];
            return index < [value1 count] ? [value1 objectAtIndex:index] : nil;
        } else if ([value1 isKindOfClass:[NSDictionary class]]) {
            return [value1 objectForKey:value2];
        } else if ([value1 isKindOfClass:[NSString class]]) {
            return [value1 substringWithRange:NSMakeRange([value2 unsignedIntegerValue], 1)];
        } else {
            NSLog(@"[] operator can not be used on instance of '%@'", [value1 class]);
            return nil;
        }
    }

    // comparision operation
    if ([@"==" isEqualToString:_operator]) {
        return @(vzt_isEqual(value1, value2));
    } else if ([@"!=" isEqualToString:_operator]) {
        return @(!vzt_isEqual(value1, value2));
    }

    // string operation
    if ([@"+" isEqualToString:_operator] && ([value1 isKindOfClass:[NSString class]] || [value2 isKindOfClass:[NSString class]])) {
        return [vzt_stringValue(value1) stringByAppendingString:vzt_stringValue(value2)];
    }

    // logical operation
    else if ([@"&&" isEqualToString:_operator]) {
        return @((BOOL)(vzt_boolValue(value1) && vzt_boolValue(value2)));
    } else if ([@"||" isEqualToString:_operator]) {
        return @((BOOL)(vzt_boolValue(value1) || vzt_boolValue(value2)));
    }

    if ((value1 && ![value1 isKindOfClass:[NSNumber class]]) || (value2 && ![value2 isKindOfClass:[NSNumber class]])) {
        NSLog(@"invalid operands '%@' to binary expression ('%@' and '%@')", _operator, NSStringFromClass([value1 class]), NSStringFromClass([value2 class]));
        return nil;
    }

    // arithmetical operation
    if ([@"+" isEqualToString:_operator]) {
        return @([value1 doubleValue] + [value2 doubleValue]);
    } else if ([@"-" isEqualToString:_operator]) {
        return @([value1 doubleValue] - [value2 doubleValue]);
    } else if ([@"*" isEqualToString:_operator]) {
        return @([value1 doubleValue] * [value2 doubleValue]);
    } else if ([@"/" isEqualToString:_operator]) {
        return @([value1 doubleValue] / [value2 doubleValue]);
    } else if ([@"%" isEqualToString:_operator]) {
        NSInteger v2 = [value2 integerValue];
        if (v2 == 0) {
            NSAssert(NO, @"should not mod with zero");
            return 0;
        }
        return @([value1 integerValue] % v2);
    }

    // relational operation
    else if ([@">" isEqualToString:_operator]) {
        return @((BOOL)([value1 doubleValue] > [value2 doubleValue]));
    } else if ([@"<" isEqualToString:_operator]) {
        return @((BOOL)([value1 doubleValue] < [value2 doubleValue]));
    } else if ([@">=" isEqualToString:_operator]) {
        return @((BOOL)([value1 doubleValue] >= [value2 doubleValue]));
    } else if ([@"<=" isEqualToString:_operator]) {
        return @((BOOL)([value1 doubleValue] <= [value2 doubleValue]));
    }

    NSAssert(NO, @"unknown binary operator '%@'", _operator);
    return nil;
}

@end
