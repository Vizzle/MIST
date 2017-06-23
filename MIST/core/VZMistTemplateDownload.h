//
//  VZMistTemplateDownload.h
//  MIST
//
//  Created by moxin on 2017/1/16.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#ifndef VZMistTemplateDownload_h
#define VZMistTemplateDownload_h
#import <UIKit/UIKit.h>


@protocol VZMistTplDownload <NSObject>

/**
 下载模板API

 @param tplIds 模板ID数组
 @param completion 下载完成回调
 @param opt 其它参数
 */
- (void)downloadTemplates:(NSArray *)tplIds
               completion:(void (^)(NSDictionary<NSString *, NSString *> *))completion
                  options:(NSDictionary *)opt;

@end
#endif /* VZMistTemplateDownload_h */
