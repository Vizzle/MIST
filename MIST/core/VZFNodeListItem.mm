//
//  VZFNodeListItem.m
//  MIST
//
//  Created by moxin on 2016/12/6.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZFNodeListItem.h"

#import <VZFlexLayout/VZFNodeListItemRecycler.h>
#import <VZFlexLayout/VZFSizeRange.h>
#import <VZFlexLayout/VZFNodeProvider.h>
#import <VZFlexLayout/VZFNodeSpecs.h>

@interface UIView(VZFNodeListItemInfo)


@end

const void* g_vzfIndexPath = &g_vzfIndexPath;
@implementation UIView(VZFNodeListItemInfo)

- (void)setVz_indexPath:(NSIndexPath *)indexPath{
    objc_setAssociatedObject(self, &g_vzfIndexPath, indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath* )vz_indexPath{
    return objc_getAssociatedObject(self, g_vzfIndexPath);
}

@end

@interface VZFNodeListItem () <VZFNodeProvider>

@property (nonatomic, strong) VZFNodeListItemRecycler *recycler;
@end


@implementation VZFNodeListItem

- (void)setStore:(VZFluxStore *)store
{
    _store = store;
    _recycler.store = store;
}

- (float)itemHeight
{
    return MAX(0.0001, _recycler.layoutSize.height);
}
- (float)itemWidth
{
    return _recycler.layoutSize.width;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _recycler = [[VZFNodeListItemRecycler alloc] initWithNodeProvider:[self class]];
    }
    return self;
}

- (void)dealloc
{
    //    NSLog(@"[%@]-->dealloc",self.class);
}

- (void)updateModel:(id)model constrainedSize:(CGSize)sz context:(id)context
{
    [_recycler calculate:model constrainedSize:sz context:context];
}

- (void)updateState
{
    return [_recycler updateState];
}


- (void)attachToView:(UIView *)view
{
//    NSIndexPath *indexPath = view.vz_indexPath;
//    BOOL rasterizeUseCache = indexPath && indexPath.section == self.indexPath.section && indexPath.row == self.indexPath.row;
//    [view setVz_indexPath:self.indexPath];
    
    [_recycler attachToView:view rasterizeUseCache:NO];
    _attachedView = view;
}

- (void)detachFromView
{
    [_recycler detachFromView];
    _attachedView = nil;
}

+ (VZFNode<VZFNodeRequiredMethods> *)nodeForItem:(id)item Store:(VZFluxStore *)store Context:(id)ctx
{
    return nil;
}

@end
