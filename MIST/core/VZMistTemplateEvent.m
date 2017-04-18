//
//  VZMistTemplateEvent.m
//  MIST
//
//  Created by moxin on 2016/12/7.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZMistTemplateEvent.h"
#import "VZDataStructure.h"
#import "VZMistItem.h"
#import <UIKit/UIKit.h>


@implementation VZMistTemplateEvent
{
    id<VZMistItem> _item;
    NSDictionary *_action;
    NSDictionary *_onceAction;
}

- (instancetype)initWithItem:(id<VZMistItem>)item
                      action:(NSDictionary *)action
                  onceAction:(NSDictionary *)onceAction
{
    if (self = [super init]) {
        _item = item;
        _action = __vzDictionary(action, nil);
        _onceAction = __vzDictionary(onceAction, nil);
    }
    return self;
}


- (void)performAction:(NSDictionary *)action withSender:(id)sender
{
    if (!action) {
        return;
    }

    for (NSString *sel in action) {
        VZMistTemplateController *controller = _item.tplController;
        SEL selector = NSSelectorFromString(sel);
        if ([(id)controller respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [(id)controller performSelector:selector withObject:action[sel] withObject:sender];
#pragma clang diagnostic pop
        } else {
            NSLog(@"%@ does not responds to selector '%@'", controller, sel);
        }
    }
}

- (void)invokeWithSender:(id)sender
{
    [self performAction:_onceAction withSender:sender];
    _onceAction = nil;
    [self performAction:_action withSender:sender];
}

- (NSString* )description
{
    NSString* desc = [NSString stringWithFormat:@"action:%@\n controller:%@\n", _action,_item.tplController];
    return desc;
}

@end
