//
//  VZMistTemplateEvent.h
//  MIST
//
//  Created by moxin on 2016/12/7.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol VZMistItem;


/**
 Mist 的事件封装类。
 */
@interface VZMistTemplateEvent : NSObject


/**
 Mist 的事件创建方法。

 @param item Mist 的 item
 @param action 响应事件的行为。键为调用的selector，值为调用的参数。
 @param onceAction 响应时间的行为，创建后只调用一次。键值同上。
 @return Mist 的事件实例。
 */
- (instancetype)initWithItem:(id<VZMistItem>)item action:(NSDictionary *)action onceAction:(NSDictionary *)onceAction;


/**
 事件触发时调用，以触发响应事件的行为。

 @param sender 触发时间的对象，例如view、node。
 */
- (void)invokeWithSender:(id)sender;

@end
