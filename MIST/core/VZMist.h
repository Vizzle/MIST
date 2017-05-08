//
//  VZMist.h
//  MIST
//
//  Created by John Wong on 12/21/16.
//  Copyright © 2016 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<VZFlexLayout/VZFlexLayout.h>)
#import <VZFlexLayout/VZFNode.h>
#else
#import "VZFNode.h"
#endif

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
 处理标签，返回解析出的 node。Mist 内部调用，外部不应使用。

 @param tag 标签名称
 @param specs 声明的布局
 @param tpl 书写的模板
 @param item 承载数据的 item
 @param data 模板使用的数据
 @return node 虚拟 dom
 */
- (VZFNode *)processTag:(NSString *)tag
              withSpecs:(NodeSpecs)specs
               template:(NSDictionary *)tpl
                   item:(id<VZMistItem>)item
                   data:(VZTExpressionContext *)data;

@end
