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
#import "VZMistInternal.h"

@implementation VZMistPropertyProcessor
@end

@implementation VZMist
{
    NSMutableDictionary<NSString *, VZMistTagProcessor> *_processorMap;
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, VZMistPropertyProcessor *> *> *_propertiesMap;
    pthread_rwlock_t rwlock;
    
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
        _propertiesMap = [NSMutableDictionary dictionaryWithCapacity:10];
        [self registerDefaultTags];
        
        pthread_rwlock_init(&jsRwlock, NULL);
        _registeredJSVariables = [NSMutableDictionary dictionary];

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
        [VZFNode bindTextNodeSpecs:textSpecs fromTemplate:tpl data:data item:item];
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

    [self registerTag:@"text-field" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        TextFieldNodeSpecs textFieldSpecs = TextFieldNodeSpecs();
        [VZFNode bindTextFieldNodeSpecs:textFieldSpecs fromTemplate:tpl data:data item:item];
        return [VZFTextFieldNode newWithTextFieldAttributes:textFieldSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"text-view" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        TextViewNodeSpecs textViewSpecs = TextViewNodeSpecs();
        [VZFNode bindTextViewNodeSpecs:textViewSpecs fromTemplate:tpl data:data item:item];
        return [VZFTextViewNode newWithTextViewAttributes:textViewSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"switch" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        SwitchNodeSpecs switchSpecs = SwitchNodeSpecs();
        [VZFNode bindSwitchNodeSpecs:switchSpecs fromTemplate:tpl data:data item:item];
        return [VZFSwitchNode newWithSwitchAttributes:switchSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"segmented-control" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        SegmentedControlNodeSpecs segmentedControlSpecs = SegmentedControlNodeSpecs();
        [VZFNode bindSegmentedControlNodeSpecs:segmentedControlSpecs fromTemplate:tpl data:data item:item];
        return [VZFSegmentedControlNode newWithSegmentedControlAttributes:segmentedControlSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"picker" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
        PickerNodeSpecs pickerSpecs = PickerNodeSpecs();
        [VZFNode bindPickerNodeSpecs:pickerSpecs fromTemplate:tpl data:data item:item];
        return [VZFPickerNode newWithPickerAttributes:pickerSpecs NodeSpecs:specs];
    }];

    [self registerTag:@"web-view" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {
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

- (void)registerProperty:(nonnull NSString *)name
                 forType:(nullable NSString *)type
          withApplicator:(nonnull VZMistPropertyApplicator)applicator
            unapplicator:(nullable VZMistPropertyUnapplicator)unapplicator {
    if (!type) type = @"shared";
    VZMistPropertyProcessor *processor = [VZMistPropertyProcessor new];
    processor.applicator = applicator;
    processor.unapplicator = unapplicator;
    NSMutableDictionary *map = _propertiesMap[type];
    if (!map) {
        map = [NSMutableDictionary dictionary];
        _propertiesMap[type] = map;
    }
    map[name] = processor;
}

- (NSDictionary<NSString *,VZMistPropertyProcessor *> *)getProperties:(NSString *)type dict:(NSDictionary *)dict {
    NSMutableDictionary *properties = [NSMutableDictionary new];
    NSDictionary *sharedProperties = _propertiesMap[@"shared"];
    NSDictionary *typeProperties = _propertiesMap[type];
    for (NSString *name in sharedProperties) {
        if (dict[name]) {
            properties[name] = sharedProperties[name];
        }
    }
    for (NSString *name in typeProperties) {
        if (dict[name]) {
            properties[name] = typeProperties[name];
        }
    }
    return properties;
}

- (void)registerJSGlobalVariable:(NSString *)name object:(id)object {
    if (name.length > 0 && object) {
        pthread_rwlock_wrlock(&jsRwlock);
        [_registeredJSVariables setObject:object forKey:name];
        pthread_rwlock_unlock(&jsRwlock);
    }
}

- (void)registerJSTypes:(NSArray<NSString *> *)types {
    _exportTypes = types;
}

@end
