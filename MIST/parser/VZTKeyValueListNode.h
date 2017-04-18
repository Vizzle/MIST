//
//  VZTKeyValueListNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTSyntaxNode.h"

@class VZTExpressionNode;


@interface VZTKeyValueListNode : VZTSyntaxNode

@property (nonatomic, strong) NSMapTable<VZTExpressionNode *, VZTExpressionNode *> *keyValueList;

@end
