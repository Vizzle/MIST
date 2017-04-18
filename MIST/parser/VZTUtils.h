//
//  VZTUtils.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

NSString *vzt_stringValue(id obj);
BOOL vzt_boolValue(id obj);
BOOL vzt_isEqual(id a, id b);
id vzt_invokeMethod(id target, SEL selector, NSArray *parameters);

#ifdef __cplusplus
}
#endif


@interface VZTNull : NSObject

+ (instancetype)null;

@end
