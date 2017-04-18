//
//  VZTLambdaExpressionNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTLambdaExpressionNode : VZTExpressionNode

@property (nonatomic, strong) NSString *parameter;
@property (nonatomic, strong) VZTExpressionNode *expression;

- (instancetype)initWithParameter:(NSString *)parameter expression:(VZTExpressionNode *)expression;

@end
