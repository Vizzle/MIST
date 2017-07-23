//
//  VZTUnaryExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTUnaryExpressionNode.h"
#import "VZTUtils.h"


@implementation VZTUnaryExpressionNode

- (instancetype)initWithOperator:(VZTTokenType) operator operand:(VZTExpressionNode *)operand
{
    if (self = [super init]) {
        _operator = operator;
        _operand = operand;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    switch ((int)_operator) {
        case '!':
            return vzt_boolValue([_operand compute:context]) ? @NO : @YES;
        case '-':
        {
            id value = [_operand compute:context];
            if (value && ![value isKindOfClass:[NSNumber class]]) {
                NSLog(@"unary operator '-' only supports on number type");
                return nil;
            }
            return @(-[value doubleValue]);
        }
        default:
            NSAssert(NO, @"unknown unary operator '%@'", vzt_tokenName(_operator));
            return nil;
    }
}

@end
