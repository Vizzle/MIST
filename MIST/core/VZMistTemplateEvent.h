//
//  VZMistTemplateEvent.h
//  MIST
//
//  Created by moxin on 2016/12/7.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VZTExpressionContext.h"

#define kVZTemplateNodeId       @"_node_id_"

@protocol VZMistItem;


/**
 Mist 的事件封装类。
 */
@interface VZMistTemplateEvent : NSObject

/**
 Mist 的事件创建方法。
 
 @param name 事件名，建议以 'on-' 开头。
 @param dict 事件所在的 dictionary（node）
 @param expressionContext 用于表达式延后计算
 @param item Mist 的 item
 @return Mist 的事件实例。
 */
+ (VZMistTemplateEvent *)eventWithName:(NSString *)name
                                  dict:(NSDictionary *)dict
                     expressionContext:(VZTExpressionContext *)expressionContextxx
                                  item:(id<VZMistItem>)item;

/**
 事件触发时调用，以触发响应事件的行为。

 @param sender 触发时间的对象，例如view、node。
 */
- (void)invokeWithSender:(id)sender;

/**
 添加事件参数，在模版里通过 _event_.xxx 访问
 
 @param name 参数名
 @param object 参数值
 */
- (void)addEventParamWithName:(NSString *)name object:(id)object;

@end
