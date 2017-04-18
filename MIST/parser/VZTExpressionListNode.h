//
//  VZTExpressionListNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTSyntaxNode.h"

@class VZTExpressionNode;


@interface VZTExpressionListNode : VZTSyntaxNode

@property (nonatomic, strong) NSMutableArray<VZTExpressionNode *> *expressionList;

@end
