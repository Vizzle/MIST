//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"
#import "VZTLexer.h"


@interface VZTUnaryExpressionNode : VZTExpressionNode

@property (nonatomic, assign) VZTTokenType operator;
@property (nonatomic, strong) VZTExpressionNode *operand;

- (instancetype)initWithOperator:(VZTTokenType) operator operand:(VZTExpressionNode *)operand;

@end
