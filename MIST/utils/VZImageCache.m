//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZImageCache.h"


@implementation VZImageCache
{
    NSCache *_memCache; //thread safe
}

static inline NSUInteger vzMemoryCacheCostForImage(UIImage *image)
{
    return image.size.width * image.size.height * image.scale;
}


+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    static VZImageCache *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _memCache = [[NSCache alloc] init];
        _memCache.name = @"com.image-memory-cache.vz";
        _memCache.countLimit = 0;     //no constraint
        _memCache.totalCostLimit = 0; //no constraint
    }
    return self;
}

- (void)storeImage:(UIImage *)img WithKey:(NSString *)key
{
    if (!img || !key) {
        return;
    }

    [_memCache setObject:img forKey:key cost:vzMemoryCacheCostForImage(img)];
}
- (UIImage *)imageForKey:(NSString *)key
{
    return [_memCache objectForKey:key];
}

- (void)removeImageForKey:(NSString *)key
{
    [_memCache removeObjectForKey:key];
}

- (void)removeAllObjects
{
    [_memCache removeAllObjects];
}

@end
