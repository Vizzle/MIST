//
//  VZTExpressionContext.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTExpressionContext.h"
#import "VZTUtils.h"


@interface VZTWeakWrapper : NSObject 
@property (nonatomic, weak) id object;
+ (instancetype)newWithObject:(id)object;
@end
@implementation VZTWeakWrapper
+ (instancetype)newWithObject:(id)object {
    VZTWeakWrapper *wrapper = [VZTWeakWrapper new];
    wrapper.object = object;
    return wrapper;
}
@end


@implementation VZTExpressionContext
{
    NSMutableDictionary<NSString *, NSMutableArray *> *_variablesTable;
}

- (instancetype)init
{
    if (self = [super init]) {
        _variablesTable = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    VZTExpressionContext *ctx = [VZTExpressionContext new];
    NSMutableDictionary *dict = [NSMutableDictionary new];
    for (NSString *key in _variablesTable.copy) {
        dict[key] = _variablesTable[key].mutableCopy;
    }
    ctx->_variablesTable = dict;
    return ctx;
}

- (id)pushVariableWithKey:(NSString *)key value:(id)value
{
    NSMutableArray *valueStack = _variablesTable[key];
    if (!valueStack) {
        valueStack = [NSMutableArray array];
        _variablesTable[key] = valueStack;
    }

    [valueStack addObject:value ?: [VZTNull null]];
    return valueStack;
}

- (id)pushWeakVariableWithKey:(NSString *)key value:(id)value
{
    return [self pushVariableWithKey:key value:[VZTWeakWrapper newWithObject:value]];
}

- (void)popVariableWithKey:(NSString *)key
{
    NSMutableArray *valueStack = _variablesTable[key];
    if (valueStack.count == 0) {
        NSAssert(NO, @"there is no variable named '%@' to pop", key);
    } else {
        [valueStack removeLastObject];
    }
}

- (void)pushVariables:(NSDictionary *)variables
{
	if (![variables isKindOfClass:[NSDictionary class]]) {
		return;
	}
    for (NSString *key in variables) {
        [self pushVariableWithKey:key value:variables[key]];
    }
}

- (void)popVariables:(NSDictionary *)variables
{
    for (NSString *key in variables) {
        [self popVariableWithKey:key];
    }
}

- (id)valueForKey:(NSString *)key
{
    return [self valueForKey:key count:NULL];
}

- (id)valueForKey:(NSString *)key count:(NSInteger *)count
{
    NSMutableArray *valueStack = _variablesTable[key];
    id value = nil;
    if (valueStack.count > 0) {
        value = valueStack.lastObject;
        if (value == [VZTNull null]) {
            value = nil;
        }
    }
    if (count) {
        *count = valueStack.count;
    }

    if ([value isKindOfClass:[VZTWeakWrapper class]]) {
        value = ((VZTWeakWrapper *)value).object;
    }
    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    NSMutableArray *valueStack = _variablesTable[key];
    if (valueStack.count == 0) {
        NSAssert(NO, @"there is no variable named '%@' to set", key);
    } else {
        valueStack[valueStack.count - 1] = value ?: [VZTNull null];
    }
}

- (void)clear
{
    [_variablesTable removeAllObjects];
}

@end
