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
#import "VZMistTemplateHelper.h"
#import "VZTExpressionNode.h"
#import <JavaScriptCore/JavaScriptCore.h>

@implementation VZMistTemplateEvent
{
    __weak id<VZMistItem> _item;
    NSDictionary *_action;
    NSDictionary *_onceAction;
    VZTExpressionContext *_expressionContext;
    NSMutableDictionary *_eventDict;
}

- (instancetype)initWithItem:(id<VZMistItem>)item
                      action:(NSDictionary *)action
                  onceAction:(NSDictionary *)onceAction
           expressionContext:(VZTExpressionContext *)expressionContext
{
    if (self = [super init]) {
        if ([action isKindOfClass:[VZTExpressionNode class]]) {
            action = [VZMistTemplateHelper extractValueForExpression:action withContext:expressionContext];
        }
        if ([onceAction isKindOfClass:[VZTExpressionNode class]]) {
            onceAction = [VZMistTemplateHelper extractValueForExpression:onceAction withContext:expressionContext];
        }
        _item = item;
        _action = __vzDictionary(action, nil);
        _onceAction = __vzDictionary(onceAction, nil);
        _expressionContext = [expressionContext copy];
        _eventDict = [NSMutableDictionary new];
    }
    return self;
}


- (void)performAction:(NSDictionary *)action withSender:(id)sender
{
    if (!action) {
        return;
    }

    for (NSString *sel in action) {
        if ([sel hasPrefix:@"js-"]) {
            NSString *methodName = [sel substringFromIndex:3];
            id param = action[sel];
            JSContext *jsContext = _item.jsContext;
            JSValue *method = jsContext[methodName];
            if (method) {
                [method callWithArguments:@[param]];
            }
        } else {
            VZMistTemplateController *controller = _item.tplController;
            SEL selector = NSSelectorFromString(sel);
            if ([(id)controller respondsToSelector:selector]) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                id param = action[sel];
                param = [VZMistTemplateHelper extractValueForExpression:param withContext:_expressionContext];
                [(id)controller performSelector:selector withObject:param withObject:sender];
    #pragma clang diagnostic pop
            } else {
                NSLog(@"%@ does not responds to selector '%@'", controller, sel);
            }
        }
    }
}

- (void)addEventParamWithName:(NSString *)name object:(id)object
{
    _eventDict[name] = object;
}

- (void)invokeWithSender:(id)sender
{
    [self addEventParamWithName:@"sender" object:sender];
    if (_expressionContext) {
        [_expressionContext pushVariableWithKey:@"_event_" value:_eventDict.copy];
    }
    [_eventDict removeAllObjects];

    [self performAction:_onceAction withSender:sender];
    _onceAction = nil;
    [self performAction:_action withSender:sender];

    if (_expressionContext) {
        [_expressionContext popVariableWithKey:@"_event_"];
    }
}

- (NSString *)description
{
    NSString *desc = [NSString stringWithFormat:@"action:%@\n controller:%@\n", _action, _item.tplController];
    return desc;
}

@end
