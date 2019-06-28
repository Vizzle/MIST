//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VZMistItem.h"


@interface VZMistTemplateController : NSObject

@property (nonatomic, weak, readonly) id<VZMistItem> item;

- (instancetype)initWithItem:(id<VZMistItem>)item;

- (void)didLoadTemplate;
- (void)didReload;
- (id)initialState;

- (UIView *)viewWithTag:(NSInteger)tag;

- (void)updateState:(NSDictionary *)stateChanges;
- (void)runAction:(NSString *)action;
- (void)runAction:(NSString *)action withParams:(NSDictionary *)params;
- (void)showPopover:(NSDictionary *)params;
- (void)dismiss;

@end
