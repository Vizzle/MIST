//
//  VZFNode+Template.h
//  MIST
//
//  Created by John Wong on 12/19/16.
//  Copyright © 2016 Vizlab. All rights reserved.
//


#import <VZFlexLayout/VZFlexLayout.h>
#import "VZMistTemplate.h"
#import "VZMistItem.h"


@interface VZFNode (Template)

+ (instancetype)nodeFromTemplate:(VZMistTemplate *)tpl
                            data:(id)data
                            item:(id<VZMistItem>)item;

+ (void)bindTextNodeSpecs:(TextNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(NSDictionary *)data;
+ (void)bindImageNodeSpecs:(ImageNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(NSDictionary *)data item:(id<VZMistItem>)item;
+ (void)bindButtonNodeSpecs:(ButtonNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(NSDictionary *)data;
+ (void)bindScrollNodeSpecs:(ScrollNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(NSDictionary *)data;
+ (void)bindPagingNodeSpecs:(PagingNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(NSDictionary *)data item:(id<VZMistItem>)item;
+ (void)bindIndicatorNodeSpecs:(IndicatorNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(NSDictionary *)data;
+ (void)bindLineNodeSpecs:(LineNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(NSDictionary *)data;
+ (void)bindStackNodeSpecs:(StackNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data;
+ (void)bindNodeSpecs:(NodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data;
+ (void)bindTextFieldNodeSpecs:(TextFieldNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data item:(id<VZMistItem>)item;
+ (void)bindTextViewNodeSpecs:(TextViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data item:(id<VZMistItem>)item;
+ (void)bindSwitchNodeSpecs:(SwitchNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data item:(id<VZMistItem>)item;
+ (void)bindSegmentedControlNodeSpecs:(SegmentedControlNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data item:(id<VZMistItem>)item;
+ (void)bindPickerNodeSpecs:(PickerNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data item:(id<VZMistItem>)item;
+ (void)bindWebViewNodeSpecs:(WebViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data item:(id<VZMistItem>)item;
+ (void)bindMapViewNodeSpecs:(MapViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(id)data item:(id<VZMistItem>)item;

@end
