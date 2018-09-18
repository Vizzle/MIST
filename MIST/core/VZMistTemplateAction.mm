//
//  VZMistTemplateAction.m
//  Pods
//
//  Created by Sleen on 2017/6/26.
//
//

#import "VZMistTemplateAction.h"
#import "VZMistTemplateHelper.h"
#import "VZDataStructure.h"
#import "VZFDispatch.h"
#import "VZMistCallHelper.h"
#import <objc/runtime.h>
#import "VZMist.h"

#define kVZMistActionResultKey @"_result_"

@implementation VZMistTemplateAction
{
    NSDictionary * _dict;
    NSDictionary *_successAction;
    NSDictionary *_errorAction;
    NSDictionary *_finishAction;
    VZTExpressionContext *_context;
    NSString *_resultName;
    NSTimeInterval _delay;
    BOOL _mainThread;

    VZMistTemplateActionBlock _successBlock;
    VZMistTemplateActionBlock _errorBlock;
    NSArray<VZMistTemplateAction *> *_actions;
}

+ (instancetype)actionWithDictionary:(NSDictionary *)dictionary expressionContext:(VZTExpressionContext *)context item:(id<VZMistItem>)item {
    dictionary = __vzDictionary(dictionary, nil);
    if (!dictionary) {
        return nil;
    }
    
    if (dictionary[@"if"] && !__vzBool([VZMistTemplateHelper extractValueForExpression:dictionary[@"if"] withContext:context], NO)) {
        return nil;
    }
    
    VZMistTemplateAction *action = [VZMistTemplateAction new];
    action->_item = item;
    action->_context = context;
    action->_dict = dictionary;
    action->_type = __vzStringDefault(dictionary[@"type"]);
    action->_resultName = __vzString(dictionary[@"result"], kVZMistActionResultKey);
    NSArray *actionsArray = __vzArray(dictionary[@"actions"], nil);
    if (actionsArray) {
        NSMutableArray *actions = [NSMutableArray new];
        for (NSDictionary *dict in actionsArray) {
            VZMistTemplateAction *childAction = [VZMistTemplateAction actionWithDictionary:dict expressionContext:context item:item];
            if (childAction) {
                [actions addObject:childAction];
            }
        }
        action->_actions = actions;
    }
    if (action->_type || action->_actions) {
        action->_successAction = dictionary[@"success"];
        action->_errorAction = dictionary[@"error"];
        action->_finishAction = dictionary[@"finish"];
        action->_delay = __vzDouble([VZMistTemplateHelper extractValueForExpression:dictionary[@"delay"] withContext:context], 0);
        action->_mainThread = __vzBool([VZMistTemplateHelper extractValueForExpression:dictionary[@"main-thread"] withContext:context], NO);
        action->_params = dictionary[@"params"];
    }
    
    return action;
}

- (VZMistTemplateActionBlock)success {
    __weak __typeof(self) weakSelf = self;
    return ^(id value) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf){
            [strongSelf->_context pushVariableWithKey:strongSelf->_resultName value:value];
            if (strongSelf->_finishAction) {
                [[strongSelf.class actionWithDictionary:strongSelf->_finishAction expressionContext:strongSelf->_context.copy item:strongSelf->_item] runWithSender:strongSelf->_sender];
            }
            if (strongSelf->_successAction) {
                [[strongSelf.class actionWithDictionary:strongSelf->_successAction expressionContext:strongSelf->_context.copy item:strongSelf->_item] runWithSender:strongSelf->_sender];
            }
            [strongSelf->_context popVariableWithKey:strongSelf->_resultName];
            
            if (strongSelf->_successBlock) {
                strongSelf->_successBlock(value);
            }
        }

    };
}

- (VZMistTemplateActionBlock)error {
    __weak __typeof(self) weakSelf = self;
    return ^(id error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf){
            [strongSelf->_context pushVariableWithKey:strongSelf->_resultName value:error];
            if (strongSelf->_finishAction) {
                [[strongSelf.class actionWithDictionary:strongSelf->_finishAction expressionContext:strongSelf->_context.copy item:strongSelf->_item] runWithSender:nil];
            }
            if (strongSelf->_errorAction) {
                [[strongSelf.class actionWithDictionary:strongSelf->_errorAction expressionContext:strongSelf->_context.copy item:strongSelf->_item] runWithSender:nil];
            }
            [strongSelf->_context popVariableWithKey:strongSelf->_resultName];
            
            if (strongSelf->_errorBlock) {
                strongSelf->_errorBlock(error);
            }
        }

    };
}

- (void)dealloc {
//    NSLog(@"action dealloc: %@", [_dict dictionaryWithValuesForKeys:@[@"type", @"params"]]);
}

- (void)runWithSender:(id)sender {
    if (_type || _actions) {
        VZMistTemplateActionRegisterBlock actionBlock;
        if (_actions) {
            actionBlock = ^(VZMistTemplateAction *action) {
                VZMistTemplateAction *weakAction = action;
                NSMutableArray *array = [NSMutableArray new];
                for (int i = 0; i < self->_actions.count; i++) {
                    [array addObject:NSNull.null];
                }
                __block int count = (int)self->_actions.count;
                __block BOOL success = YES;
                void(^block)(int i, id value) = ^(int i, id value) {
                    count--;
                    if (value) {
                        array[i] = value;
                    }

                    if (count == 0) {
                        if (success) {
                            if (weakAction.success) {
                                weakAction.success(array);
                            }
                        }
                        else {
                            if (weakAction.error) {
                                weakAction.error(nil);
                            }
                        }
                        // break the retain cycle
                        weakAction->_actions = nil;
                    }
                };
                for (int i = 0; i < self->_actions.count; i++) {
                    VZMistTemplateAction *child = self->_actions[i];
                    child->_successBlock = ^(id value) {
                        @synchronized(array) {
                            block(i, value);
                        }
                    };
                    child->_errorBlock = ^(id error) {
                        @synchronized(array) {
                            success = NO;
                            block(i, nil);
                        }
                    };
                    [child runWithSender:sender];
                }
            };
        }
        else {
            actionBlock = [self.class actionWithName:self.type];
        }

        if (actionBlock) {
            _sender = sender;
            _params = [VZMistTemplateHelper extractValueForExpression:_params withContext:_context];
            if (_delay > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_delay * NSEC_PER_SEC)), _mainThread || [NSThread isMainThread] ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    actionBlock(self);
                });
            }
            else if (_mainThread && ![NSThread isMainThread]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    actionBlock(self);
                });
            }
            else {
                actionBlock(self);
            }
        }
        else {
            NSAssert(NO, @"action type '%@' can not be recognized", self.type);
        }
    }
    else {
        for (NSString *sel in _dict) {
            if ([sel hasPrefix:@"js-"]) {
                NSString *methodName = [sel substringFromIndex:3];
                id param = _dict[sel];
                param = [VZMistTemplateHelper extractValueForExpression:param withContext:_context];
                param = convertOCToJS(param);
                
                JSContext *jsContext = [VZMistCallHelper shared].context;
                JSValue *method = jsContext[methodName];
                
                if (method && !method.isNull && !method.isUndefined) {
                    [method callWithArguments:[param isKindOfClass:[NSArray class]] ? param : @[param]];
                }
            } else {
                VZMistTemplateController *controller = _item.tplController;
                SEL selector = NSSelectorFromString(sel);
                if ([(id)controller respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    id param = _dict[sel];
                    param = [VZMistTemplateHelper extractValueForExpression:param withContext:_context];
                    [(id)controller performSelector:selector withObject:param withObject:sender];
#pragma clang diagnostic pop
                } else {
                    NSLog(@"%@ does not responds to selector '%@'", controller, sel);
                }
            }
        }
        self.success(nil);
    }
}

+ (NSMutableDictionary *)_actionMap {
    static NSMutableDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [NSMutableDictionary new];
    });
    return dict;
}

+ (void)registerActionWithName:(NSString *)name block:(VZMistTemplateActionRegisterBlock)block {
    [self _actionMap][name] = block;
}

+ (VZMistTemplateActionRegisterBlock)actionWithName:(NSString *)name {
    return [self _actionMap][name];
}

@end
