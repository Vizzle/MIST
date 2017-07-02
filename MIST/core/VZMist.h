//
//  VZMist.h
//  MIST
//
//  Created by John Wong on 12/21/16.
//  Copyright © 2016 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VZFlexLayout/VZFNode.h>
#import "VZMistItem.h"
#import "VZMistError.h"

@class VZTExpressionContext;


/**
 Mist 用于标签解析的代码块

 @param specs 声明的布局
 @param tpl 书写的模板
 @param item 承载数据的item
 @param data 模板使用的数据
 @return node 虚拟dom
 */
typedef VZFNode * (^VZMistTagProcessor)(NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data);


/**
 Mist 的全局错误处理代码块

 @param error 处理中遇到的错误
 */
typedef void (^VZMistErrorCallback)(VZMistError *error);

/**
 Mist 引擎，用于注册标签解析
 */
@interface VZMist : NSObject

+ (instancetype)sharedInstance;


/**
 全局的错误回调。一般的处理方式为开发环境弹出提示，线上环境打日志追踪
 */
@property (nonatomic, copy) VZMistErrorCallback errorCallback;

/**
 注册标签的解析

 @param tag 标签名称，例如text、stack。
 @param processor 标签解析的代码块
 */
- (void)registerTag:(NSString *)tag withProcessor:(VZMistTagProcessor)processor;


/**
 注册 js 全局对象或方法，如果需要注册方法，object 传入 block

 @param name 变量名
 @param object 可以是对象或者 block
 */
- (void)registerJSGlobalVariable:(NSString *)name object:(id)object;


/**
 注册 Class 到 js 环境

 @param types 类名数组
 */
- (void)registerJSTypes:(NSArray<NSString *> *)types;

@end
