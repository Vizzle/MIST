//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"

@class VZTIdentifierNode;


@interface VZTFunctionExpressionNode : VZTExpressionNode

@property (nonatomic, strong) VZTExpressionNode *target;
@property (nonatomic, strong) VZTIdentifierNode *action;
@property (nonatomic, strong) NSArray<VZTExpressionNode *> *parameters;

- (instancetype)initWithTarget:(VZTExpressionNode *)target action:(VZTIdentifierNode *)action parameters:(NSArray<VZTExpressionNode *> *)parameters;

@end
