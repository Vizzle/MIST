//
//  VZTParser.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/14.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VZTExpressionNode;


@interface VZTParser : NSObject

+ (VZTExpressionNode *_Nullable)parse:(NSString *_Nonnull)code error:(NSError *_Nullable *_Nullable)error;

@end
