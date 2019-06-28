//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"
#import "VZTLexer.h"


@interface VZTBinaryExpressionNode : VZTExpressionNode

@property (nonatomic, assign) VZTTokenType operator;
@property (nonatomic, strong) VZTExpressionNode *operand1;
@property (nonatomic, strong) VZTExpressionNode *operand2;

- (instancetype)initWithOperator:(VZTTokenType)operator operand1:(VZTExpressionNode *)operand1 operand2:(VZTExpressionNode *)operand2;

@end
