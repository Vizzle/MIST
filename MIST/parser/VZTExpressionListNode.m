//
//  VZTExpressionListNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionListNode.h"


@implementation VZTExpressionListNode

- (instancetype)init
{
    if (self = [super init]) {
        _expressionList = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
