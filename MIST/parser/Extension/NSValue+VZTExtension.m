//
//  Copyright © 2016年 Vizlab. All rights reserved.
//
#import "NSValue+VZTExtension.h"
#import <UIKit/UIKit.h>

@implementation NSValue (VZTExtension)

#pragma mark - CGPoint

- (CGFloat)vzt_x {
    if (strcmp(self.objCType, @encode(CGRect)) == 0) {
        return self.CGRectValue.origin.x;
    }
    return self.CGPointValue.x;
}

- (CGFloat)vzt_y {
    if (strcmp(self.objCType, @encode(CGRect)) == 0) {
        return self.CGRectValue.origin.y;
    }
    return self.CGPointValue.y;
}

#pragma mark - CGSize

- (CGFloat)vzt_width {
    if (strcmp(self.objCType, @encode(CGRect)) == 0) {
        return self.CGRectValue.size.width;
    }
    return self.CGSizeValue.width;
}

- (CGFloat)vzt_height {
    if (strcmp(self.objCType, @encode(CGRect)) == 0) {
        return self.CGRectValue.size.height;
    }
    return self.CGSizeValue.height;
}

#pragma mark - CGRect

- (CGPoint)vzt_origin {
    return self.CGRectValue.origin;
}

- (CGSize)vzt_size {
    return self.CGRectValue.size;
}

#pragma mark - UIEdgeInsets

- (CGFloat)vzt_top {
    return self.UIEdgeInsetsValue.top;
}

- (CGFloat)vzt_left {
    return self.UIEdgeInsetsValue.left;
}

- (CGFloat)vzt_bottom {
    return self.UIEdgeInsetsValue.bottom;
}

- (CGFloat)vzt_right {
    return self.UIEdgeInsetsValue.right;
}

#pragma mark - NSRange

- (NSUInteger)vzt_location {
    return self.rangeValue.location;
}

- (NSUInteger)vzt_length {
    return self.rangeValue.length;
}

#pragma mark - CGVector

- (CGFloat)vzt_dx {
    return self.CGVectorValue.dx;
}

- (CGFloat)vzt_dy {
    return self.CGVectorValue.dy;
}

#pragma mark - UIOffset

- (CGFloat)vzt_horizontal {
    return self.UIOffsetValue.horizontal;
}

- (CGFloat)vzt_vertical {
    return self.UIOffsetValue.vertical;
}

@end
