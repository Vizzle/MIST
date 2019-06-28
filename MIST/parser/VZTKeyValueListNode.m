//
//  Copyright © 2016年 Vizlab. All rights reserved.
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
