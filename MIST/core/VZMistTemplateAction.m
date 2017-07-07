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
#import "VZMistJSEngine.h"
#import <objc/runtime.h>

#define kVZMistActionResultKey @"_result_"

@implementation VZMistTemplateAction
{
    NSDictionary * _dict;
    NSDictionary *_successAction;
    NSDictionary *_errorAction;
    NSDictionary *_finishAction;
    VZTExpressionContext *_context;
    NSString *_resultName;
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
    action->_successAction = dictionary[@"success"];
    action->_errorAction = dictionary[@"error"];
    action->_finishAction = dictionary[@"finish"];
    action->_params = [VZMistTemplateHelper extractValueForExpression:dictionary[@"params"] withContext:context];
    action->_resultName = __vzString(dictionary[@"result"], kVZMistActionResultKey);
    
    return action;
}

- (VZMistTemplateActionBlock)success {
    return ^(id value) {
        [_context pushVariableWithKey:_resultName value:value];
        if (_finishAction) {
            [[self.class actionWithDictionary:_finishAction expressionContext:_context item:_item] runWithSender:nil];
        }
        if (_successAction) {
            [[self.class actionWithDictionary:_successAction expressionContext:_context item:_item] runWithSender:nil];
        }
        [_context popVariableWithKey:_resultName];
    };
}

- (VZMistTemplateActionBlock)error {
    return ^(id error) {
        [_context pushVariableWithKey:_resultName value:error];
        if (_finishAction) {
            [[self.class actionWithDictionary:_finishAction expressionContext:_context item:_item] runWithSender:nil];
        }
        if (_errorAction) {
            [[self.class actionWithDictionary:_errorAction expressionContext:_context item:_item] runWithSender:nil];
        }
        [_context popVariableWithKey:_resultName];
    };
}

- (void)runWithSender:(id)sender {
    if (self.type) {
        VZMistTemplateActionRegisterBlock action = [self.class actionWithName:self.type];
        if (action) {
            action(self);
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
                
                JSContext *jsContext = [VZMistJSEngine context];
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
