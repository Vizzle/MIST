//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <VZFlexLayout/VZFlexLayout.h>
#import "VZMistTemplate.h"
#import "VZMistItem.h"
#import "VZMist.h"

@class VZTExpressionContext;

@interface VZFNode (Template)

+ (instancetype)nodeFromTemplate:(VZMistTemplate *)tpl
                            data:(VZTExpressionContext *)data
                            item:(id<VZMistItem>)item
                    mistInstance:(VZMist *)mistInstance;

+ (void)bindTextNodeSpecs:(TextNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindImageNodeSpecs:(ImageNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindButtonNodeSpecs:(ButtonNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data;
+ (void)bindScrollNodeSpecs:(ScrollNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data;
+ (void)bindPagingNodeSpecs:(PagingNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindIndicatorNodeSpecs:(IndicatorNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data;
+ (void)bindLineNodeSpecs:(LineNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data;
+ (void)bindStackNodeSpecs:(StackNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data;
+ (void)bindNodeSpecs:(NodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data;
+ (void)bindTextFieldNodeSpecs:(TextFieldNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindTextViewNodeSpecs:(TextViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindSwitchNodeSpecs:(SwitchNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindSegmentedControlNodeSpecs:(SegmentedControlNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindPickerNodeSpecs:(PickerNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindWebViewNodeSpecs:(WebViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;
+ (void)bindMapViewNodeSpecs:(MapViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item;

@end
