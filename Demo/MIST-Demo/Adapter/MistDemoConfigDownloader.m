//
//  MistDemoConfigDownloader.m
//  MIST
//
//  Created by lingwan on 2017/3/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistDemoConfigDownloader.h"

@implementation MistDemoConfigDownloader

+ (instancetype)defaultDelegate {
    static MistDemoConfigDownloader *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MistDemoConfigDownloader alloc] init];
    });
    
    return instance;
}

- (void)loadPageConfig:(NSString *)pageName completion:(VZMistPageCompletion)completion {
    NSString *url = [NSString stringWithFormat:@"http://127.0.0.1:10001/%@.mist", pageName];
    NSData *mockConfig = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    NSDictionary *result = nil;
    NSError *error;

    if (mockConfig) {
        result = [NSJSONSerialization JSONObjectWithData:mockConfig options:0 error:&error];
        completion(result, error);
    }
}

- (void)showError:(NSError *)error inViewController:(UIViewController *)vc {
}

@end
