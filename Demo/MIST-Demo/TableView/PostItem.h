//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZListItem.h"
@interface PostItem : VZListItem<VZFNodeProvider>

@property(nonatomic,strong) NSNumber* userId;
@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSString* body;
@property(nonatomic,assign) float contentWidth;
@property(nonatomic,assign) float contentHeight;
@property(nonatomic,readonly,weak) UIView* attachedView;

- (void)updateModelWithConstrainedSize:(CGSize)sz context:(id)context;
- (void)updateState;
- (void)attachToView:(UIView *)view;
- (void)detachFromView;

@end
