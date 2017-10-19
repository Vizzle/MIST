//
//  VZFCustomNode.m
//  MIST
//
//  Created by Sleen on 2017/3/6.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "VZFCustomNode.h"
#import <VZFlexLayout/VZFNodeInternal.h>
#import <VZFlexLayout/VZFlexNode.h>


@implementation VZFCustomNode

+ (nonnull instancetype)newWithViewFactory:(nonnull ViewFactory)factory NodeSpecs:(const NodeSpecs &)specs Measure:(nullable CGSize (^)(CGSize constrainedSize))measure
{
    NSString *identifier = specs.identifier.empty() ? nil : [NSString stringWithUTF8String:specs.identifier.c_str()];
    VZFCustomNode *node = [super newWithView:{ factory, identifier } NodeSpecs:specs];
    node.flexNode.measure = measure;
    return node;
}

// 不应用 attributes，避免覆盖掉 custom view 的样式
- (void)applyAttributes
{
}

@end
