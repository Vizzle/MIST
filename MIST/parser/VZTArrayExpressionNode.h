//
//  VZTArrayExpressionNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTArrayExpressionNode : VZTExpressionNode

@property (nonatomic, strong) NSArray<VZTExpressionNode *> *expressionList;

- (instancetype)initWithExpressionList:(NSArray<VZTExpressionNode *> *)expressionList;

@end
