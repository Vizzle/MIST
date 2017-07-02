//
//  MistJSHttpRequestHelper.m
//  MIST-Demo
//
//  Created by lingwan on 2017/6/29.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistJSHttpRequestHelper.h"

@interface MistJSHttpRequestHelper ()
@property (nonatomic, strong) NSMutableDictionary *handlers;
@property (nonatomic, strong) JSManagedValue *handler;
@property (nonatomic, strong) JSValue *callback;
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

- (instancetype)init {
    if (self = [super init]) {
        _handlers = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)get:(NSString *)url :(JSValue *)handler {
    [self.handlers setObject:handler forKey:url];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:-1];
    request.HTTPMethod = @"GET";
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable err) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        JSValue *cb = weakSelf.handlers[url];
        
        if (cb) {
            [cb callWithArguments:@[dict?:@{}, err?:@{}]];
        }
    }] resume];
}

@end
