//
//  VZTFunctionExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTFunctionExpressionNode.h"
#import "VZTIdentifierNode.h"
#import "VZTExpressionListNode.h"
#import "VZTUtils.h"
#import "VZTLambdaExpressionNode.h"
#import "VZTGlobalFunctions.h"
#import "VZTParser.h"


@implementation VZTFunctionExpressionNode

- (instancetype)initWithTarget:(VZTExpressionNode *)target action:(VZTIdentifierNode *)action parameters:(VZTExpressionListNode *)parameters
{
    if (self = [super init]) {
        _target = target;
        _action = action;
        _parameters = parameters;
    }
    return self;
}

- (NSUInteger)numberOfCharacter:(unichar)c inString:(NSString *)str
{
    NSUInteger n = 0;
    for (NSUInteger i = 0, len = str.length; i < len; i++) {
        if ([str characterAtIndex:i] == c) {
            n++;
        }
    }
    return n;
}

- (id)compute:(VZTExpressionContext *)context
{
    id target = _target ? [_target compute:context] : [VZTGlobalFunctions class];
    if (!target) {
        return nil;
    }

    NSString *identifier = _action.identifier;

    if (!_parameters.expressionList && [target isKindOfClass:[NSDictionary class]]) {
        id value = [target objectForKey:identifier];
        if (value) {
            return value;
        }
    }
    
    if ([@"eval" isEqualToString:identifier] && target == [VZTGlobalFunctions class]) {
        if (_parameters.expressionList.count != 1) {
            NSLog(@"eval() requires one parameter, but %lu was provided", (unsigned long)_parameters.expressionList.count);
            return nil;
        }
        NSString *exp = [_parameters.expressionList.firstObject compute:context];
        if (![exp isKindOfClass:[NSString class]]) {
            NSLog(@"eval() requires string parameter, but %@ was provided", NSStringFromClass([exp class]));
            return nil;
        }
        NSError *error;
        VZTExpressionNode *node = [VZTParser parse:exp error:&error];
        if (error) {
            NSLog(@"eval(): parsing error, expression: %@", exp);
            return nil;
        }
        return [node compute:context];
    }

    NSString *selectorName = [[[identifier stringByReplacingOccurrencesOfString:@"__" withString:@"$"] stringByReplacingOccurrencesOfString:@"_" withString:@":"] stringByReplacingOccurrencesOfString:@"$" withString:@"_"];

    NSUInteger numberOfColons = [self numberOfCharacter:':' inString:selectorName];
    if (_parameters.expressionList.count > numberOfColons) {
        selectorName = [selectorName stringByPaddingToLength:selectorName.length + _parameters.expressionList.count - numberOfColons withString:@":" startingAtIndex:0];
    }

    SEL selector = NSSelectorFromString(selectorName);
    SEL vzt_selector = NSSelectorFromString([@"vzt_" stringByAppendingString:selectorName]);
    if ([target respondsToSelector:vzt_selector]) {
        selector = vzt_selector;
    } else if (![target respondsToSelector:selector]) {
        //        NSLog(@"unrecognized selector '%@' sent to instance of '%@'", selectorName, NSStringFromClass([target class]));
        return nil;
    }

    return [self invokeMethodWithTarget:target selector:selector context:context];
}

- (id)invokeMethodWithTarget:(id)target selector:(SEL)selector context:(VZTExpressionContext *)context
{
    NSMutableArray *arguments = [NSMutableArray array];
    NSMutableArray *lambdaParameters = [NSMutableArray array];
    for (VZTExpressionNode *expression in _parameters.expressionList) {
        if ([expression isKindOfClass:[VZTLambdaExpressionNode class]]) {
            NSString *parameter = ((VZTLambdaExpressionNode *)expression).parameter;
            [lambdaParameters addObject:parameter];
            [context pushVariableWithKey:parameter value:nil];
        }
        [arguments addObject:[expression compute:context] ?: [VZTNull null]];
    }

    id value = vzt_invokeMethod(target, selector, arguments);

    for (NSString *parameter in lambdaParameters) {
        [context popVariableWithKey:parameter];
    }

    return value;
}

@end
