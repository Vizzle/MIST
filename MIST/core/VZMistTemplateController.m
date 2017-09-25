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
#import "VZFDispatch.h"
#import "VZDataStructure.h"
#import "VZMistTemplate.h"
#import "VZMistTemplateAction.h"

#import <UIKit/UIKit.h>


@implementation VZMistTemplateController{

}

- (instancetype)initWithItem:(id<VZMistItem>)item
{
    if (self = [super init]) {
        _item = item;
        for (NSString *key in _item.tpl.notifications) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotification:) name:key object:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

    // actions or notifications
- (void)_runAction:(id)action actions:(NSDictionary *)actions {
    NSString *actionName;
    NSDictionary *actionParams;
    if ([action isKindOfClass:[NSString class]]) {
        actionName = action;
    }
    else if ([action isKindOfClass:[NSDictionary class]]) {
        actionName = action[@"name"];
        actionParams = __vzDictionary(action[@"params"], nil);
    }
    else {
        return;
    }

    NSDictionary *actionDict = actions[actionName];
    if (actionDict) {
        VZTExpressionContext *context;
        if (actionParams) {
            context = self.item.expressionContext.copy;
            [context pushVariables:actionParams];
        }
        else {
            context = self.item.expressionContext;
        }
        VZMistTemplateAction *action = [VZMistTemplateAction actionWithDictionary:actionDict expressionContext:context item:self.item];
        [action runWithSender:nil];
    }
}

- (void)onNotification:(NSNotification *)notification {
    NSMutableDictionary *actionDict = [NSMutableDictionary new];
    actionDict[@"name"] = notification.name;
    actionDict[@"params"] = notification.userInfo;
    [self _runAction:actionDict actions:self.item.tpl.notifications];
}

#pragma mark - build-in actions

- (void)updateState:(NSDictionary *)stateChanges
{
    [_item updateState:^NSDictionary *(NSDictionary * oldState) {
        NSMutableDictionary *state = [oldState ?: @{} mutableCopy];
        [state setValuesForKeysWithDictionary:stateChanges];
        return state;
    }];
}

- (void)openUrl:(NSString *)url
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)alert:(NSDictionary *)alert
{
    if ([alert isKindOfClass:[NSString class]]) {
        alert = @{@"message": alert};
    }
    else {
        alert = __vzDictionary(alert, nil);
    }
    
    VZFDispatchMain(0, ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:__vzStringDefault(alert[@"title"])
                                                            message:__vzStringDefault(alert[@"message"])
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:nil];
        [alertView addButtonWithTitle:@"OK"];
        [alertView show];
    });
}

- (void)runAction:(id)action {
    [self _runAction:action actions:self.item.tpl.actions];
}

- (void)postNotification:(id)notification {
    NSString *name;
    NSDictionary *userInfo;
    if ([notification isKindOfClass:[NSString class]]) {
        name = notification;
    }
    else if ([notification isKindOfClass:[NSDictionary class]]) {
        name = notification[@"name"];
        userInfo = __vzDictionary(notification[@"userInfo"], nil);
    }
    else {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:userInfo];
}

@end
