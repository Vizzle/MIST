//
//  VZTArrayExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTArrayExpressionNode.h"
#import "VZTExpressionListNode.h"


@implementation VZTArrayExpressionNode

- (instancetype)initWithExpressionList:(VZTExpressionListNode *)expressionList
{
    if (self = [super init]) {
        _expressionList = expressionList;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    NSMutableArray *array = [NSMutableArray array];
    for (VZTExpressionNode *element in _expressionList.expressionList) {
        id obj = [element compute:context];
        if (obj) {
            [array addObject:obj];
        }
        else {
            NSLog(@"expression: array contains null value");
        }
    }
    return array;
}

@end
