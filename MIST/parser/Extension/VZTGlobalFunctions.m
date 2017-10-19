//
//  VZTGlobalFunctions.m
//  O2OMist
//
//  Created by Sleen on 2016/11/9.
//  Copyright © 2016年 Alipay. All rights reserved.
//

#import "VZTGlobalFunctions.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


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

+ (NSValue *)range:(double)loc :(double)len
{
    return [NSValue valueWithRange:NSMakeRange(loc, len)];
}

#if TARGET_OS_IPHONE

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

+ (NSValue *)inset:(double)top :(double)left :(double)bottom :(double)right
{
    return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(top, left, bottom, right)];
}

#else

+ (NSValue *)size:(double)width :(double)height
{
    return [NSValue valueWithSize:CGSizeMake(width, height)];
}

+ (NSValue *)point:(double)x :(double)y
{
    return [NSValue valueWithPoint:CGPointMake(x, y)];
}

+ (NSValue *)rect:(double)x :(double)y :(double)width :(double)height
{
    return [NSValue valueWithRect:CGRectMake(x, y, width, height)];
}

+ (NSValue *)inset:(double)top :(double)left :(double)bottom :(double)right
{
    return [NSValue valueWithEdgeInsets:NSEdgeInsetsMake(top, left, bottom, right)];
}

#endif

+ (NSValue *)identity {
    return [NSValue valueWithCATransform3D:CATransform3DIdentity];
}

+ (NSValue *)m34:(CGFloat)m34 {
    CATransform3D t = CATransform3DIdentity;
    t.m34 = m34;
    return [NSValue valueWithCATransform3D:t];
}

+ (NSValue *)transformSet:(NSValue *)transform :(NSUInteger)row :(NSUInteger)column :(CGFloat)value {
    CATransform3D t = transform.CATransform3DValue;
    *((CGFloat *)&t + (row * 4 + column)) = value;
    return [NSValue valueWithCATransform3D:t];
}

+ (NSValue *)transform:(CGFloat)m11 :(CGFloat)m12 :(CGFloat)m13 :(CGFloat)m14
                      :(CGFloat)m21 :(CGFloat)m22 :(CGFloat)m23 :(CGFloat)m24
                      :(CGFloat)m31 :(CGFloat)m32 :(CGFloat)m33 :(CGFloat)m34
                      :(CGFloat)m41 :(CGFloat)m42 :(CGFloat)m43 :(CGFloat)m44 {
    CATransform3D t;
    t.m11 = m11; t.m12 = m12; t.m13 = m13; t.m14 = m14;
    t.m21 = m21; t.m22 = m22; t.m23 = m23; t.m24 = m24;
    t.m31 = m31; t.m32 = m32; t.m33 = m33; t.m34 = m34;
    t.m41 = m41; t.m42 = m42; t.m43 = m43; t.m44 = m44;
    return [NSValue valueWithCATransform3D:t];
}

+ (NSValue *)transform:(CGFloat)a :(CGFloat)b :(CGFloat)c :(CGFloat)d
                      :(CGFloat)tx :(CGFloat)ty {
    CGAffineTransform t;
    t.a = a; t.b = b; t.c = c; t.d = d;
    t.tx = tx; t.ty = ty;
    return [NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(t)];
}

+ (NSValue *)makeTranslation:(CGFloat)tx :(CGFloat)ty :(CGFloat)tz {
    return [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(tx, ty, tz)];
}

+ (NSValue *)makeTranslation:(CGFloat)tx :(CGFloat)ty {
    return [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(tx, ty, 0)];
}

+ (NSValue *)makeRotation:(CGFloat)angle :(CGFloat)x :(CGFloat)y :(CGFloat)z {
    return [NSValue valueWithCATransform3D:CATransform3DMakeRotation(angle, x, y, z)];
}

+ (NSValue *)makeRotation:(CGFloat)angle {
    return [NSValue valueWithCATransform3D:CATransform3DMakeRotation(angle, 0, 0, 1)];
}

+ (NSValue *)makeScale:(CGFloat)sx :(CGFloat)sy :(CGFloat)sz {
    return [NSValue valueWithCATransform3D:CATransform3DMakeScale(sx, sy, sz)];
}

+ (NSValue *)makeScale:(CGFloat)sx :(CGFloat)sy {
    return [NSValue valueWithCATransform3D:CATransform3DMakeScale(sx, sy, 1)];
}

+ (NSValue *)translate:(NSValue *)t :(CGFloat)tx :(CGFloat)ty :(CGFloat)tz {
    return [NSValue valueWithCATransform3D:CATransform3DTranslate(t.CATransform3DValue, tx, ty, tz)];
}

+ (NSValue *)translate:(NSValue *)t :(CGFloat)tx :(CGFloat)ty {
    return [NSValue valueWithCATransform3D:CATransform3DTranslate(t.CATransform3DValue, tx, ty, 0)];
}

+ (NSValue *)rotate:(NSValue *)t :(CGFloat)angle :(CGFloat)x :(CGFloat)y :(CGFloat)z {
    return [NSValue valueWithCATransform3D:CATransform3DRotate(t.CATransform3DValue, angle, x, y, z)];
}

+ (NSValue *)rotate:(NSValue *)t :(CGFloat)angle {
    return [NSValue valueWithCATransform3D:CATransform3DRotate(t.CATransform3DValue, angle, 0, 0, 1)];
}

+ (NSValue *)scale:(NSValue *)t :(CGFloat)sx :(CGFloat)sy :(CGFloat)sz {
    return [NSValue valueWithCATransform3D:CATransform3DScale(t.CATransform3DValue, sx, sy, sz)];
}

+ (NSValue *)scale:(NSValue *)t :(CGFloat)sx :(CGFloat)sy {
    return [NSValue valueWithCATransform3D:CATransform3DScale(t.CATransform3DValue, sx, sy, 1)];
}

+ (NSValue *)concat:(NSValue *)a :(NSValue *)b {
    return [NSValue valueWithCATransform3D:CATransform3DConcat(a.CATransform3DValue, b.CATransform3DValue)];
}

+ (NSValue *)invert:(NSValue *)t {
    return [NSValue valueWithCATransform3D:CATransform3DInvert(t.CATransform3DValue)];
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
