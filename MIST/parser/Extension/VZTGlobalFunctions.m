//
//  VZTGlobalFunctions.m
//  O2OMist
//
//  Created by Sleen on 2016/11/9.
//  Copyright © 2016年 Alipay. All rights reserved.
//

#import "VZTGlobalFunctions.h"

#import <UIKit/UIKit.h>


@implementation VZTGlobalFunctions

@end


@implementation VZTGlobalFunctions (Math)

+ (double)abs:(double)a
{
    return fabs(a);
}

+ (double)sign:(double)a
{
    return a > 0 ? 1 : a < 0 ? -1 : a;
}

+ (double)max:(double)a :(double)b
{
    return MAX(a, b);
}

+ (double)min:(double)a :(double)b
{
    return MIN(a, b);
}

+ (double)ceil:(double)a
{
    return ceil(a);
}

+ (double)floor:(double)a
{
    return floor(a);
}

+ (double)round:(double)a
{
    return round(a);
}

+ (double)trunc:(double)a
{
    return trunc(a);
}

+ (double)sin:(double)a
{
    return sin(a);
}

+ (double)cos:(double)a
{
    return cos(a);
}

+ (double)tan:(double)a
{
    return tan(a);
}

+ (double)pow:(double)a :(double)b
{
    return pow(a, b);
}

+ (double)sqrt:(double)a
{
    return sqrt(a);
}

+ (double)log2:(double)a
{
    return log2(a);
}

+ (double)log10:(double)a
{
    return log10(a);
}

+ (double)log:(double)a
{
    return log(a);
}

+ (double)log:(double)a :(double)b
{
    return log(b) / log(a);
}

+ (double)random
{
    return (double)arc4random() / 0x100000000;
}

+ (double)random:(double)a :(double)b
{
    return a + [self random] * (b - a);
}

+ (uint)randomInt
{
    return arc4random();
}

+ (int)randomInt:(int)a :(int)b
{
    if (a > b) {
        return [self randomInt:b:a];
    } else if (a == b) {
        return a;
    }
    return arc4random() % (b - a) + a;
}

+ (double)PI
{
    return M_PI;
}

+ (double)E
{
    return M_E;
}

+ (double)HUGENUM
{
    return HUGE_VALF;
}

@end


@implementation VZTGlobalFunctions (NSValue)

+ (NSValue *)size:(double)width :(double)height
{
    return [NSValue valueWithCGSize:CGSizeMake(width, height)];
}

+ (NSValue *)point:(double)x :(double)y
{
    return [NSValue valueWithCGPoint:CGPointMake(x, y)];
}

+ (NSValue *)rect:(double)x :(double)y :(double)width :(double)height
{
    return [NSValue valueWithCGRect:CGRectMake(x, y, width, height)];
}

+ (NSValue *)range:(double)loc :(double)len
{
    return [NSValue valueWithRange:NSMakeRange(loc, len)];
}

+ (NSValue *)inset:(double)top :(double)left :(double)bottom :(double)right
{
    return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(top, left, bottom, right)];
}

@end


@implementation VZTGlobalFunctions (For)

+ (NSArray *)for:(double)start :(double)end :(double)step
{
    if (step == 0) step = 1;
    step = fabs(step);

    NSMutableArray *array = [NSMutableArray array];
    int count = ceil((end - start) / step);
    for (int i = 0; i < count; i++) {
        [array addObject:@(start + step * i)];
    }
    return array;
}

+ (NSArray *)for:(double)start :(double)end
{
    return [self for:start :end :1];
}

+ (NSArray *)for:(double)count
{
    return [self for:0 :count :1];
}

@end
