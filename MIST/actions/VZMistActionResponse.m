//
//  VZMistActionResponse.m
//  Pods
//
//  Created by Sleen on 2017/6/26.
//
//

#import "VZMistActionResponse.h"

@implementation VZMistActionResponse
{
    NSHTTPURLResponse *_response;
    NSData *_data;
    NSError *_error;
}

+ (instancetype)newWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *)error {
    VZMistActionResponse *ret = [VZMistActionResponse new];
    ret->_response = response;
    ret->_data = data;
    ret->_error =error;
    return ret;
}

- (NSData *)data {
    return _data;
}

- (NSString *)textData:(NSStringEncoding)encoding {
    return _data ? [[NSString alloc] initWithData:_data encoding:encoding] : nil;
}

- (NSString *)textData {
    return [self textData:NSUTF8StringEncoding];
}

- (id)jsonData {
    return _data ? [NSJSONSerialization JSONObjectWithData:_data options:NSJSONReadingAllowFragments error:nil] : nil;
}

- (NSInteger)statusCode {
    return _response.statusCode;
}

- (NSDictionary *)headers {
    return _response.allHeaderFields;
}

- (NSError *)error {
    return _error;
}

@end
