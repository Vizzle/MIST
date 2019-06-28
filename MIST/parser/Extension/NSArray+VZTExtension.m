//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "NSArray+VZTExtension.h"


@implementation NSArray (VZTExtension)

// [11, 12, 13, 14].filter(n -> n % 2 == 0)      =>      [12, 14]
- (NSArray *)vzt_filter:(nonnull id (^)(id))block
{
    NSMutableArray *array = [NSMutableArray array];
    for (id obj in self) {
        if ([block(obj) boolValue]) {
            [array addObject:obj];
        }
    }
    return array;
}

// [1, 2, 3].select(n -> n * 2)      =>      [2, 4, 6]
- (NSArray *)vzt_select:(nonnull id (^)(id))block
{
    NSMutableArray *array = [NSMutableArray array];
    for (id obj in self) {
        id r = block(obj);
        if (r) [array addObject:r];
    }
    return array;
}

// [11, 12, 13, 14].all(n -> n % 2 == 0)      =>      false
- (BOOL)vzt_all:(nonnull id (^)(id))block
{
    for (id obj in self) {
        if (![block(obj) boolValue]) {
            return NO;
        }
    }
    return YES;
}

// [11, 12, 13, 14].any(n -> n % 2 == 0)      =>      true
- (BOOL)vzt_any:(nonnull id (^)(id))block
{
    for (id obj in self) {
        if ([block(obj) boolValue]) {
            return YES;
        }
    }
    return NO;
}

// ['a', 'b', 'c'].first()      =>      'a'
- (id)vzt_first
{
    return self.firstObject;
}

// [11, 12, 13, 14].first(n -> n % 2 == 0)       =>      12
- (id)vzt_first:(nonnull id (^)(id))block
{
    for (NSInteger i = 0; i < self.count; i++) {
        if ([block(self[i]) boolValue]) {
            return self[i];
        }
    }
    return nil;
}

// [11, 12, 13, 14].firstIndex(n -> n % 2 == 0)       =>      1
- (NSInteger)vzt_firstIndex:(nonnull id (^)(id))block
{
    for (NSInteger i = 0; i < self.count; i++) {
        if ([block(self[i]) boolValue]) {
            return i;
        }
    }
    return -1;
}

// ['a', 'b', 'c'].last()      =>      'c'
- (id)vzt_last
{
    return self.lastObject;
}

// [11, 12, 13, 14].last(n -> n % 2 == 0)       =>      14
- (id)vzt_last:(nonnull id (^)(id))block
{
    for (NSInteger i = self.count - 1; i >= 0; i--) {
        if ([block(self[i]) boolValue]) {
            return self[i];
        }
    }
    return nil;
}

// [11, 12, 13, 14].lastIndex(n -> n % 2 == 0)       =>      3
- (NSInteger)vzt_lastIndex:(nonnull id (^)(id))block
{
    for (NSInteger i = self.count-1; i >= 0; i--) {
        if ([block(self[i]) boolValue]) {
            return i;
        }
    }
    return -1;
}

// ['a', 'b', 'c', 'a', 'b'].indexOf('a')       =>      0
- (NSInteger)vzt_indexOf:(id)obj
{
    NSUInteger index = [self indexOfObject:obj];
    return index == NSNotFound ? -1 : index;
}

// ['a', 'b', 'c', 'a', 'b'].lastIndexOf('a')       =>      3
- (NSInteger)vzt_lastIndexOf:(id)obj
{
    for (NSInteger i = self.count - 1; i >= 0; i--) {
        if ([self[i] isEqual:obj]) {
            return i;
        }
    }
    return -1;
}

// [1, 2, 3].reverse()      =>      [3, 2, 1]
- (NSArray *)vzt_reverse
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    for (id obj in self.reverseObjectEnumerator) {
        [array addObject:obj];
    }
    return array;
}

// ['a', 'b', 'a', 'c'].distinct()      =>      ['a', 'b', 'c']
- (NSArray *)vzt_distinct
{
    return [[NSOrderedSet orderedSetWithArray:self] array];
}

// ['a', 'b', 'c'].join(',')      =>      'a,b,c'
- (NSString *)vzt_join:(NSString *)str
{
    NSMutableString *ret = [NSMutableString new];
    for (int i = 0; i < self.count; i++) {
        if (i > 0) [ret appendString:str];
        [ret appendString:[self[i] description]];
    }
    return ret;
}

// [1, 2, 3].join_property(',', 'description')      =>      '1,2,3'
- (NSString *)vzt_join:(NSString *)str property:(NSString *)property
{
    NSMutableString *ret = [NSMutableString new];
    for (int i = 0; i < self.count; i++) {
        if (i > 0) [ret appendString:str];

        id value = [self[i] valueForKey:property];
        [ret appendString:[value description]];
    }
    return ret;
}

// [1, 2, 3].repeat(2)      =>      [1, 2, 3, 1, 2, 3]
- (NSArray *)vzt_repeat:(NSUInteger)count
{
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        [array addObjectsFromArray:self];
    }
    return array;
}

// [1, 2, 3, 4, 5, 6, 7, 8].slice(3)    =>      [[1, 2, 3], [4, 5, 6], [7, 8]]
- (NSArray *)vzt_slice:(NSUInteger)count
{
    NSMutableArray *arrays = [NSMutableArray array];
    for (int i = 0; i < self.count; i += count) {
        [arrays addObject:[self subarrayWithRange:NSMakeRange(i, MIN(count, self.count - i))]];
    }
    return arrays;
}

// [1, 2, 3, 4, 5].sub_array(0, 3)      =>      [1, 2, 3]
- (NSArray *)vzt_sub:(NSUInteger)start array:(NSUInteger)length
{
    NSMutableArray *arrays = [NSMutableArray array];
    if (start + 1 > self.count) {
        return nil;
    } else {
        [arrays addObjectsFromArray:[self subarrayWithRange:NSMakeRange(start, MIN(length, self.count - start))]];
    }
    return arrays;
}

// [1, [2, [3, 4]], 5].flatten(false)      =>      [1, 2, [3, 4], 5]
- (NSArray *)vzt_flatten:(BOOL)recursive
{
    NSMutableArray *array = [NSMutableArray array];
    for (id value in self) {
        if ([value isKindOfClass:[NSArray class]]) {
            [array addObjectsFromArray:recursive ? [value vzt_flatten:YES] : value];
        }
        else {
            [array addObject:value];
        }
    }
    return array;
}

// [1, [2, [3, 4]], 5].flatten()      =>      [1, 2, 3, 4, 5]
- (NSArray *)vzt_flatten
{
    return [self vzt_flatten:YES];
}

// [1, 2].concat([3])      =>      [1, 2, 3]
- (NSArray *)vzt_concat:(NSArray *)array
{
    return [self arrayByAddingObjectsFromArray:array];
}

// [1, 2, 3].splice(1, 0, 5)      =>      [1, 2, 5, 3]
// [1, 2, 3].splice(1, 1, 5)      =>      [1, 5, 3]
- (NSArray *)vzt_splice:(NSInteger)start :(NSUInteger)deleteCount :(id)insertValue
{
    if (deleteCount == 0 && !insertValue) {
        return self;
    }
    if (start < 0) {
        start = self.count + start;
    }
    NSMutableArray *array = self.mutableCopy;
    if (start < 0 || start + deleteCount > self.count) {
        // index out of bounds
        return nil;
    }
    if (deleteCount) {
        [array removeObjectsInRange:NSMakeRange(start, deleteCount)];
    }
    if (insertValue) {
        [array insertObject:insertValue atIndex:start];
    }
    return array;
}

// [1, 2, 3].splice(1, 1)      =>      [1, 3]
- (NSArray *)vzt_splice:(NSInteger)start :(NSUInteger)deleteCount
{
    return [self vzt_splice:start :deleteCount :nil];
}

// [1, 2, 3].splice(1)      =>      [1]
// [1, 2, 3].splice(-2)      =>      [1]
- (NSArray *)vzt_splice:(NSInteger)start
{
    NSInteger deleteCount = self.count - (start < 0 ? self.count + start : start);
    return [self vzt_splice:start :deleteCount :nil];
}

@end
