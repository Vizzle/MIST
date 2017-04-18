//
//  VZTUnaryExpressionNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTUnaryExpressionNode : VZTExpressionNode

@property (nonatomic, strong) NSString *operator;
@property (nonatomic, strong) VZTExpressionNode *operand;

- (instancetype)initWithOperator:(NSString *) operator operand:(VZTExpressionNode *)operand;

@end
