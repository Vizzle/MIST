//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "NSNumber+VZTExtension.h"

@implementation NSNumber (VZTExtension)

- (NSString *)vzt_toFixed:(NSUInteger)fractionDigits {
    return [NSString stringWithFormat:[NSString stringWithFormat:@"%%.%luf", (unsigned long)fractionDigits], self.doubleValue];
}

- (NSString *)vzt_toPrecision:(NSUInteger)precision {
    int exponent = floor(log10(fabs(self.doubleValue)) + 1);
    return [self vzt_toFixed:precision - exponent];
}

@end
