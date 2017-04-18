//
//  VZTObjectExpressionNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionNode.h"

@class VZTKeyValueListNode;


@interface VZTObjectExpressionNode : VZTExpressionNode

@property (nonatomic, strong) VZTKeyValueListNode *keyValueList;

- (instancetype)initWithKeyValueList:(VZTKeyValueListNode *)keyValueList;

@end
