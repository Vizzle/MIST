//
//  VZTKeyValueListNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTKeyValueListNode.h"


@implementation VZTKeyValueListNode

- (instancetype)init
{
    if (self = [super init]) {
        _keyValueList = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}

@end
