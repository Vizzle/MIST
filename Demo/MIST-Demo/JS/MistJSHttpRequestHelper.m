//
//  MistJSHttpRequestHelper.m
//  MIST-Demo
//
//  Created by lingwan on 2017/6/29.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistJSHttpRequestHelper.h"

@interface MistJSHttpRequestHelper ()
@end

@implementation MistJSHttpRequestHelper

+ (instancetype)sharedInstance {
    static MistJSHttpRequestHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [MistJSHttpRequestHelper new];
    });
    
    return sharedInstance;
}

- (void)get:(NSString *)url handler:(void (^)(NSDictionary *, NSError *))handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:-1];
    request.HTTPMethod = @"GET";
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable err) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        handler(dict, err);
    }] resume];
}

@end
