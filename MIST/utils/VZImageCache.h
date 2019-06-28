//
//  Copyright © 2016年 Vizlab. All rights reserved.
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
