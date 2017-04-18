//
//  VZFNodeListItem.m
//  MIST
//
//  Created by moxin on 2016/12/6.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZFNodeListItem.h"

#if __has_include(<VZFlexLayout/VZFlexLayout.h>)
#import <VZFlexLayout/VZFNodeListItemRecycler.h>
#import <VZFlexLayout/VZFSizeRange.h>
#import <VZFlexLayout/VZFNodeProvider.h>
#import <VZFlexLayout/VZFNodeSpecs.h>
#else
#import "VZFNodeListItemRecycler.h"
#import "VZFSizeRange.h"
#import "VZFNodeProvider.h"
#import "VZFNodeSpecs.h"
#endif


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
    return _recycler.layoutSize.height;
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
    [_recycler attachToView:view];
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
