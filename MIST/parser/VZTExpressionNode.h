//
//  VZTExpressionNode.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTSyntaxNode.h"
#import "VZTExpressionContext.h"


@interface VZTExpressionNode : VZTSyntaxNode

- (nullable id)compute:(nonnull VZTExpressionContext *)context;
- (nullable id)compute;

@end
