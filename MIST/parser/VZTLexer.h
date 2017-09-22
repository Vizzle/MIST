//
//  VZTLexer.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/14.
//  Copyright © 2016年 O2O. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, VZTTokenType) {
    VZTTokenTypeString = 256,
    VZTTokenTypeNumber,
    VZTTokenTypeBoolean,
    VZTTokenTypeNull,
    VZTTokenTypeId,
    VZTTokenTypeAnd,
    VZTTokenTypeOr,
    VZTTokenTypeEqual,
    VZTTokenTypeNotEqual,
    VZTTokenTypeGreaterOrEqaul,
    VZTTokenTypeLessOrEqaul,
    VZTTokenTypeArrow,
    VZTTokenTypeUnknown,
};

typedef struct {
    VZTTokenType type;
    size_t offset;
    size_t length;
    union {
        const char* string;
        double number;
    };
} VZTToken;

//typedef struct VZTVector;

typedef struct {
    const char* source;
    size_t length;
    size_t pointer;
    char c;
    size_t line;
    const char* error;
    VZTToken token;
    VZTToken lookAhead;
    struct VZTVector* buffer;
} VZTLexer;

VZTLexer * VZTLexer_new(const char* source);
void VZTLexer_free(VZTLexer *lexer);
void VZTLexer_next(VZTLexer *lexer);
void VZTLexer_lookAhead(VZTLexer *lexer);

NSString *vzt_tokenName(VZTTokenType type);

#ifdef __cplusplus
}
#endif
