//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VZTExpressionNode;


@interface VZTParser : NSObject

+ (VZTExpressionNode *_Nullable)parse:(NSString *_Nonnull)code error:(NSError *_Nullable *_Nullable)error;

@end
