//
//  VZMistTemplateController.m
//  MIST
//
//  Created by moxin on 2016/12/6.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZMistTemplateController.h"
#import "VZMistItem.h"
#import "VZFNodeListItem.h"

#import <UIKit/UIKit.h>


@implementation VZMistTemplateController{

}

- (instancetype)initWithItem:(id<VZMistItem>)item
{
    if (self = [super init]) {
        _item = item;
    }
    return self;
}


- (void)didLoadTemplate {}
- (void)didReload {}
- (id)initialState { return nil; }
- (UIView *)viewWithTag:(NSInteger)tag
{
    if (![self.item respondsToSelector:@selector(attachedView)]) {
        NSAssert(NO, @"%@ does not responds to selector 'attachedView'", self.item);
        return nil;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    UIView *attachedView = [self.item performSelector:@selector(attachedView)];
#pragma clang diagnostic pop

    return [attachedView viewWithTag:tag];
}

- (void)updateState:(NSDictionary *)stateChanges
{
    [_item updateState:^id(id oldState) {
        NSMutableDictionary *state = [oldState ?: @{} mutableCopy];
        [state setValuesForKeysWithDictionary:stateChanges];
        return state;
    }];
}

- (void)openUrl:(NSString *)url
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
}

@end
