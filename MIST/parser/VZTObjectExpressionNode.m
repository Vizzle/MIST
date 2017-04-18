//
//  VZTObjectExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTObjectExpressionNode.h"
#import "VZTKeyValueListNode.h"


@implementation VZTObjectExpressionNode

- (instancetype)initWithKeyValueList:(VZTKeyValueListNode *)keyValueList
{
    if (self = [super init]) {
        _keyValueList = keyValueList;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (VZTExpressionNode *key in _keyValueList.keyValueList.keyEnumerator) {
        id keyObj = [key compute:context];
        if (keyObj) {
            dictionary[keyObj] = [[_keyValueList.keyValueList objectForKey:key] compute:context];
        }
        else {
            NSLog(@"expression: dictionary contains null key");
        }
    }
    return dictionary;
}

@end
