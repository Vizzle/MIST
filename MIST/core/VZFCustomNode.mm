//
//  VZFCustomNode.m
//  MIST
//
//  Created by Sleen on 2017/3/6.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "VZFCustomNode.h"
#import "VZFNodeInternal.h"
#import "VZFlexNode.h"


@implementation VZFCustomNode

+ (nonnull instancetype)newWithViewFactory:(nonnull ViewFactory)factory NodeSpecs:(const NodeSpecs &)specs Measure:(nullable CGSize (^)(CGSize constrainedSize))measure
{
    VZFCustomNode *node = [super newWithView:{ factory, nil } NodeSpecs:specs];
    node.flexNode.measure = measure;
    return node;
}

// 不应用 attributes，避免覆盖掉 custom view 的样式
- (void)applyAttributes
{
}

@end
