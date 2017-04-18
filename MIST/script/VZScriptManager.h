//
//  O2OScriptManager.h
//  O2OMist
//
//  Created by lingwan on 16/7/28.
//  Copyright © 2016年 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 模板中脚本部分解密，需要外部实现；如果不设置，默认模板中的脚本未加密
 
 @param rawScript 模板中原始的脚本内容
 */
typedef NSString * (^VZMistDecryptScript)(NSString *rawScript);

@interface VZScriptManager : NSObject

+ (instancetype)manager;

/**
 生成VZMistTemplate时执行mist文件中的脚本
 */
- (void)runScript:(NSString *)script;

/**
 注册脚本解密方法，如果是明文，直接返回
 */
- (void)registerDecryptMethod:(VZMistDecryptScript)method;

@end
