//
//  MistJSToast.h
//  MIST-Demo
//
//  Created by lingwan on 2017/7/2.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol MistJSToastExports <NSObject, JSExport>

+ (void)alert:(NSString *)title :(NSString *)content;

@end

@interface MistJSToast : NSObject <MistJSToastExports>

+ (void)alert:(NSString *)title :(NSString *)content;

@end
