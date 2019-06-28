//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"


@interface VZTIdentifierNode : VZTExpressionNode

@property (nonatomic, strong) NSString *identifier;

- (instancetype)initWithIdentifier:(id)identifier;

@end
