//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTLiteralNode : VZTExpressionNode

@property (nonatomic, strong) id value;

- (instancetype)initWithValue:(id)value;

@end
