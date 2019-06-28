//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTConditionalExpressionNode : VZTExpressionNode

@property (nonatomic, strong) VZTExpressionNode *condition;
@property (nonatomic, strong) VZTExpressionNode *trueExpression;
@property (nonatomic, strong) VZTExpressionNode *falseExpression;

- (instancetype)initWithCondition:(VZTExpressionNode *)condition trueExpression:(VZTExpressionNode *)trueExpression falseExpression:(VZTExpressionNode *)falseExpression;

@end
