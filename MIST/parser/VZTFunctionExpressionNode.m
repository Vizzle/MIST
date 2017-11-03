//
//  VZTFunctionExpressionNode.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/16.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTFunctionExpressionNode.h"
#import "VZTIdentifierNode.h"
#import "VZTUtils.h"
#import "VZTLambdaExpressionNode.h"
#import "VZTGlobalFunctions.h"
#import "VZTParser.h"


@implementation VZTFunctionExpressionNode

- (instancetype)initWithTarget:(VZTExpressionNode *)target action:(VZTIdentifierNode *)action parameters:(NSArray<VZTExpressionNode *> *)parameters
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
    if (!_target) {
        typedef id(^BlockType)(id);
        id value = [_action compute:context];
        if ([value isKindOfClass:NSClassFromString(@"NSBlock")]) {
            return ((BlockType)value)([_parameters.firstObject compute:context]);
        }
    }
    id target = _target ? [_target compute:context] : [VZTGlobalFunctions class];
    if (!target) {
        return nil;
    }

    NSString *identifier = _action.identifier;

    if (!_parameters && [target isKindOfClass:[NSDictionary class]]) {
        id value = [target objectForKey:identifier];
        if (value) {
            return value;
        }
    }
    
    if (target == [VZTGlobalFunctions class] && [@"eval" isEqualToString:identifier]) {
        if (_parameters.count != 1) {
            NSLog(@"eval() requires one parameter, but %lu was provided", (unsigned long)_parameters.count);
            return nil;
        }
        NSString *exp = [_parameters.firstObject compute:context];
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

    NSString *selectorName = identifier;
    if ([selectorName rangeOfString:@"_"].length > 0) {
        selectorName = [[selectorName stringByReplacingOccurrencesOfString:@"_" withString:@":"] stringByReplacingOccurrencesOfString:@"::" withString:@"_"];
    }

    NSUInteger numberOfColons = [self numberOfCharacter:':' inString:selectorName];
    if (_parameters.count > numberOfColons) {
        selectorName = [selectorName stringByPaddingToLength:selectorName.length + _parameters.count - numberOfColons withString:@":" startingAtIndex:0];
    }

    SEL selector;
    SEL vzt_selector = NSSelectorFromString([@"vzt_" stringByAppendingString:selectorName]);
    if ([target respondsToSelector:vzt_selector]) {
        selector = vzt_selector;
    } else {
        selector = NSSelectorFromString(selectorName);
        if (![target respondsToSelector:selector]) {
//            NSLog(@"unrecognized selector '%@' sent to instance of '%@'", selectorName, NSStringFromClass([target class]));
            return nil;
        }
    }

    return [self invokeMethodWithTarget:target selector:selector context:context];
}

- (id)invokeMethodWithTarget:(id)target selector:(SEL)selector context:(VZTExpressionContext *)context
{
    if (_parameters.count > 0) {
        NSMutableArray *arguments = [NSMutableArray array];
        for (VZTExpressionNode *expression in _parameters) {
            [arguments addObject:[expression compute:context] ?: [VZTNull null]];
        }
        return vzt_invokeMethod(target, selector, arguments);
    }
    else {
        return vzt_invokeMethod(target, selector, nil);
    }
}

@end
