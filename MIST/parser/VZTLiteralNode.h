//
//  VZTLiteralNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTLiteralNode : VZTExpressionNode

@property (nonatomic, strong) id value;

- (instancetype)initWithValue:(id)value;

@end
