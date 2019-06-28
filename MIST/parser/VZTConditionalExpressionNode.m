//
//  Copyright © 2016年 Vizlab. All rights reserved.
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
    return vzt_boolValue(value) ? (_trueExpression ? [_trueExpression compute:context] : value)
                                : [_falseExpression compute:context];

}

@end
