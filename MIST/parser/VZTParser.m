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


#define next() VZTLexer_next(lexer)
#define VZT_REQUIRE_OPERATOR(op)                                                         \
    if (lexer->token.type == op) {                                                       \
        next();                                                                          \
    }                                                                                    \
    else {                                                                               \
        *error = "error";                                                                \
        return nil;                                                                      \
    }

static inline VZTExpressionNode* vzt_parseExpression(VZTLexer *lexer, const char** error);
VZTExpressionNode *vzt_parsePrimaryExpression(VZTLexer *lexer, const char** error);

static inline bool vzt_parseOperator(VZTLexer *lexer, VZTTokenType type) {
    if (lexer->token.type == type) {
        VZTLexer_next(lexer);
        return type;
    }
    return 0;
}

static inline VZTIdentifierNode * vzt_parseIdentifier(VZTLexer *lexer, const char** error) {
    if (lexer->token.type == VZTTokenTypeId) {
        VZTIdentifierNode *node = [[VZTIdentifierNode alloc] initWithIdentifier:[NSString stringWithUTF8String:lexer->token.string]];
        next();
        return node;
    }
    return nil;
}

/*
 key_value_list2
	: , identifier : expression key_value_list2
	| ε
	;
 */
VZTKeyValueListNode *vzt_parseKeyValueList2(VZTLexer *lexer, const char** error, VZTKeyValueListNode *list) {
    if (vzt_parseOperator(lexer, ',')) {
        VZTExpressionNode *key = vzt_parseExpression(lexer, error);
        if (!key) return nil;
        VZT_REQUIRE_OPERATOR(':');
        VZTExpressionNode *value = vzt_parseExpression(lexer, error);
        if (!value) return nil;
        [list.keyValueList setObject:value forKey:key];
        return vzt_parseKeyValueList2(lexer, error, list);
    }
    return list;
}

/*
 key_value_list
	: identifier : expression key_value_list2
    | ε
	;
 */
VZTKeyValueListNode *vzt_parseKeyValueList(VZTLexer *lexer, const char** error) {
    VZTKeyValueListNode *list = [[VZTKeyValueListNode alloc] init];
    VZTExpressionNode *key = vzt_parseExpression(lexer, error);
    if (!key) return list;
    VZT_REQUIRE_OPERATOR(':');
    VZTExpressionNode *value = vzt_parseExpression(lexer, error);
    if (!value) return nil;
    [list.keyValueList setObject:value forKey:key];
    return vzt_parseKeyValueList2(lexer, error, list);
}

/*
 expression_list2
	: , expression expression_list2
	| ε
	;
 */
NSArray<VZTExpressionNode *> * vzt_parseExpressionList2(VZTLexer *lexer, const char** error, NSMutableArray<VZTExpressionNode *> *list) {
    if (vzt_parseOperator(lexer, ',')) {
        VZTExpressionNode *expression = vzt_parseExpression(lexer, error);
        if (expression) {
            [list addObject:expression];
            return vzt_parseExpressionList2(lexer, error, list);
        } else {
            return nil;
        }
    }
    return list;
}

/*
 expression_list
	: expression expression_list2
    | ε
	;
 */
NSArray<VZTExpressionNode *> * vzt_parseExpressionList(VZTLexer *lexer, const char** error) {
    NSInteger pointer = lexer->pointer;
    VZTToken lookAhead = lexer->lookAhead;
    
    NSMutableArray<VZTExpressionNode *> *list = [[NSMutableArray alloc] init];
    VZTExpressionNode *expression = vzt_parseExpression(lexer, error);
    if (expression) {
        [list addObject:expression];
    } else {
        lexer->pointer = pointer;
        lexer->lookAhead = lookAhead;
        return list;
    }
    return vzt_parseExpressionList2(lexer, error, list);
}

/*
 postfix_expression2
    : [ expression ] postfix_expression2
    | . identifier postfix_expression2
    | . identifier ( expression_list ) postfix_expression2
    | ε
    ;
 */
VZTExpressionNode * vzt_parsePostfixExpression2(VZTLexer *lexer, const char** error, VZTExpressionNode *operand1) {
    if (vzt_parseOperator(lexer, '[')) {
        VZTExpressionNode *operand2 = vzt_parseExpression(lexer, error);
        if (!operand2) return nil;
        VZT_REQUIRE_OPERATOR(']');
        VZTBinaryExpressionNode *binaryExpression = [[VZTBinaryExpressionNode alloc] initWithOperator:'[' operand1:operand1 operand2:operand2];
        return vzt_parsePostfixExpression2(lexer, error, binaryExpression);
    } else if (vzt_parseOperator(lexer, '.')) {
        VZTIdentifierNode *action = vzt_parseIdentifier(lexer, error);
        if (!action) return nil;
        NSArray<VZTExpressionNode *> *parameters;
        if (vzt_parseOperator(lexer, '(')) {
            parameters = vzt_parseExpressionList(lexer, error);
            if (!parameters) return nil;
            VZT_REQUIRE_OPERATOR(')');
        }
        VZTFunctionExpressionNode *function = [[VZTFunctionExpressionNode alloc] initWithTarget:operand1 action:action parameters:parameters];
        return vzt_parsePostfixExpression2(lexer, error, function);
    }
    return operand1;
}

/*
 postfix_expression
    : primary_expression postfix_expression2
    ;
 */
static inline VZTExpressionNode * vzt_parsePostfixExpression(VZTLexer *lexer, const char** error) {
    VZTExpressionNode *expression = vzt_parsePrimaryExpression(lexer, error);
    if (!expression) return nil;
    return vzt_parsePostfixExpression2(lexer, error, expression);
}

typedef enum {
    VZT_BIN_NONE,
    VZT_BIN_ADD,
    VZT_BIN_SUB,
    VZT_BIN_MUL,
    VZT_BIN_DIV,
    VZT_BIN_MOD,
    
    VZT_BIN_AND,
    VZT_BIN_OR,
    
    VZT_BIN_EQ,
    VZT_BIN_NE,
    
    VZT_BIN_GT,
    VZT_BIN_LT,
    VZT_BIN_GE,
    VZT_BIN_LE,
} VZTBinOp;

typedef enum {
    VZT_UN_NONE,
    VZT_UN_NEG,
    VZT_UN_NOT,
} VZTUnOp;

static inline VZTBinOp getBinOp(VZTTokenType type) {
    switch ((int)type) {
        case '+':
            return VZT_BIN_ADD;
        case '-':
            return VZT_BIN_SUB;
        case '*':
            return VZT_BIN_MUL;
        case '/':
            return VZT_BIN_DIV;
        case '%':
            return VZT_BIN_MOD;
        case VZTTokenTypeAnd:
            return VZT_BIN_AND;
        case VZTTokenTypeOr:
            return VZT_BIN_OR;
        case VZTTokenTypeEqual:
            return VZT_BIN_EQ;
        case VZTTokenTypeNotEqual:
            return VZT_BIN_NE;
        case '>':
            return VZT_BIN_GT;
        case '<':
            return VZT_BIN_LT;
        case VZTTokenTypeGreaterOrEqaul:
            return VZT_BIN_GE;
        case VZTTokenTypeLessOrEqaul:
            return VZT_BIN_LE;
        default:
            return VZT_BIN_NONE;
    }
}

static inline VZTUnOp getUnOp(VZTTokenType type) {
    switch ((int)type) {
        case '-':
            return VZT_UN_NEG;
        case '!':
            return VZT_UN_NOT;
        default:
            return VZT_UN_NONE;
    }
}

static const struct {
    char left;
    char right;
} bin_op_priority[] = {
    {0, 0},
    {6, 6}, {6, 6}, {7, 7}, {7, 7}, {7, 7},         // +  -  *  /  %
    {2, 2}, {1, 1},                                 // &&  ||
    {3, 3}, {3, 3}, {3, 3}, {3, 3}, {3, 3}, {3, 3}, // ==  !=  >  <  >=  <=
};

/*
 sub_expression
	: (postfix_expression | unop sub_expression) { binop sub_expression }
 */
VZTExpressionNode* vzt_parseSubExpression(VZTLexer *lexer, const char** error, int priorityLimit) {
    VZTBinOp binOp;
    VZTUnOp unOp;
    
    VZTExpressionNode *exp;
    VZTTokenType type = lexer->token.type;
    unOp = getUnOp(type);
    if (unOp != VZT_UN_NONE) {
        next();
        exp = vzt_parseSubExpression(lexer, error, 8);
        if (!exp) {
            return nil;
        }
        exp = [[VZTUnaryExpressionNode alloc] initWithOperator:type operand:exp];
    }
    else {
        exp = vzt_parsePostfixExpression(lexer, error);
    }
    if (!exp) {
        return nil;
    }
    
    type = lexer->token.type;
    binOp = getBinOp(type);
    while (binOp && bin_op_priority[binOp].left > priorityLimit) {
        next();
        VZTExpressionNode *subexp = vzt_parseSubExpression(lexer, error, bin_op_priority[binOp].right);
        if (!subexp) {
            return nil;
        }
        exp = [[VZTBinaryExpressionNode alloc] initWithOperator:type operand1:exp operand2:subexp];
        type = lexer->token.type;
        binOp = getBinOp(type);
    }
    return exp;
}

/*
 conditional_expression
    : logical_or_expression
    | logical_or_expression ? : conditional_expression
    | logical_or_expression ? expression : conditional_expression
    ;
 */
VZTExpressionNode* vzt_parseConditionalExpression(VZTLexer *lexer, const char** error) {
    VZTExpressionNode *expression = vzt_parseSubExpression(lexer, error, 0);
    if (expression) {
        if (lexer->token.type == '?') {
            next();
            VZTExpressionNode *trueExpression;
            if (!vzt_parseOperator(lexer, ':')) {
                trueExpression = vzt_parseExpression(lexer, error);
                if (!trueExpression) return nil;
                VZT_REQUIRE_OPERATOR(':');
            }
            VZTExpressionNode *falseExpression = vzt_parseConditionalExpression(lexer, error);
            if (!falseExpression) return nil;
            return [[VZTConditionalExpressionNode alloc] initWithCondition:expression trueExpression:trueExpression falseExpression:falseExpression];
        }
        return expression;
    }
    return nil;
}

/*
 expression
    : conditional_expression
    ;
 */
static inline VZTExpressionNode* vzt_parseExpression(VZTLexer *lexer, const char** error) {
    return vzt_parseConditionalExpression(lexer, error);
}

/*
 primary_expression
    : literal                           // string | number | boolean | null
    | ( expression )
    | [ expression_list ]
    | { key_value_list }
    | identifier ( expression_list )
    | identifier
    | lambda_expression                 // identifier -> expression
    ;
 */
VZTExpressionNode *vzt_parsePrimaryExpression(VZTLexer *lexer, const char** error) {
    VZTExpressionNode *expression;
    
    switch ((int)lexer->token.type) {
        case VZTTokenTypeString:
        {
            VZTLiteralNode *node = [[VZTLiteralNode alloc] initWithValue:[NSString stringWithUTF8String:lexer->token.string]];
            next();
            return node;
        }
        case VZTTokenTypeNumber:
        case VZTTokenTypeBoolean:
        {
            VZTLiteralNode *node = [[VZTLiteralNode alloc] initWithValue:@(lexer->token.number)];
            next();
            return node;
        }
        case VZTTokenTypeNull:
        {
            next();
            return [[VZTLiteralNode alloc] initWithValue:nil];
        }
        case '(':
            next();
            expression = vzt_parseExpression(lexer, error);
            VZT_REQUIRE_OPERATOR(')');
            return expression;
        case '[':
        {
            next();
            NSArray *list = vzt_parseExpressionList(lexer, error);
            if (!list) return nil;
            VZT_REQUIRE_OPERATOR(']');
            return [[VZTArrayExpressionNode alloc] initWithExpressionList:list];
        }
        case '{':
        {
            next();
            VZTKeyValueListNode *list = vzt_parseKeyValueList(lexer, error);
            if (!list) return nil;
            VZT_REQUIRE_OPERATOR('}');
            return [[VZTObjectExpressionNode alloc] initWithKeyValueList:list];
        }
        case VZTTokenTypeId:
        {
            VZTIdentifierNode *identifier = vzt_parseIdentifier(lexer, error);
            if (vzt_parseOperator(lexer, '(')) {
                NSArray *list = vzt_parseExpressionList(lexer, error);
                if (!list) return nil;
                VZT_REQUIRE_OPERATOR(')');
                return [[VZTFunctionExpressionNode alloc] initWithTarget:nil action:identifier parameters:list];
            }
            else if (vzt_parseOperator(lexer, VZTTokenTypeArrow)) {
                expression = vzt_parseExpression(lexer, error);
                if (!expression) {
                    *error = "expression is required after '->'";
                    return nil;
                }
                return [[VZTLambdaExpressionNode alloc] initWithParameter:identifier.identifier expression:expression];
            }
            return identifier;
        }
    }
    
    return nil;
}

VZTExpressionNode *vzt_parse(const char* code, const char** error) {
    const char *unusedError;
    if (!error) {
        error = &unusedError;
    }
    VZTLexer *lexer = VZTLexer_new(code);
    VZTLexer_next(lexer);
    VZTExpressionNode *expression = vzt_parseExpression(lexer, error);
    if (lexer->error) {
        *error = lexer->error;
        expression = nil;
    }
    if (lexer->token.type) {
        *error = "parse expression failure";//[NSString stringWithFormat:expression ? @"parse expression failure with redundant token '%@'" : @"unexpected token '%@'", [parser getTokenName:&parser->lexer->lookAhead]];
        expression = nil;
    }
    if (!*error && !expression) {
        *error = "parse expression failure";//[NSString stringWithFormat:@"expression failure near token '%@'", [parser getTokenName:&parser->lexer->lookAhead ?: &parser->lexer->token]];
    }
    VZTLexer_free(lexer);
    return expression;
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
        _lexer = VZTLexer_new(code.UTF8String);
        VZTLexer_next(_lexer);
    }
    return self;
}

- (void)dealloc {
    VZTLexer_free(_lexer);
}

- (NSString *)getTokenName:(VZTToken *)token
{
    return @"";//[_lexer getTokenText:token];
}

- (NSString *)errorDescriptionForRequireToken:(VZTTokenType)type beforeToken:(VZTToken *)token
{
    return [NSString stringWithFormat:@"'%@' is expected%@", vzt_tokenName(type), token ? [NSString stringWithFormat:@" before '%@'", [self getTokenName:token]] : @""];
}

+ (VZTExpressionNode *)parse:(NSString *)code error:(NSError *__autoreleasing _Nullable *)error
{
    const char *err = NULL;
    VZTExpressionNode *exp = vzt_parse(code.UTF8String, &err);
    if (error && err) {
        *error = [NSError errorWithDomain:@"VZTemplateExpression" code:0 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithUTF8String:err]}];
    }
    return exp;
}

@end
