//
//  WBTimelineTemplateController.h
//  MIST
//
//  Created by moxin on 2017/3/14.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "VZMistTemplateController.h"

@interface WBTimelineTemplateController : VZMistTemplateController


/**
 格式化微博的create_at发布时间
 
 @param time created_at
 @return 格式化后的时间
 */
+ (NSString* )createdAt:(NSString* )time;
/**
 Timeline大图浏览

 @param data 大图数据
 @param sender 图片view
 */
- (void)displayImages:(NSDictionary* )data sender:(UIView* )sender;


/**
 点赞
 */
- (void)onLike:(__unused id)obj sender:(UIView* )sender;


/**
 action sheet

 @param obj unused
 */
- (void)onMore:(__unused id )obj;

@end
