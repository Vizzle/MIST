//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class VZTExpressionNode;
@class VZTExpressionContext;
@class VZMist;


@interface VZMistTemplateHelper : NSObject

+ (NSArray *)sliceList:(NSArray *)list forCount:(NSUInteger)count;
+ (UIColor *)colorFromString:(NSString *)string;
+ (id)extractValueForExpression:(id)expression withContext:(VZTExpressionContext *)context;
+ (NSDictionary *)parseExpressionsInTemplate:(NSDictionary *)tpl mistInstance:(VZMist *)mistInstance;
+ (NSAttributedString *)attributedStringFromHtml:(NSString *)html;
+ (UIImage *)imageNamed:(NSString *)imageName;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;


@end
