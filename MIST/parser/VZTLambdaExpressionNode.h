//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTLambdaExpressionNode : VZTExpressionNode

@property (nonatomic, strong) NSString *parameter;
@property (nonatomic, strong) VZTExpressionNode *expression;

- (instancetype)initWithParameter:(NSString *)parameter expression:(VZTExpressionNode *)expression;

@end
