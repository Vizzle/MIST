//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTExpressionNode.h"


@implementation VZTExpressionNode

- (nullable id)compute:(nonnull VZTExpressionContext *)context
{
    return nil;
}

- (nullable id)compute
{
    return [self compute:[VZTExpressionContext new]];
}

@end
