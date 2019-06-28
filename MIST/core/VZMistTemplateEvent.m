//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZMistTemplateEvent.h"
#import "VZDataStructure.h"
#import "VZMistItem.h"
#import "VZMistTemplateHelper.h"
#import "VZTExpressionNode.h"
#import "VZMistTemplateAction.h"

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

#import <objc/runtime.h>

@implementation VZMistTemplateEvent
{
    __weak id<VZMistItem> _item;
    NSString *_eventId;
    VZMistTemplateAction *_action;
    VZMistTemplateAction *_onceAction;
    VZTExpressionContext *_expressionContext;
    NSMutableDictionary *_eventDict;
}

+ (VZMistTemplateEvent *)eventWithName:(NSString *)name
                                  dict:(NSDictionary *)dict
                     expressionContext:(VZTExpressionContext *)expressionContext
                                  item:(id<VZMistItem>)item
{
    NSString *nodeId = [expressionContext valueForKey:kVZTemplateNodeId];
    NSDictionary *actionDict = dict[name];
    NSDictionary *onceActionDict = dict[[name stringByAppendingString:@"-once"]];
    if ([actionDict isKindOfClass:[VZTExpressionNode class]]) {
        actionDict = [VZMistTemplateHelper extractValueForExpression:actionDict withContext:expressionContext];
    }
    if ([onceActionDict isKindOfClass:[VZTExpressionNode class]]) {
        onceActionDict = [VZMistTemplateHelper extractValueForExpression:onceActionDict withContext:expressionContext];
    }
    if (actionDict || onceActionDict) {
        NSString *eventId = [nodeId ?: @"" stringByAppendingFormat:@">%@", name];
        return [[self alloc] initWithItem:item eventId:eventId action:actionDict onceAction:onceActionDict expressionContext:expressionContext];
    }
    return nil;
}

- (instancetype)initWithItem:(id<VZMistItem>)item
                     eventId:(NSString *)eventId
                      action:(NSDictionary *)action
                  onceAction:(NSDictionary *)onceAction
           expressionContext:(VZTExpressionContext *)expressionContext
{
    if (self = [super init]) {
        if ([action isKindOfClass:[NSString class]]) {
            action = @{action: @""};
        }
        if ([onceAction isKindOfClass:[NSString class]]) {
            onceAction = @{onceAction: @""};
        }
        
        _item = item;
        _eventId = eventId;
        _expressionContext = [expressionContext copy];
        _action = [VZMistTemplateAction actionWithDictionary:__vzDictionary(action, nil) expressionContext:_expressionContext item:_item];
        _onceAction = [VZMistTemplateAction actionWithDictionary:__vzDictionary(onceAction, nil) expressionContext:_expressionContext item:_item];
        _eventDict = [NSMutableDictionary new];
    }
    return self;
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
    
    static void *key = &key;
    NSMutableArray *invokedActions = objc_getAssociatedObject(_item, key);
    if (!invokedActions) {
        invokedActions = [NSMutableArray new];
        if (_item) {
            objc_setAssociatedObject(_item, key, invokedActions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    if (![invokedActions containsObject:_eventId]) {
        [_onceAction runWithSender:sender];
        _onceAction = nil;
        [invokedActions addObject:_eventId];
    }
    
    [_action runWithSender:sender];
    
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
