//
//  VZMistTemplateAction.h
//  Pods
//
//  Created by Sleen on 2017/6/26.
//
//

#import <Foundation/Foundation.h>

#import "VZMistItem.h"
#import "VZTExpressionContext.h"

@class VZMistTemplateAction;
typedef void(^VZMistTemplateActionBlock)(id value);
typedef void(^VZMistTemplateActionRegisterBlock)(VZMistTemplateAction *action);

@interface VZMistTemplateAction : NSObject

@property (nonatomic, strong, readonly) NSString *type;
@property (nonatomic, weak, readonly) id<VZMistItem> item;
@property (nonatomic, weak, readonly) id sender;
@property (nonatomic, strong, readonly) VZMistTemplateActionBlock success;
@property (nonatomic, strong, readonly) VZMistTemplateActionBlock error;
@property (nonatomic, strong, readonly) NSDictionary *params;

+ (instancetype)actionWithDictionary:(NSDictionary *)dictionary expressionContext:(VZTExpressionContext *)context item:(id<VZMistItem>)item;
+ (void)registerActionWithName:(NSString *)name block:(VZMistTemplateActionRegisterBlock)block;
- (void)runWithSender:(id)sender;

@end
