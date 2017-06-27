//
//  VZMist.mm
//  MIST
//
//  Created by John Wong on 12/21/16.
//  Copyright © 2016 Vizlab. All rights reserved.
//

#import "VZMist.h"
#import "VZFNode+Template.h"
#import <VZFlexLayout/VZFlexLayout.h>
#import <VZFlexLayout/VZFNetworkImageView.h>
#include <pthread.h>


@implementation VZMist
{
    NSMutableDictionary<NSString *, VZMistTagProcessor> *_processorMap;
    pthread_rwlock_t rwlock;
    
    NSMutableDictionary<NSString *, id> *_jsGlobalFunctions;
    pthread_rwlock_t jsRwlock;
}

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_rwlock_init(&rwlock, NULL);
        _processorMap = [NSMutableDictionary dictionaryWithCapacity:10];
        [self registerDefaultTags];
        
        pthread_rwlock_init(&jsRwlock, NULL);
        _jsGlobalFunctions = [NSMutableDictionary dictionary];

        self.errorCallback = ^(NSError *error) {
            NSLog(@"MIST error: %@", error);
        };
    }
    return self;
}

- (void)registerDefaultTags
{
    [self registerTag:@"text" withProcessor:^VZFNode *(NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        TextNodeSpecs textSpecs = TextNodeSpecs();
        [VZFNode bindTextNodeSpecs:textSpecs fromTemplate:tpl data:data];
        return [VZFTextNode newWithTextAttributes:textSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"button" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        ButtonNodeSpecs buttonSpecs = ButtonNodeSpecs();
        [VZFNode bindButtonNodeSpecs:buttonSpecs fromTemplate:tpl data:data];
        return [VZFButtonNode newWithButtonAttributes:buttonSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"image" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        ImageNodeSpecs imageSpecs = ImageNodeSpecs();
        [VZFNode bindImageNodeSpecs:imageSpecs fromTemplate:tpl data:data item:item];
        // TODO image view
        NSString *backingView = tpl[@"style"][@"backing-view"];
        Class backingViewClass = nil;
        if (backingView.length > 0) {
            backingViewClass = NSClassFromString(backingView);
        }
        if (!backingViewClass || ![backingViewClass conformsToProtocol:@protocol(VZFNetworkImageDownloadProtocol)]) {
            backingViewClass = [VZFNetworkImageView class];
        }

        return [VZFImageNode newWithImageAttributes:imageSpecs NodeSpecs:specs BackingImageViewClass:backingViewClass];
    }];

    [self registerTag:@"indicator" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        IndicatorNodeSpecs indicatorSpecs = IndicatorNodeSpecs();
        [VZFNode bindIndicatorNodeSpecs:indicatorSpecs fromTemplate:tpl data:data];
        return [VZFIndicatorNode newWithIndicatorAttributes:indicatorSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"line" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        LineNodeSpecs lineSpecs = LineNodeSpecs();
        [VZFNode bindLineNodeSpecs:lineSpecs fromTemplate:tpl data:data];
        return [VZFLineNode newWithLineAttributes:lineSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"textfield" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        TextFieldNodeSpecs textFieldSpecs = TextFieldNodeSpecs();
        [VZFNode bindTextFieldNodeSpecs:textFieldSpecs fromTemplate:tpl data:data item:item];
        return [VZFTextFieldNode newWithTextFieldAttributes:textFieldSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"textview" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        TextViewNodeSpecs textViewSpecs = TextViewNodeSpecs();
        [VZFNode bindTextViewNodeSpecs:textViewSpecs fromTemplate:tpl data:data item:item];
        return [VZFTextViewNode newWithTextViewAttributes:textViewSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"switch" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        SwitchNodeSpecs switchSpecs = SwitchNodeSpecs();
        [VZFNode bindSwitchNodeSpecs:switchSpecs fromTemplate:tpl data:data item:item];
        return [VZFSwitchNode newWithSwitchAttributes:switchSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"segmentedcontrol" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        SegmentedControlNodeSpecs segmentedControlSpecs = SegmentedControlNodeSpecs();
        [VZFNode bindSegmentedControlNodeSpecs:segmentedControlSpecs fromTemplate:tpl data:data item:item];
        return [VZFSegmentedControlNode newWithSegmentedControlAttributes:segmentedControlSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"picker" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        PickerNodeSpecs pickerSpecs = PickerNodeSpecs();
        [VZFNode bindPickerNodeSpecs:pickerSpecs fromTemplate:tpl data:data item:item];
        return [VZFPickerNode newWithPickerAttributes:pickerSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"webview" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        WebViewNodeSpecs webViewSpecs = WebViewNodeSpecs();
        [VZFNode bindWebViewNodeSpecs:webViewSpecs fromTemplate:tpl data:data item:item];
        return [VZFWebViewNode newWithWebViewAttributes:webViewSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"map" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        MapViewNodeSpecs mapSpecs = MapViewNodeSpecs();
        [VZFNode bindMapViewNodeSpecs:mapSpecs fromTemplate:tpl data:data item:item];
        return [VZFMapViewNode newWithMapViewAttributes:mapSpecs NodeSpecs:specs];
    }];
}

- (void)registerTag:(NSString *)tag withProcessor:(VZMistTagProcessor)processor
{
    if (tag.length > 0 && processor) {
        pthread_rwlock_wrlock(&rwlock);
        [_processorMap setObject:[processor copy] forKey:tag];
        pthread_rwlock_unlock(&rwlock);
    }
}


- (VZFNode *)processTag:(NSString *)tag
              withSpecs:(VZ::NodeSpecs)specs
               template:(NSDictionary *)tpl
                   item:(id<VZMistItem>)item
                   data:(VZTExpressionContext *)data
{
    if (tag.length == 0) {
        return nil;
    }
    VZFNode *ret = nil;
    pthread_rwlock_rdlock(&rwlock);
    VZMistTagProcessor processor = _processorMap[tag];
    if (processor) {
        ret = processor(specs, tpl, item, data);
    }
    pthread_rwlock_unlock(&rwlock);
    return ret;
}

- (void)registerJSFunction:(NSString *)funcName block:(id)block {
    if (funcName.length > 0 && block) {
        pthread_rwlock_wrlock(&jsRwlock);
        [_jsGlobalFunctions setObject:block forKey:funcName];
        pthread_rwlock_unlock(&jsRwlock);
    }
}

- (NSDictionary *)registeredJSFunctions {
    return _jsGlobalFunctions;
}

@end
