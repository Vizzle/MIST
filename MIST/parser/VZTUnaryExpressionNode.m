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

- (instancetype)initWithOperator:(NSString *) operator operand:(VZTExpressionNode *)operand
{
    if (self = [super init]) {
        _operator = operator;
        _operand = operand;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    if ([@"!" isEqualToString:_operator]) {
        return vzt_boolValue([_operand compute:context]) ? @NO : @YES;
    } else if ([@"-" isEqualToString:_operator]) {
        id value = [_operand compute:context];
        if (value && ![value isKindOfClass:[NSNumber class]]) {
            NSLog(@"unary operator '-' only supports on number type");
            return nil;
        }
        return @(-[value doubleValue]);
    }

    NSAssert(NO, @"unknown unary operator '%@'", _operator);
    return nil;
}

@end
