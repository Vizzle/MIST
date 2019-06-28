//
//  Copyright © 2016年 Vizlab. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "VZMistTemplateAction.h"
#import "VZMistListItem.h"

@interface VZMistTemplateAnimation : NSObject

@property (nonatomic, assign) NSString *key;
@property (nonatomic, strong) CAAnimation *animation;
@property (nonatomic) CFAbsoluteTime delay;
@property (nonatomic) NSInteger viewTag;
@property (nonatomic, strong) NSDictionary *startEvent;
@property (nonatomic, strong) NSDictionary *endEvent;
@property (nonatomic, weak) id<VZMistItem> item;
@property (nonatomic, strong) VZTExpressionContext *context;

+ (instancetype)animationWithDict:(NSDictionary *)dict item:(id<VZMistItem>)item;

- (void)runWithView:(UIView *)view;

@end
