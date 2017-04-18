//
//  VZTIdentifierNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTIdentifierNode.h"


@implementation VZTIdentifierNode

- (instancetype)initWithIdentifier:(id)identifier
{
    if (self = [super init]) {
        _identifier = identifier;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    Class cls = NSClassFromString(_identifier);
    if (cls) {
        return cls;
    }

    NSInteger count;
    id value = [context valueForKey:_identifier count:&count];

    if (count == 0) {
        //        NSLog(@"can not find '%@' in data", _identifier);
    }

    return value;
}

@end
