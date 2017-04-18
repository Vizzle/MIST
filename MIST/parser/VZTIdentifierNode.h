//
//  VZTIdentifierNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTIdentifierNode : VZTExpressionNode

@property (nonatomic, strong) NSString *identifier;

- (instancetype)initWithIdentifier:(id)identifier;

@end
