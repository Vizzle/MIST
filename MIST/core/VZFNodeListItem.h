//
//  Copyright © 2016年 Vizlab. All rights reserved.
//


#import <UIKit/UIKit.h>


@class VZFNode;
@class VZFluxStore;


@interface VZFNodeListItem : NSObject


@property (nonatomic, strong) VZFluxStore *store;

//计算后的item宽度
@property (nonatomic, assign, readonly) float itemWidth;
@property (nonatomic, assign, readonly) float itemHeight;
@property (nonatomic, weak, readonly) UIView *attachedView;

- (void)updateModel:(id)model constrainedSize:(CGSize)sz context:(id)context;
- (void)updateState;
- (void)attachToView:(UIView *)view;
- (void)detachFromView;

@end


@interface VZFNodeListItem (SubClass)

+ (VZFNode *)nodeForItem:(id)item Store:(VZFluxStore *)store Context:(id)ctx;

@end
