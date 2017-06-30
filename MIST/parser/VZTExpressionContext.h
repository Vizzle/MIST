//
//  VZTExpressionContext.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTSyntaxNode.h"


@interface VZTExpressionContext : VZTSyntaxNode <NSCopying>

- (id)pushVariableWithKey:(NSString *)key value:(id)value;
- (id)pushWeakVariableWithKey:(NSString *)key value:(id)value;
- (void)popVariableWithKey:(NSString *)key;
- (void)pushVariables:(NSDictionary *)variables;
- (void)popVariables:(NSDictionary *)variables;
- (id)valueForKey:(NSString *)key;
- (id)valueForKey:(NSString *)key count:(NSInteger *)count;
- (void)setValue:(id)value forKey:(NSString *)key;
- (void)clear;

@end
