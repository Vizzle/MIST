//
//  VZTOperatorNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTOperatorNode.h"


@implementation VZTOperatorNode

- (instancetype)initWithOperator:(NSString *) operator
{
    if (self = [super init]) {
        _operator = operator;
    }
    return self;
}

@end
