//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTSyntaxNode.h"
#import "VZTExpressionContext.h"


@interface VZTExpressionNode : VZTSyntaxNode

- (nullable id)compute:(nonnull VZTExpressionContext *)context;
- (nullable id)compute;

@end
