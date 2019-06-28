//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTSyntaxNode.h"

@class VZTExpressionNode;


@interface VZTKeyValueListNode : VZTSyntaxNode

@property (nonatomic, strong) NSMapTable<VZTExpressionNode *, VZTExpressionNode *> *keyValueList;

@end
