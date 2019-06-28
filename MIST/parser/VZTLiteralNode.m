//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTLiteralNode.h"


@implementation VZTLiteralNode

- (instancetype)initWithValue:(id)value
{
    if (self = [super init]) {
        _value = value;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    return _value;
}

@end
