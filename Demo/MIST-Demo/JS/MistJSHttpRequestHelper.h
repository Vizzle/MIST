//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MistJSHttpRequestHelper : NSObject

+ (instancetype)sharedInstance;

/**
 模板里的 js 发请求
 */
- (void)get:(NSString *)url handler:(void (^)(NSDictionary *, NSError *))handler;

@end
