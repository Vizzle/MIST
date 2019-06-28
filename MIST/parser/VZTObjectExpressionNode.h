//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"

@class VZTKeyValueListNode;


@interface VZTObjectExpressionNode : VZTExpressionNode

@property (nonatomic, strong) VZTKeyValueListNode *keyValueList;

- (instancetype)initWithKeyValueList:(VZTKeyValueListNode *)keyValueList;

@end
