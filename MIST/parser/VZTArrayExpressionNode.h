//
//  VZTArrayExpressionNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionNode.h"

@class VZTExpressionListNode;


@interface VZTArrayExpressionNode : VZTExpressionNode

@property (nonatomic, strong) VZTExpressionListNode *expressionList;

- (instancetype)initWithExpressionList:(VZTExpressionListNode *)expressionList;

@end
