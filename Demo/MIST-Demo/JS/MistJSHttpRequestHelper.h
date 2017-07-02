//
//  MistJSHttpRequestHelper.h
//  MIST-Demo
//
//  Created by lingwan on 2017/6/29.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol MistJSHttpRequestHelperExports <NSObject, JSExport>

- (void)get:(NSString *)url :(JSValue *)handler;

@end

@interface MistJSHttpRequestHelper : NSObject <MistJSHttpRequestHelperExports>

+ (instancetype)sharedInstance;

/**
 模板里的 js 发请求
 */
- (void)get:(NSString *)url :(JSValue *)handler;

@end
