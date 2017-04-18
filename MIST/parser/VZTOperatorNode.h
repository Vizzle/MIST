//
//  VZTOperatorNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTSyntaxNode.h"


@interface VZTOperatorNode : VZTSyntaxNode

@property (nonatomic, strong) NSString *operator;

- (instancetype)initWithOperator:(NSString *) operator;

@end
