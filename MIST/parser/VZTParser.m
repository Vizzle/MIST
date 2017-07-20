//
//  VZTParser.m
//  VZFlexEditor
//
//  Created by Sleen on 16/4/14.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import "VZTParser.h"
#import "VZTLexer.h"
#import "VZTOperatorNode.h"
#import "VZTExpressionNode.h"
#import "VZTKeyValueListNode.h"
#import "VZTLiteralNode.h"
#import "VZTIdentifierNode.h"
#import "VZTUnaryExpressionNode.h"
#import "VZTBinaryExpressionNode.h"
#import "VZTConditionalExpressionNode.h"
#import "VZTLambdaExpressionNode.h"
#import "VZTFunctionExpressionNode.h"
#import "VZTArrayExpressionNode.h"
#import "VZTObjectExpressionNode.h"

#define VZT_ERROR(...) [NSError errorWithDomain:@"VZTemplateExpression" code:0 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:__VA_ARGS__]}]
#define VZT_RETURE(...)                                   \
    {                                                     \
        _error = [NSString stringWithFormat:__VA_ARGS__]; \
        return nil;                                       \
    }
#define VZT_REQUIRE_OPERATOR(op)                                                         \
    if (![self parseOperator:op]) {                                                      \
        _error = [self errorDescriptionForRequireToken:op beforeToken:_lexer.lookAhead]; \
        return nil;                                                                      \
    }


@implementation VZTParser
{
    VZTLexer *_lexer;
    NSString *_error;
}

- (instancetype)init
{
    NSAssert(NO, @"-[VZTParser init] is not the designated initializer, use +[VZTParser parse:error:] to parse an expression");
    return nil;
}

- (instancetype)initWithCode:(NSString *)code
{
    if (self = [super init]) {
        _lexer = [[VZTLexer alloc] initWithString:code];
    }
    return self;
}

- (NSString *)getTokenName:(VZTToken *)token
{
    return [_lexer.source substringWithRange:token.range];
}

- (NSString *)errorDescriptionForRequireToken:(NSString *)text beforeToken:(VZTToken *)token
{
    return [NSString stringWithFormat:@"'%@' is expected%@", text, token ? [NSString stringWithFormat:@" before '%@'", [self getTokenName:token]] : @""];
}

+ (VZTExpressionNode *)parse:(NSString *)code error:(NSError *__autoreleasing _Nullable *)error
{
    if (code.length == 0) {
        if (error) {
            *error = VZT_ERROR(@"empty expression.");
        }
        return nil;
    }

    VZTParser *parser = [[VZTParser alloc] initWithCode:code];
    VZTExpressionNode *expression = [parser parseExpression];
    if (parser->_lexer.error) {
        parser->_error = parser->_lexer.error;
        expression = nil;
    }
    if (parser->_lexer.lookAhead) {
        parser->_error = [NSString stringWithFormat:expression ? @"parse expression failure with redundant token '%@'" : @"unexpected token '%@'", [parser getTokenName:parser->_lexer.lookAhead]];
        expression = nil;
    }
    if (!parser->_error && !expression) {
        parser->_error = [NSString stringWithFormat:@"expression failure near token '%@'", [parser getTokenName:parser->_lexer.lookAhead ?: parser->_lexer.lastToken]];
    }
    if (parser->_error) {
        if (error) {
            *error = VZT_ERROR(@"%@", parser->_error);
        }
        expression = nil;
    }
    return expression;
}

- (BOOL)lookOperator:(NSString *) operator atIndex:(NSInteger)index
{
    VZTToken *token = [_lexer lookAhead:index];
    return token.type == VZTTokenTypeOperator && [token.token isEqualToString:operator];
}

- (BOOL)lookOperator:(NSString *) operator
{
    return [self lookOperator:operator atIndex:0];
}

- (VZTOperatorNode *)parseOperator:(NSString *) operator
{
    if ([self lookOperator:operator]) {
        return [[VZTOperatorNode alloc] initWithOperator:_lexer.nextToken.token];
    }
    return nil;
}

- (VZTIdentifierNode *)parseIdentifier
{
    if (_lexer.lookAhead.type == VZTTokenTypeId && ![@"true" isEqualToString:_lexer.lookAhead.token] && ![@"false" isEqualToString:_lexer.lookAhead.token]) {
        return [[VZTIdentifierNode alloc] initWithIdentifier:_lexer.nextToken.token];
    }
    return nil;
}

- (VZTLiteralNode *)parseLiteral
{
    if (_lexer.lookAhead.type == VZTTokenTypeNumber) {
        return [[VZTLiteralNode alloc] initWithValue:@(strtod(_lexer.nextToken.token.UTF8String, NULL))];
    } else if (_lexer.lookAhead.type == VZTTokenTypeString) {
        return [[VZTLiteralNode alloc] initWithValue:_lexer.nextToken.token];
    } else if (_lexer.lookAhead.type == VZTTokenTypeId) {
        NSString *token = _lexer.lookAhead.token;
        if ([@"nil" isEqualToString:token] || [@"null" isEqualToString:token]) {
            [_lexer nextToken];
            return [[VZTLiteralNode alloc] initWithValue:nil];
        } else if ([@"true" isEqualToString:token]) {
            [_lexer nextToken];
            return [[VZTLiteralNode alloc] initWithValue:@YES];
        } else if ([@"false" isEqualToString:token]) {
            [_lexer nextToken];
            return [[VZTLiteralNode alloc] initWithValue:@NO];
        }
    }
    return nil;
}

/*
 expression
    : conditional_expression
    ;
 */
- (VZTExpressionNode *)parseExpression
{
    return [self parseConditionalExpression];
}

/*
 conditional_expression
    : logical_or_expression
    | logical_or_expression ? : conditional_expression
    | logical_or_expression ? expression : conditional_expression
    ;
 */
- (VZTExpressionNode *)parseConditionalExpression
{
    VZTExpressionNode *expression = [self parseLogicalOrExpression];
    if (expression) {
        if ([self parseOperator:@"?"]) {
            VZTExpressionNode *trueExpression;
            if (![self parseOperator:@":"]) {
                trueExpression = [self parseExpression];
                if (!trueExpression) return nil;
                VZT_REQUIRE_OPERATOR(@":");
            }
            VZTExpressionNode *falseExpression = [self parseConditionalExpression];
            if (!falseExpression) return nil;
            return [[VZTConditionalExpressionNode alloc] initWithCondition:expression trueExpression:trueExpression falseExpression:falseExpression];
        }
        return expression;
    }
    return nil;
}

/*
 logical_or_expression
	: logical_and_expression logical_or_expression2
 */
- (VZTExpressionNode *)parseLogicalOrExpression
{
    VZTExpressionNode *expression = [self parseLogicalAndExpression];
    if (!expression) return nil;
    return [self parseLogicalOrExpression2:expression];
}

/*
 logical_or_expression2
	: || logical_and_expression logical_or_expression2
	| ε
	;
 */
- (VZTExpressionNode *)parseLogicalOrExpression2:(VZTExpressionNode *)operand1
{
    VZTOperatorNode *operator;
    if ((operator= [self parseOperator:@"||"])) {
        VZTExpressionNode *operand2 = [self parseLogicalAndExpression];
        if (!operand2) return nil;
        VZTBinaryExpressionNode *expression = [[VZTBinaryExpressionNode alloc] initWithOperator:operator.operator operand1:operand1 operand2:operand2];
        return [self parseLogicalOrExpression2:expression];
    }
    return operand1;
}

/*
 logical_and_expression
	: equality_expression logical_and_expression2
 */
- (VZTExpressionNode *)parseLogicalAndExpression
{
    VZTExpressionNode *expression = [self parseEqualityExpression];
    if (!expression) return nil;
    return [self parseLogicalAndExpression2:expression];
}

/*
 logical_and_expression2
	: && equality_expression logical_and_expression2
	| ε
	;
 */
- (VZTExpressionNode *)parseLogicalAndExpression2:(VZTExpressionNode *)operand1
{
    VZTOperatorNode *operator;
    if ((operator= [self parseOperator:@"&&"])) {
        VZTExpressionNode *operand2 = [self parseEqualityExpression];
        if (!operand2) return nil;
        VZTBinaryExpressionNode *expression = [[VZTBinaryExpressionNode alloc] initWithOperator:operator.operator operand1:operand1 operand2:operand2];
        return [self parseLogicalAndExpression2:expression];
    }
    return operand1;
}

/*
 equality_expression
	: relational_expression equality_expression2
	;
 */
- (VZTExpressionNode *)parseEqualityExpression
{
    VZTExpressionNode *expression = [self parseRelationalExpression];
    if (!expression) return nil;
    return [self parseEqualityExpression2:expression];
}

/*
 equality_expression2
	: == relational_expression equality_expression2
	: != relational_expression equality_expression2
	: ε
	;
 */
- (VZTExpressionNode *)parseEqualityExpression2:(VZTExpressionNode *)operand1
{
    VZTOperatorNode *operator;
    if ((operator= [self parseOperator:@"=="]) || (operator= [self parseOperator:@"!="])) {
        VZTExpressionNode *operand2 = [self parseRelationalExpression];
        if (!operand2) return nil;
        VZTBinaryExpressionNode *expression = [[VZTBinaryExpressionNode alloc] initWithOperator:operator.operator operand1:operand1 operand2:operand2];
        return [self parseEqualityExpression2:expression];
    }
    return operand1;
}

/*
 relational_expression
	: additive_expression relational_expression2
	;
 */
- (VZTExpressionNode *)parseRelationalExpression
{
    VZTExpressionNode *expression = [self parseAdditiveExpression];
    if (!expression) return nil;
    return [self parseRelationalExpression2:expression];
}

/*
 relational_expression2
	: < additive_expression relational_expression2
	| > additive_expression relational_expression2
	| <= additive_expression relational_expression2
	| >= additive_expression relational_expression2
	| ε
	;
 */
- (VZTExpressionNode *)parseRelationalExpression2:(VZTExpressionNode *)operand1
{
    VZTOperatorNode *operator;
    if ((operator= [self parseOperator:@"<"]) || (operator= [self parseOperator:@">"]) || (operator= [self parseOperator:@"<="]) || (operator= [self parseOperator:@">="])) {
        VZTExpressionNode *operand2 = [self parseAdditiveExpression];
        if (!operand2) return nil;
        VZTBinaryExpressionNode *expression = [[VZTBinaryExpressionNode alloc] initWithOperator:operator.operator operand1:operand1 operand2:operand2];
        return [self parseRelationalExpression2:expression];
    }
    return operand1;
}

/*
 additive_expression
    : multiplicative_expression additive_expression2
    ;
 */
- (VZTExpressionNode *)parseAdditiveExpression
{
    VZTExpressionNode *expression = [self parseMultiplicativeExpression];
    if (!expression) return nil;
    return [self parseAdditiveExpression2:expression];
}

/*
 additive_expression2
    : + multiplicative_expression additive_expression2
    | - multiplicative_expression additive_expression2
	| ε
    ;
 */
- (VZTExpressionNode *)parseAdditiveExpression2:(VZTExpressionNode *)operand1
{
    VZTOperatorNode *operator;
    if ((operator= [self parseOperator:@"+"]) || (operator= [self parseOperator:@"-"])) {
        VZTExpressionNode *operand2 = [self parseMultiplicativeExpression];
        if (!operand2) return nil;
        VZTBinaryExpressionNode *expression = [[VZTBinaryExpressionNode alloc] initWithOperator:operator.operator operand1:operand1 operand2:operand2];
        return [self parseAdditiveExpression2:expression];
    }
    return operand1;
}

/*
 multiplicative_expression
    : unary_expression multiplicative_expression2
    ;
 */
- (VZTExpressionNode *)parseMultiplicativeExpression
{
    VZTExpressionNode *expression = [self parseUnaryExpression];
    if (!expression) return nil;
    return [self parseMultiplicativeExpression2:expression];
}

/*
 multiplicative_expression2
    : * unary_expression multiplicative_expression2
    | / unary_expression multiplicative_expression2
    | % unary_expression multiplicative_expression2
	| ε
    ;
 */
- (VZTExpressionNode *)parseMultiplicativeExpression2:(VZTExpressionNode *)operand1
{
    VZTOperatorNode *operator;
    if ((operator= [self parseOperator:@"*"]) || (operator= [self parseOperator:@"/"]) || (operator= [self parseOperator:@"%"])) {
        VZTExpressionNode *operand2 = [self parseUnaryExpression];
        if (!operand2) return nil;
        VZTBinaryExpressionNode *expression = [[VZTBinaryExpressionNode alloc] initWithOperator:operator.operator operand1:operand1 operand2:operand2];
        return [self parseMultiplicativeExpression2:expression];
    }
    return operand1;
}

/*
 unary_expression
    : postfix_expression
    | unary_operator unary_expression
    ;
 */
- (VZTExpressionNode *)parseUnaryExpression
{
    VZTOperatorNode *operator= [self parseUnaryOperator];
    if (operator) {
        VZTExpressionNode *expression = [self parseUnaryExpression];
        if (!expression) return nil;
        return [[VZTUnaryExpressionNode alloc] initWithOperator:operator.operator operand:expression];
    }

    return [self parsePostfixExpression];
}

/*
 unary_operator
    : !
    : -
    ;
 */
- (VZTOperatorNode *)parseUnaryOperator
{
    return [self parseOperator:@"!"] ?: [self parseOperator:@"-"];
}

/*
 postfix_expression
    : primary_expression postfix_expression2
    ;
 */
- (VZTExpressionNode *)parsePostfixExpression
{
    VZTExpressionNode *expression = [self parsePrimaryExpression];
    if (!expression) return nil;
    return [self parsePostfixExpression2:expression];
}

/*
 postfix_expression2
    : [ expression ] postfix_expression2
    | . identifier postfix_expression2
    | . identifier ( expression_list ) postfix_expression2
    | ε
    ;
 */
- (VZTExpressionNode *)parsePostfixExpression2:(VZTExpressionNode *)operand1
{
    if ([self parseOperator:@"["]) {
        VZTExpressionNode *operand2 = [self parseExpression];
        if (!operand2) return nil;
        VZT_REQUIRE_OPERATOR(@"]");
        VZTBinaryExpressionNode *binaryExpression = [[VZTBinaryExpressionNode alloc] initWithOperator:@"[" operand1:operand1 operand2:operand2];
        return [self parsePostfixExpression2:binaryExpression];
    } else if ([self parseOperator:@"."]) {
        VZTIdentifierNode *action = [self parseIdentifier];
        if (!action) return nil;
        NSArray<VZTExpressionNode *> *parameters;
        if ([self parseOperator:@"("]) {
            parameters = [self parseExpressionList];
            if (!parameters) return nil;
            VZT_REQUIRE_OPERATOR(@")");
        }
        VZTFunctionExpressionNode *function = [[VZTFunctionExpressionNode alloc] initWithTarget:operand1 action:action parameters:parameters];
        return [self parsePostfixExpression2:function];
    }
    return operand1;
}

/*
 expression_list
	: expression expression_list2
    | ε
	;
 */
- (NSArray<VZTExpressionNode *> *)parseExpressionList
{
    NSInteger pointer = _lexer.pointer;
    NSMutableArray *lookAheadStack = _lexer.lookAheadStack.mutableCopy;
    
    NSMutableArray<VZTExpressionNode *> *list = [[NSMutableArray alloc] init];
    VZTExpressionNode *expression = [self parseExpression];
    if (expression) {
        [list addObject:expression];
    } else {
        _lexer.pointer = pointer;
        _lexer.lookAheadStack = lookAheadStack;
        return list;
    }
    return [self parseExpressionList2:list];
}

/*
 expression_list2
	: , expression expression_list2
	| ε
	;
 */
- (NSArray<VZTExpressionNode *> *)parseExpressionList2:(NSMutableArray<VZTExpressionNode *> *)list
{
    if ([self parseOperator:@","]) {
        VZTExpressionNode *expression = [self parseExpression];
        if (expression) {
            [list addObject:expression];
            return [self parseExpressionList2:list];
        } else {
            return nil;
        }
    }
    return list;
}

/*
 key_value_list
	: identifier : expression key_value_list2
    | ε
	;
 */
- (VZTKeyValueListNode *)parseKeyValueList
{
    VZTKeyValueListNode *list = [[VZTKeyValueListNode alloc] init];
    VZTExpressionNode *key = [self parseExpression];
    if (!key) return list;
    VZT_REQUIRE_OPERATOR(@":");
    VZTExpressionNode *value = [self parseExpression];
    if (!value) return nil;
    [list.keyValueList setObject:value forKey:key];
    return [self parseKeyValueList2:list];
}

/*
 key_value_list2
	: , identifier : expression key_value_list2
	| ε
	;
 */
- (VZTKeyValueListNode *)parseKeyValueList2:(VZTKeyValueListNode *)list
{
    if ([self parseOperator:@","]) {
        VZTExpressionNode *key = [self parseExpression];
        if (!key) return nil;
        VZT_REQUIRE_OPERATOR(@":");
        VZTExpressionNode *value = [self parseExpression];
        if (!value) return nil;
        [list.keyValueList setObject:value forKey:key];
        return [self parseKeyValueList2:list];
    }
    return list;
}

/*
 primary_expression
    : literal
    | ( expression )
    | [ expression_list ]
    | { key_value_list }
    | identifier ( expression_list )
    | identifier
    | lambda_expression
    ;
 */
- (VZTExpressionNode *)parsePrimaryExpression
{
    VZTExpressionNode *expression;
    if ((expression = [self parseLiteral])) {
        return expression;
    } else if ([self parseOperator:@"("]) {
        expression = [self parseExpression];
        VZT_REQUIRE_OPERATOR(@")");
        return expression;
    } else if ([self parseOperator:@"["]) {
        NSArray *list = [self parseExpressionList];
        if (!list) return nil;
        VZT_REQUIRE_OPERATOR(@"]");
        return [[VZTArrayExpressionNode alloc] initWithExpressionList:list];
    } else if ([self parseOperator:@"{"]) {
        VZTKeyValueListNode *list = [self parseKeyValueList];
        if (!list) return nil;
        VZT_REQUIRE_OPERATOR(@"}");
        return [[VZTObjectExpressionNode alloc] initWithKeyValueList:list];
    } else if ([self lookOperator:@"->" atIndex:1]) {
        return [self parseLambdaExpression];
    }

    VZTIdentifierNode *identifier = [self parseIdentifier];
    if ([self parseOperator:@"("]) {
        NSArray *list = [self parseExpressionList];
        if (!list) return nil;
        VZT_REQUIRE_OPERATOR(@")");
        return [[VZTFunctionExpressionNode alloc] initWithTarget:nil action:identifier parameters:list];
    }
    return identifier;
}

/*
 lambda_expression
    : identifier -> expression
    ;
 */
- (VZTLambdaExpressionNode *)parseLambdaExpression
{
    VZTIdentifierNode *parameter = [self parseIdentifier];
    if (!parameter) VZT_RETURE(@"identifier is required before '->'");
    VZT_REQUIRE_OPERATOR(@"->");
    VZTExpressionNode *expression = [self parseExpression];
    if (!expression) VZT_RETURE(@"expression is required after '->'");
    return [[VZTLambdaExpressionNode alloc] initWithParameter:parameter.identifier expression:expression];
}

@end
