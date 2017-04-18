//
//  VZTConditionalExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTConditionalExpressionNode.h"
#import "VZTUtils.h"


@implementation VZTConditionalExpressionNode

- (instancetype)initWithCondition:(VZTExpressionNode *)condition trueExpression:(VZTExpressionNode *)trueExpression falseExpression:(VZTExpressionNode *)falseExpression
{
    if (self = [super init]) {
        _condition = condition;
        _trueExpression = trueExpression;
        _falseExpression = falseExpression;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    id value = [_condition compute:context];
    id trueValue = _trueExpression ? [_trueExpression compute:context] : value;
    id falseValue = [_falseExpression compute:context];
    return vzt_boolValue(value) ? trueValue : falseValue;
}

@end
