//
//  VZTExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionNode.h"


@implementation VZTExpressionNode

- (nullable id)compute:(nonnull VZTExpressionContext *)context
{
    return nil;
}

- (nullable id)compute
{
    return [self compute:[VZTExpressionContext new]];
}

@end
