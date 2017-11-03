//
//  VZTLambdaExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTLambdaExpressionNode.h"


@implementation VZTLambdaExpressionNode

- (instancetype)initWithParameter:(NSString *)parameter expression:(VZTExpressionNode *)expression
{
    if (self = [super init]) {
        _parameter = parameter;
        _expression = expression;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    id block = ^id(id param) {
        [context pushVariableWithKey:_parameter value:param];
        id value = [_expression compute:context];
        [context popVariableWithKey:_parameter];
        return value;
    };

    return block;
}

@end
