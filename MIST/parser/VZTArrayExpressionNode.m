//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZTArrayExpressionNode.h"


@implementation VZTArrayExpressionNode

- (instancetype)initWithExpressionList:(NSArray<VZTExpressionNode *> *)expressionList
{
    if (self = [super init]) {
        _expressionList = expressionList;
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    NSMutableArray *array = [NSMutableArray array];
    for (VZTExpressionNode *element in _expressionList) {
        id obj = [element compute:context];
        if (obj) {
            [array addObject:obj];
        }
        else {
            NSLog(@"expression: array contains null value");
        }
    }
    return array;
}

@end
