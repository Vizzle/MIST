//
//  MistDemoImageView.m
//  MIST
//
//  Created by moxin on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistDemoImageView.h"
#import <SDWebImage/UIImageView+WebCache.h>


@implementation MistDemoImageView

/**
 覆写 UIImageView 的 setImage: 方法来解决 gif 的 UIImageView 复用后无法播放的问题。

 @param image 图片
 */
- (void)setImage:(UIImage *)image
{
    NSArray *images = image.images;
    NSTimeInterval duration = image.duration;

    if (images.count && duration) {
        //gif
        self.animationImages = images;
        self.animationDuration = duration;
        self.animationRepeatCount = self.animationRepeatCount ?: HUGE_VAL; //context里拿到直接设置
        super.image = images.lastObject;                                   //播放n次后显示最后一帧
        [self startAnimating];
    } else {
        //非gif
        //gif相关状态清理
        [self stopAnimating];
        self.animationImages = nil;
        self.animationDuration = 0;
        self.animationRepeatCount = 0;

        [super setImage:image];
    }
}

- (void)vz_setImageWithURL:(NSURL *)url
                      size:(CGSize)sz
          placeholderImage:(UIImage *)loadingImage
                errorImage:(UIImage *)errorImage
                   context:(id)ctx
           completionBlock:(id<VZFActionWrapper>)completion
{
    [self sd_setImageWithURL:url
            placeholderImage:loadingImage
                     options:0
                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                       
                       if (completion) {
                           [completion invoke:self event:nil];
                       }
                   }];
}

//- (void)vz_setImageWithURL:(NSURL *)url size:(CGSize)sz contentMode:(UIViewContentMode)contentMode placeholderImage:(UIImage *)loadingImage errorImage:(UIImage *)errorImage context:(id)ctx completionBlock:(id<VZFActionWrapper>)completion
//{
//    [self sd_setImageWithURL:url
//            placeholderImage:loadingImage
//                     options:0
//                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//
//                       if (completion) {
//                           [completion invoke:self event:nil];
//                       }
//                   }];
//}


@end
