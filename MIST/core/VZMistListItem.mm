//
//  VZMistItem.m
//  MIST
//
//  Created by moxin on 2016/12/6.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZMistListItem.h"
#import "VZMistTemplate.h"
#import "VZFNode+Template.h"
#import "VZTExpressionContext.h"
#import "VZMistTemplateHelper.h"
#import "VZMistTemplateController.h"
#import <VZFlexLayout/VZFValue.h>
#import "VZMistItem.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "VZMist.h"
#import "VZMistInternal.h"
#import "VZTUtils.h"

#ifdef DEBUG
#import "VZScriptErrorMsgViewController.h"
#endif

@interface VZMistWeakObject : NSObject

@property (nonatomic, weak) id object;

@end


@implementation VZMistWeakObject

- (instancetype)initWithObject:(id)object
{
    if (self = [super init]) {
        _object = object;
    }
    return self;
}
@end


static const void *kMistItemInCell = &kMistItemInCell;

@interface VZMistListItem ()
@property (nonatomic, copy) void (^updateStateCompletion)();

#ifdef DEBUG
@property (nonatomic, strong) UIWindow *errorWindow;
@property (nonatomic, strong) NSString *errMsg;
#endif

@end

@implementation VZMistListItem
{
    VZTExpressionContext *_expressionContext;
    NSMutableArray *_stateUpdatesQueue;
    __weak UITableView *_tableView;
    __weak UIViewController *_viewController;
}

@synthesize jsContext = _jsContext;

- (instancetype)init
{
    NSAssert(NO, @"%@: init: should not be called.", self.class);
    return [self initWithData:nil customData:nil template:nil];
}

- (instancetype)initWithData:(NSDictionary *)data customData:(NSDictionary *)customData template:(VZMistTemplate *)tpl
{
    self = [super init];
    if (self) {
        //初始化数据和模板
        _data = data;
        _customData = customData ? [customData mutableCopy] : [NSMutableDictionary dictionary];
        _stateUpdatesQueue = [NSMutableArray new];

        _tpl = tpl;
        [self render];
    }
    return self;
}

- (void)render
{
    if (!_tpl) {
        return;
    }
    Class tplClass = _tpl.tplControllerClass ?: [self templateControllerClass];
    _tplController = [[tplClass alloc] initWithItem:self];
    if (_tplController) {
        [_tplController didLoadTemplate];
    }
    _state = nil;
    [self _rebuild:YES];
}

- (void)setData:(NSDictionary *)data keepState:(BOOL)b
{
    _data = data;
    [self _rebuild:!b];
}

- (void)updateState:(NSDictionary * (^)(NSDictionary * oldState))block completion:(void (^)())completion {
    if (completion) {
        self.updateStateCompletion = completion;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_stateUpdatesQueue addObject:block];
        
        //丢弃来不及处理的state
        if (_stateUpdatesQueue.count == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self _doUpdateState];
            });
        }
        
    });
}

- (void)updateState:(NSDictionary * (^)(NSDictionary *))block
{
    [self updateState:block completion:nil];
}

- (void)attachToView:(UIView *)view atIndexPath:(NSIndexPath *)indexPath
{
    [self attachToView:view];
    _indexPath = indexPath;
}


/**
 在 cell 上绑定对应 item，为了在 item 更新 cell 的时候，检查下 cell 对应的 item 还是不是自己。
 */
- (void)attachToView:(UIView *)view
{
    VZMistWeakObject *preItemWrapper = objc_getAssociatedObject(view, kMistItemInCell);
    if (preItemWrapper.object && preItemWrapper.object != self) {
        [preItemWrapper.object detachFromView];
    }
    [super attachToView:view];
    objc_setAssociatedObject(view, kMistItemInCell, [[VZMistWeakObject alloc] initWithObject:self], OBJC_ASSOCIATION_RETAIN);
}

- (void)detachFromView
{
    objc_setAssociatedObject(self.attachedView, kMistItemInCell, nil, OBJC_ASSOCIATION_RETAIN);
    [super detachFromView];
    _tableView = nil;
    _viewController = nil;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - private methods

+ (dispatch_queue_t)_stateUpdateQueue
{
    static dispatch_queue_t serialQueue = NULL;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create("com.mist.state-update", DISPATCH_QUEUE_SERIAL);

    });
    return serialQueue;
}

- (void)_doUpdateState
{
    //求最终state的值
    for (NSDictionary * (^block)(NSDictionary *) in _stateUpdatesQueue) {
        _state = block(_state);
    }
    [_stateUpdatesQueue removeAllObjects];

    dispatch_async([[self class] _stateUpdateQueue], ^{

        CGFloat oldHeight = self.itemHeight;
        [self _rebuild:NO];

        dispatch_async(dispatch_get_main_queue(), ^{

            UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:self.indexPath];

            VZMistWeakObject *itemWrapper = objc_getAssociatedObject(self.attachedView, kMistItemInCell);
            VZMistListItem *item = itemWrapper.object;

            if (item == self && cell) {
                //如果高度不变，刷新当前cell
                if (self.itemHeight == oldHeight) {
                    [self attachToView:cell.contentView];
                } else {
                    [self _reloadTableView];
                }
            } else if (self.attachedView) {
                [self attachToView:self.attachedView];
            }

            if (self.updateStateCompletion) {
                self.updateStateCompletion();
                
                //只执行一次
                self.updateStateCompletion = nil;
            }
        });
    });
}

- (void)_rebuild:(BOOL)useInitialState
{
    if (_tpl && _data) {
        _expressionContext = [VZTExpressionContext new];
        [_expressionContext pushVariables:_data];
        [_expressionContext pushVariableWithKey:@"_width_" value:@([UIScreen mainScreen].bounds.size.width)];
        [_expressionContext pushVariableWithKey:@"_height_" value:@([UIScreen mainScreen].bounds.size.height)];
        [_expressionContext pushVariableWithKey:@"_data_" value:self.data];
        if (_customData) {
            [_expressionContext pushVariables:_customData];
        }
        if (useInitialState) {
            _state = _tpl.initialState ?: [_tplController initialState];
        }
        _state = [VZMistTemplateHelper extractValueForExpression:_state withContext:_expressionContext];
        [_expressionContext pushVariableWithKey:@"state" value:_state];

        [self updateModel:self.data
            constrainedSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, VZ::FlexValue::Auto())
                    context:[[VZMistWeakObject alloc] initWithObject:self]];

        if (_tplController) {
            [_tplController didReload];
        }
    }
}

- (void)_reloadTableView
{
    if ([self tableView]) {
        [[self tableView] reloadData];
    }
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - VZMistItem

@class VZMistTemplateController;

- (Class)templateControllerClass
{
    return [VZMistTemplateController class];
}

- (VZMist *)mistInstance
{
    return [VZMist sharedInstance];
}

- (UITableView *)tableView
{
    // TODO 暂时通过 superview 的方式找到 table view。
    if (!_tableView) {
        UIView *tableView = self.attachedView;
        while (tableView) {
            if ([tableView isKindOfClass:[UITableView class]]) {
                _tableView = (UITableView *)tableView;
                break;
            }
            tableView = tableView.superview;
        }
    }
    return _tableView;
}

- (UIViewController *)viewController
{
    if (!_viewController) {
        UIResponder *responder = [[self tableView] nextResponder];
        while (responder) {
            if ([responder isKindOfClass:[UIViewController class]]) {
                _viewController = (UIViewController *)responder;
                break;
            }
            responder = responder.nextResponder;
        }
    }
    return _viewController;
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - @override subclass methods

+ (VZFNode *)nodeForItem:(id)data Store:(VZFluxStore *__unused)store Context:(id)ctx
{
    VZMistListItem *context = [ctx isKindOfClass:[VZMistWeakObject class]] ? (VZMistListItem *)[ctx object] : ctx;

    if (context.tpl && context.data) {
        @try {
            return [VZFNode nodeFromTemplate:context->_tpl data:context->_expressionContext item:context mistInstance:context.mistInstance];
        } @catch (NSException *exception) {
            NSAssert(YES, @"%@: node is nil", self.class);

        } @finally {
        }

    } else {
        return nil;
    }
}

# pragma mark - Javascript

- (JSContext *)jsContext {
    if (!_jsContext) {
        NSString *script = self.tpl.script;
        if (script.length) {
            _jsContext = [self jsContextBuilder];
            [_jsContext evaluateScript:script];
        }
    }
    
    return _jsContext;
}

- (JSContext *)jsContextBuilder {
    JSContext *context = [[JSContext alloc] init];
    [self registerGlobalFunctions:context];
//    [self registerTypes:nil inContext:context];
    
    return context;
}

#define JSContextLog(fmt, ...) NSLog(@"MistJSContext: " fmt, ##__VA_ARGS__)

- (void)registerGlobalFunctions:(JSContext *)context {
    NSDictionary *bizJsFunctions = [[VZMist sharedInstance] registeredJSFunctions];
    for (NSString *funcName in bizJsFunctions) {
        context[funcName] = bizJsFunctions;
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
    
    __weak __typeof(self) weakSelf = self;
    
    context[@"updateState"] = ^(NSDictionary *stateChanges) {
        [weakSelf updateState:^NSDictionary *(NSDictionary *oldState) {
            NSMutableDictionary *state = [oldState ?: @{} mutableCopy];
            [state setValuesForKeysWithDictionary:stateChanges];
            return state;
        }];
    };
    
    context[@"setState"] = ^(NSDictionary *newState) {
        [weakSelf updateState:^NSDictionary *(NSDictionary *oldState) {
            return newState;
        }];
    };
    
#ifdef DEBUG
    context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
        JSContextLog(@"%@", exception);
        
        NSString *msg = exception.description;
        weakSelf.errMsg = msg;
        weakSelf.errorWindow.hidden = NO;
        
        if (!weakSelf.errorWindow) {
            weakSelf.errorWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
            weakSelf.errorWindow.windowLevel = UIWindowLevelStatusBar + 1.0f;
            weakSelf.errorWindow.backgroundColor = [UIColor blackColor];
            UIButton *errBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, [UIScreen mainScreen].bounds.size.width - 10, 20)];
            errBtn.titleLabel.font = [UIFont systemFontOfSize:10];
            [errBtn setTitle:msg forState:UIControlStateNormal];
            [errBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            errBtn.tag = 100;
            [errBtn addTarget:weakSelf action:@selector(handleTapErrorBtn) forControlEvents:UIControlEventTouchDown];
            [weakSelf.errorWindow addSubview:errBtn];
            weakSelf.errorWindow.hidden = NO;
        } else {
            UIButton *errBtn = [weakSelf.errorWindow viewWithTag:100];
            [errBtn setTitle:msg forState:UIControlStateNormal];
        }
    };
#endif
    
}

#ifdef DEBUG

- (void)handleTapErrorBtn {
    self.errorWindow.hidden = YES;
    
    VZScriptErrorMsgViewController *errorMsgVC = [[VZScriptErrorMsgViewController alloc] initWithMsg:self.errMsg];
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    UINavigationController *nav = nil;
    
    if ([root isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)root;
    } else {
        nav = root.navigationController;
    }
    
    NSAssert(nav, @"VZMistListItem: 未能获取导航栏");
    
    [nav pushViewController:errorMsgVC animated:YES];
}

#endif

//- (void)registerTypes:(NSArray *)types inContext:(JSContext *)context {
//    for (NSString *type in types) {
//        Class clz = NSClassFromString(type);
//        if (clz) {
//            context[type] = clz;
//        }
//    }
//}

@end
