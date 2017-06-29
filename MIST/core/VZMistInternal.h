//
//  VZMistInternal.h
//  MIST
//
//  Created by lingwan on 2017/6/23.
//
//

#ifndef VZMistInternal_h
#define VZMistInternal_h

#import "VZMist.h"

@interface VZMist ()

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


/**
 VZMistTemplate 里生成 JSContext 时获取业务注册的 js 方法

 @return 已注册方法
 */
- (NSDictionary *)registeredJSFunctions;

@end
#endif /* VZMistInternal_h */
