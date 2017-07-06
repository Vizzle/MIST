//
//  VZMistJSContextBuilder.m
//  MIST
//
//  Created by lingwan on 2017/7/3.
//
//

#import "VZMistJSContextBuilder.h"
#import "VZTUtils.h"
#import "VZMist.h"
#import "VZMistInternal.h"
#import "VZMistListItem.h"

#ifdef DEBUG
#import "VZScriptErrorMsgViewController.h"
#endif

@implementation VZMistJSContextBuilder

+ (JSContext *)newJSContext {
    JSContext *context = [[JSContext alloc] init];
    [self registerTypes:[[VZMist sharedInstance] exportTypes] inContext:context];
    [self registerGlobalVariables:context];
    
    return context;
}

+ (void)registerTypes:(NSArray *)types inContext:(JSContext *)context
{
    for (NSString *type in types) {
        Class clz = NSClassFromString(type);
        if (clz) {
            context[type] = clz;
        }
    }
}

#define JSContextLog(fmt, ...) NSLog(@"MistJSContext: " fmt, ##__VA_ARGS__)

+ (void)registerGlobalVariables:(JSContext *)context
{
    NSDictionary *bizJsVariables = [[VZMist sharedInstance] registeredJSVariables];
    for (NSString *name in bizJsVariables) {
        context[name] = bizJsVariables[name];
    }
    
    context[@"callInstance"] = ^id(id target, NSString *selector, NSArray *parameters) {
        return vzt_invokeMethod(target, NSSelectorFromString(selector), parameters);
    };
    
    context[@"callClass"] = ^id(NSString *className, NSString *selector, NSArray *parameters) {
        Class clz = NSClassFromString(className);
        if (clz) {
            return vzt_invokeMethod(clz, NSSelectorFromString(selector), parameters);
        }
        return nil;
    };
    
    context[@"oclog"] = ^() {
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            JSContextLog(@"%@", [jsVal toObject]);
        }
    };
    
    context[@"dispatch_after"] = ^(double time, JSValue *func) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"dispatch_async_main"] = ^(JSValue *func) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"dispatch_sync_main"] = ^(JSValue *func) {
        if ([NSThread currentThread].isMainThread) {
            [func callWithArguments:nil];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [func callWithArguments:nil];
            });
        }
    };
    
    context[@"dispatch_async_global_queue"] = ^(JSValue *func) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"updateState"] = ^(VZMistListItem *item, NSDictionary *stateChanges) {
        [item updateState:^NSDictionary *(NSDictionary *oldState) {
            NSMutableDictionary *state = [oldState ?: @{} mutableCopy];
            [state setValuesForKeysWithDictionary:stateChanges];
            return state;
        }];
    };
    
    context[@"setState"] = ^(VZMistListItem *item, NSDictionary *newState) {
        [item updateState:^NSDictionary *(NSDictionary *oldState) {
            return newState;
        }];
    };
    
#ifdef DEBUG
    
    context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
        JSContextLog(@"%@", exception);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            errorMessage = exception.description;
            
            if (!errorWindow) {
                errorWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
                errorWindow.windowLevel = UIWindowLevelStatusBar + 1.0f;
                errorWindow.backgroundColor = [UIColor colorWithRed:224/255.0 green:72/255.0 blue:32/255.0 alpha:1];
                
                UIButton *errBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, [UIScreen mainScreen].bounds.size.width - 10, 20)];
                errBtn.titleLabel.font = [UIFont systemFontOfSize:10];
                [errBtn setTitle:errorMessage forState:UIControlStateNormal];
                [errBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                errBtn.tag = 100;
                [errBtn addTarget:self action:@selector(tapJsErrorView) forControlEvents:UIControlEventTouchDown];
                [errorWindow addSubview:errBtn];
                
                UIButton *close = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 18, 0, 16, 16)];
                close.titleLabel.font = [UIFont systemFontOfSize:16];
                [close setTitle:@"×" forState:UIControlStateNormal];
                [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchDown];
                [errorWindow addSubview:close];
            } else {
                UIButton *errBtn = [errorWindow viewWithTag:100];
                [errBtn setTitle:errorMessage forState:UIControlStateNormal];
            }
            
            errorWindow.hidden = NO;
        });
    };
#endif
    
}

#ifdef DEBUG

static UIWindow *errorWindow = nil;
static NSString *errorMessage = nil;

+ (void)tapJsErrorView
{
    errorWindow.hidden = YES;
    
    VZScriptErrorMsgViewController *errorMsgVC = [[VZScriptErrorMsgViewController alloc] initWithMsg:errorMessage];
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    UINavigationController *nav = nil;
    
    if ([root isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)root;
    } else {
        nav = root.navigationController;
    }
    
    NSAssert(nav, @"VZMistJSContextBuilder: 未能获取导航栏");
    
    [nav pushViewController:errorMsgVC animated:YES];
}

+ (void)close {
    errorWindow.hidden = YES;
}

#endif

@end
