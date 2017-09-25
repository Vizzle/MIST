//
//  VZMistBuiltinActions.m
//  Pods
//
//  Created by Sleen on 2017/6/26.
//
//

#import "VZMistBuiltinActions.h"
#import "VZMistTemplateAction.h"
#import "VZDataStructure.h"
#import "VZFDispatch.h"
#import "VZMistActionResponse.h"
#import "VZMistActionAlertDelegate.h"
#import "VZMistActionBlockTarget.h"
#import <JavaScriptCore/JavaScriptCore.h>

#import <objc/runtime.h>

@implementation VZMistBuiltinActions

+ (void)load {
    [self http_request];
    [self location];
    [self url];
    [self update_state];
    [self alert];
    [self delay];
    [self timer];
    [self cache];
    [self pop];
    [self notify];
    [self js];
}

+ (void)http_request {
    [VZMistTemplateAction registerActionWithName:@"http-request" block:^(VZMistTemplateAction *action) {
        NSString *url = __vzStringDefault(action.params[@"url"]);
        NSString *method = __vzString(action.params[@"method"], @"GET");
        NSData *body = action.params[@"body"] ? [NSJSONSerialization dataWithJSONObject:action.params[@"body"] options:0 error:nil] : nil;
        NSTimeInterval timeout = __vzDouble(action.params[@"timeout"], 10);
        BOOL cache = __vzBool(action.params[@"cache"], YES);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:timeout];
        request.HTTPMethod = method;
        request.HTTPBody = body;
        request.cachePolicy = cache ? NSURLRequestReturnCacheDataElseLoad : NSURLRequestReloadIgnoringLocalCacheData;
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable err) {
            VZMistActionResponse *r = [VZMistActionResponse newWithResponse:(NSHTTPURLResponse *)response data:data error:err];
            if (err) {
                action.error(r);
            }
            else {
                action.success(r);
            }
        }] resume];
        
    }];
}

+ (void)location {
    [VZMistTemplateAction registerActionWithName:@"location" block:^(VZMistTemplateAction *action) {
        // TODO
    }];
}

+ (void)url {
    [VZMistTemplateAction registerActionWithName:@"url" block:^(VZMistTemplateAction *action) {
        NSString *url = __vzStringDefault(action.params[@"url"]);
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        [[NSNotificationCenter defaultCenter] postNotificationName:<#(nonnull NSNotificationName)#> object:<#(nullable id)#> userInfo:<#(nullable NSDictionary *)#>]
        action.success(nil);
    }];
}

+ (void)update_state {
    [VZMistTemplateAction registerActionWithName:@"update-state" block:^(VZMistTemplateAction *action) {
        NSDictionary *change = __vzDictionary(action.params, nil);
        [action.item updateState:^NSDictionary *(NSDictionary *oldState) {
            NSMutableDictionary *state = [oldState ?: @{} mutableCopy];
            [state setValuesForKeysWithDictionary:change];
            return state;
        }];
        action.success(nil);
    }];
}

+ (void)alert {
    [VZMistTemplateAction registerActionWithName:@"alert" block:^(VZMistTemplateAction *action) {
        NSString *title = __vzStringDefault(action.params[@"title"]);
        NSString *message = __vzStringDefault(action.params[@"message"]);
        NSArray *buttons = __vzArray(action.params[@"buttons"], @[@"OK"]);
        NSString *cancel = __vzStringDefault(action.params[@"cancel"]);
        
        VZMistActionAlertDelegate *delegate = [VZMistActionAlertDelegate delegateWithBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            dict[@"index"] = @(buttonIndex);
            dict[@"title"] = [alertView buttonTitleAtIndex:buttonIndex];
            dict[@"cancel"] = @(buttonIndex == alertView.cancelButtonIndex);
            action.success(dict);
        }];
        
        VZFDispatchMain(0, ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                message:message
                                                               delegate:delegate
                                                      cancelButtonTitle:cancel
                                                      otherButtonTitles:nil];
            static const void *key = &key;
            objc_setAssociatedObject(alertView, key, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            for (NSString *button in buttons) {
                [alertView addButtonWithTitle:__vzStringDefault(button)];
            }
            [alertView show];
        });
    }];
}

+ (void) delay{
    [VZMistTemplateAction registerActionWithName:@"delay" block:^(VZMistTemplateAction *action) {
        NSTimeInterval time = __vzDouble(action.params[@"time"], 0);
        
        VZFDispatchMain(time, ^{
            action.success(nil);
        });
    }];
}

+ (void)timer {
    [VZMistTemplateAction registerActionWithName:@"timer" block:^(VZMistTemplateAction *action) {
        NSTimeInterval time = __vzDouble(action.params[@"time"], 0);
        BOOL repeat = __vzBool(action.params[@"repeat"], NO);
        __weak NSTimer *weakTimer;
        VZMistActionBlockTarget *target = [VZMistActionBlockTarget targetWithBlock:^{
            if (!action.item) {
                if (weakTimer) {
                    [weakTimer invalidate];
                }
                return;
            }
            action.success(nil);
        }];
        NSTimer *timer = [NSTimer timerWithTimeInterval:time target:target selector:@selector(invoke) userInfo:nil repeats:repeat];
        weakTimer = timer;
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }];
}

+ (void)cache {
    [VZMistTemplateAction registerActionWithName:@"set-cache" block:^(VZMistTemplateAction *action) {
        for (NSString *key in action.params) {
            [[NSUserDefaults standardUserDefaults] setObject:action.params[key] forKey:key];
        }
        action.success(nil);
    }];
    
    [VZMistTemplateAction registerActionWithName:@"get-cache" block:^(VZMistTemplateAction *action) {
        for (NSString *key in action.params) {
            [[NSUserDefaults standardUserDefaults] setObject:action.params[key] forKey:key]; // TODO
        }
        action.success(nil);
    }];
}

+ (void)pop {
    [VZMistTemplateAction registerActionWithName:@"pop" block:^(VZMistTemplateAction *action) {
        BOOL animated = __vzBool(action.params[@"animated"], YES);
        UIViewController *vc = action.item.viewController;
        if (vc.navigationController) {
            [vc.navigationController popViewControllerAnimated:animated];
            action.success(nil);
        }
        else {
            action.error(nil);
        }
    }];
}

+ (void)notify {
    [VZMistTemplateAction registerActionWithName:@"notify" block:^(VZMistTemplateAction *action) {
        NSString *name = __vzStringDefault(action.params[@"name"]);
        NSDictionary *userInfo = __vzDictionary(action.params[@"userInfo"], nil);
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:userInfo];
        action.success(nil);
    }];
}

+ (void)js {
    [VZMistTemplateAction registerActionWithName:@"js" block:^(VZMistTemplateAction *action) {
        NSString *script = __vzStringDefault(action.params[@"script"]);
        JSContext *context = [JSContext new];
        @try {
            JSValue *value = [context evaluateScript:script];
            action.success([value toObject]);
        } @catch (id error) {
            action.error(error);
        }
    }];
}

@end
