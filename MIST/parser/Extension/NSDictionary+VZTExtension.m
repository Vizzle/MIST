//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "NSDictionary+VZTExtension.h"


@implementation NSDictionary (VZTExtension)

- (NSDictionary *)vzt_set:(NSString *)key value:(id)value
{
    NSMutableDictionary *mutableDict = self.mutableCopy;
    mutableDict[key] = value;
    return mutableDict;
}

@end
