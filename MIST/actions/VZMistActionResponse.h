//
//  VZMistActionResponse.h
//  Pods
//
//  Created by Sleen on 2017/6/26.
//
//

#import <Foundation/Foundation.h>

@interface VZMistActionResponse : NSObject

+ (instancetype)newWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *)error;

@end
