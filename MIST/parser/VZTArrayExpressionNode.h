//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTArrayExpressionNode : VZTExpressionNode

@property (nonatomic, strong) NSArray<VZTExpressionNode *> *expressionList;

- (instancetype)initWithExpressionList:(NSArray<VZTExpressionNode *> *)expressionList;

@end
