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

- (instancetype)initWithOperator:(VZTTokenType)operator operand1:(VZTExpressionNode *)operand1 operand2:(VZTExpressionNode *)operand2
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
    if ('[' == _operator) {
        if (!value1) {
            return nil;
        } else if ([value1 isKindOfClass:[NSArray class]]) {
            if (![value2 isKindOfClass:[NSNumber class]]) {
                //NSLog(@"only numbers are allowed to access an array, but '%@' was provided", [value2 class]);
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
    if (VZTTokenTypeEqual == _operator) {
        return @(vzt_isEqual(value1, value2));
    } else if (VZTTokenTypeNotEqual == _operator) {
        return @(!vzt_isEqual(value1, value2));
    }

    // string operation
    if ('+' == _operator && ([value1 isKindOfClass:[NSString class]] || [value2 isKindOfClass:[NSString class]])) {
        return [vzt_stringValue(value1) stringByAppendingString:vzt_stringValue(value2)];
    }

    // logical operation
    else if (VZTTokenTypeAnd == _operator) {
        return @((BOOL)(vzt_boolValue(value1) && vzt_boolValue(value2)));
    } else if (VZTTokenTypeOr == _operator) {
        return @((BOOL)(vzt_boolValue(value1) || vzt_boolValue(value2)));
    }

    if ((value1 && ![value1 isKindOfClass:[NSNumber class]]) || (value2 && ![value2 isKindOfClass:[NSNumber class]])) {
        NSLog(@"invalid operands '%@' to binary expression ('%@' and '%@')", vzt_tokenName(_operator), NSStringFromClass([value1 class]), NSStringFromClass([value2 class]));
        return nil;
    }

    switch ((int)_operator) {
        case '+':
            return @([value1 doubleValue] + [value2 doubleValue]);
        case '-':
            return @([value1 doubleValue] - [value2 doubleValue]);
        case '*':
            return @([value1 doubleValue] * [value2 doubleValue]);
        case '/':
            return @([value1 doubleValue] / [value2 doubleValue]);
        case '%':
        {
            NSInteger v2 = [value2 integerValue];
            if (v2 == 0) {
                NSAssert(NO, @"should not mod with zero");
                return 0;
            }
            return @([value1 integerValue] % v2);
        }
        case '>':
            return @((BOOL)([value1 doubleValue] > [value2 doubleValue]));
        case '<':
            return @((BOOL)([value1 doubleValue] < [value2 doubleValue]));
        case VZTTokenTypeGreaterOrEqaul:
            return @((BOOL)([value1 doubleValue] >= [value2 doubleValue]));
        case VZTTokenTypeLessOrEqaul:
            return @((BOOL)([value1 doubleValue] <= [value2 doubleValue]));
        default:
            NSAssert(NO, @"unknown binary operator '%@'", vzt_tokenName(_operator));
            return nil;
    }
}

@end
