//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VZMistActionResponse : NSObject

+ (instancetype)newWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *)error;

@end
