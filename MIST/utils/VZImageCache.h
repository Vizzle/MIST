//
//  VZImageCache.h
//  MIST
//
//  Created by moxin on 16/9/14.
//  Copyright © 2016 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  缓存本地图片，解决iOS8.0 多线程读图crash问题，目前不涉及文件存储
 */
@interface VZImageCache : NSObject

+ (instancetype)sharedInstance;

- (void)storeImage:(UIImage *)img WithKey:(NSString *)key;
- (UIImage *)imageForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key;

@end
