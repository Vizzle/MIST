//
//  VZTLiteralNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTLiteralNode.h"


@implementation VZTLiteralNode

- (instancetype)initWithValue:(id)value
{
    if (self = [super init]) {
        _value = value;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    return _value;
}

@end
