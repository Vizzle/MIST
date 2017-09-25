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
#import "VZMistJSContextBuilder.h"

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
    NSMutableArray *_stateUpdatesQueue;
    __weak UITableView *_tableView;
    __weak UIViewController *_viewController;
    NSDictionary *_rawData;
    NSDictionary *_processedData;
    BOOL _didLoad;
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
        _rawData = data;
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
    _didLoad = NO;
    _state = nil;
    [self _rebuild:YES];
}

- (void)setData:(NSDictionary *)data keepState:(BOOL)b
{
    _rawData = data;
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

- (NSDictionary *)rawData {
    return _rawData;
}

- (NSDictionary *)data {
    return _processedData ?: _rawData;
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
    if (_tpl && _rawData) {
        _expressionContext = [VZTExpressionContext new];
        [_expressionContext pushVariables:_rawData];
        [_expressionContext pushVariableWithKey:@"_width_" value:@([UIScreen mainScreen].bounds.size.width)];
        [_expressionContext pushVariableWithKey:@"_height_" value:@([UIScreen mainScreen].bounds.size.height)];
        
        if (_customData) {
            [_expressionContext pushVariables:_customData];
        }
        
        [_expressionContext pushVariableWithKey:@"_rawdata_" value:_rawData];
        [_expressionContext pushVariableWithKey:@"_data_" value:_rawData];
        
        NSDictionary *tplData = [VZMistTemplateHelper extractValueForExpression:_tpl.data withContext:_expressionContext];
        [_expressionContext pushVariables:tplData];
        NSMutableDictionary *processedData = _rawData.mutableCopy;
        [processedData setValuesForKeysWithDictionary:tplData];
        _processedData = processedData;
        
        [_expressionContext pushVariableWithKey:@"_data_" value:processedData];
        
        if (_tplController && !_didLoad) {
            [_tplController didLoadTemplate];
            _didLoad = YES;
        }

        if (useInitialState) {
            _state = _tpl.initialState ?: [_tplController initialState];
        }
        _state = [VZMistTemplateHelper extractValueForExpression:_state withContext:_expressionContext];
        [_expressionContext pushVariableWithKey:@"state" value:_state];
        

        [self updateModel:@{}
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
            _jsContext = [VZMistJSContextBuilder newJSContext];
            [_jsContext evaluateScript:script withSourceURL:[NSURL URLWithString:@"main.js"]];
        }
    }
    
    return _jsContext;
}

@end
