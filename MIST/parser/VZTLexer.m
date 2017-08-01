//
//  VZTLexer.cpp
//  VZFlexEditor
//
//  Created by Sleen on 16/4/14.
//  Copyright © 2016年 O2O. All rights reserved.
//

#include "VZTLexer.h"


typedef struct VZTVector {
    char *data;
    size_t size;
    size_t capacity;
    
} VZTVector;

VZTVector *VZTVector_new() {
    VZTVector *vector = (VZTVector *)malloc(sizeof(VZTVector));
    vector->size = 0;
    vector->capacity = 8;
    vector->data = malloc(sizeof(vector->capacity));
    return vector;
}

void VZTVector_push(VZTVector *vector, const char *data, size_t len) {
    vector->size += len;
    if (vector->size > vector->capacity) {
        char *oldData = vector->data;
        vector->capacity = vector->size * 1.5;
        vector->data = malloc(vector->capacity);
        memcpy(vector->data, oldData, vector->size - len);
        free(oldData);
    }
    memcpy(vector->data + vector->size - len, data, len);
}

#define VZTVector_free(vector) do { \
    free(vector->data);             \
    free(vector);                   \
    vector = NULL;                  \
} while(0)


VZTVector * _vzt_format(const char *fmt, va_list args) {
    VZTVector *dst = VZTVector_new();
    for (;;) {
        const char *pc = strchr(fmt, '%');
        if (pc == NULL) {
            break;
        }
        
        VZTVector_push(dst, fmt, pc - fmt);
        
        switch (pc[1]) {
            case 'c':
            {
                char c = va_arg(args, int);
                VZTVector_push(dst, &c, 1);
                break;
            }
            case 's':
            {
                const char* str = va_arg(args, char *);
                VZTVector_push(dst, str, strlen(str));
                break;
            }
            default:
                continue;
        }
        
        fmt = pc + 2;
    }
    
    VZTVector_push(dst, fmt, strlen(fmt));
    static const char zero = 0;
    VZTVector_push(dst, &zero, 1);
    return dst;
}

VZTVector * vzt_format(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    VZTVector *ret = _vzt_format(fmt, args);
    va_end(args);
    return ret;
}


const char *const vzt_tokenNames[] = {
    "string",   // VZTTokenTypeString = 256,
    "number",   // VZTTokenTypeNumber,
    "boolean",  // VZTTokenTypeBoolean,
    "null",     // VZTTokenTypeNull,
    "id",       // VZTTokenTypeId,
    "&&",       // VZTTokenTypeAnd,
    "||",       // VZTTokenTypeOr,
    "==",       // VZTTokenTypeEqual,
    "!=",       // VZTTokenTypeNotEqual,
    ">=",       // VZTTokenTypeGreaterOrEqaul,
    "<=",       // VZTTokenTypeLessOrEqaul,
    "->",       // VZTTokenTypeArrow,
};



#define next(lexer)     (lexer->c = lexer->source[++lexer->pointer])
#define isNewLine(c)    (c == '\r' || c == '\n')
#define isQuote(c)    (c == '\'' || c == '"')

void _newline(VZTLexer *lexer) {
    char old = lexer->c;
    assert(isNewLine(old));
    next(lexer);
    if (isNewLine(lexer->c) && lexer->c != old) {
        next(lexer);
    }
    lexer->line++;
}

void _readString(VZTLexer *lexer, VZTToken *token) {
    char quote = lexer->c;
    assert(isQuote(quote));
    
    next(lexer);
    size_t start = lexer->pointer;
    size_t segment_start = start;
    size_t segment_len = 0;
#define PUSH_CURRENT_SEGMENT                                                    \
if (segment_len > 0) {                                                          \
    VZTVector_push(lexer->buffer, lexer->source + segment_start, segment_len);  \
    segment_len = 0;                                                            \
}                                                                               \
segment_start = lexer->pointer + 1;
#define FREE_CHARS() lexer->buffer->size = 0;
    
    while (lexer->c != quote) {
        switch (lexer->c) {
            case 0:
                lexer->error = "unclosed string literal";
                FREE_CHARS();
                return;
            case '\n':
            case '\r':
                _newline(lexer);
                lexer->error = "unclosed string literal";
                FREE_CHARS();
                return;
            case '\\':
            {
                next(lexer);
                char esc = 0;
                switch (lexer->c) {
                    case '"':
                        esc = '"';
                        break;
                    case '\'':
                        esc = '\'';
                        break;
                    case '\\':
                        esc = '\\';
                        break;
                    case '/':
                        esc = '/';
                        break;
                    case 'b':
                        esc = '\b';
                        break;
                    case 'f':
                        esc = '\f';
                        break;
                    case 'n':
                        esc = '\n';
                        break;
                    case 'r':
                        esc = '\r';
                        break;
                    case 't':
                        esc = '\t';
                        break;
                    case 'u':
                    {
                        int n = 4;
                        unichar unicode = 0;
                        bool valid = true;
                        do {
                            next(lexer);
                            char c = lexer->c;
                            int num;
                            if (c >= '0' && c <='9') {
                                num = c - '0';
                            }
                            else if (c >= 'a' && c <= 'f') {
                                num = c - 'a' + 10;
                            }
                            else if (c >= 'A' && c <= 'F') {
                                num = c - 'A' + 10;
                            }
                            else {
                                valid = false;
                                break;
                            }
                            unicode = unicode * 16 + num;
                        } while (--n > 0 && lexer->c);
                        if (!valid) {
                            lexer->error = "invalid unicode sequence in string";
                            lexer->pointer -= 4 - n + 1;
                            lexer->c = 'u';
                            continue;
                        }
                        NSString *unicodeStr = [NSString stringWithCharacters:&unicode length:1];
                        PUSH_CURRENT_SEGMENT
                        const char *unicodeChars = unicodeStr.UTF8String;
                        VZTVector_push(lexer->buffer, unicodeChars, strlen(unicodeChars));
                        next(lexer);
                        continue;
                    }
                    default:
                        if (lexer->c == '\n' || lexer->c == 0) {
                            lexer->error = "unclosed string literal";
                        }
                        else {
                            lexer->error = "invalid escaped character in string";
                        }
                        continue;
                }
                
                PUSH_CURRENT_SEGMENT
                next(lexer);
                VZTVector_push(lexer->buffer, &esc, 1);
                break;
            }
            default:
                if (iscntrl(lexer->c)) {
                    lexer->error = "invalid characters in string. control characters must be escaped";
                }
                segment_len++;
                next(lexer);
                break;
        }
    }
    assert(lexer->c == quote);
    next(lexer);
    if (lexer->buffer) {
        PUSH_CURRENT_SEGMENT
        token->string = strndup(lexer->buffer->data, lexer->buffer->size);
        FREE_CHARS();
    }
    else {
        token->string = strndup(lexer->source + start, segment_len);
    }
}

void _readNumber(VZTLexer *lexer, VZTToken *token) {
    typedef enum {
        StateStart,
        StateNonzero,
        StateDot,
        StateFractionalStart,
        StateFractional,
        StateExponentMark,
        StateExponentSign,
        StateExponentValueStart,
        StateExponentValue,
        StateSuccess,
        StateError,
    } NumberState;
    
    NumberState state = StateStart;
    size_t start = lexer->pointer;
    
    while (state != StateSuccess && state != StateError) {
        switch (state) {
            case StateStart:
                if (lexer->c == '0') {
                    state = StateDot;
                    next(lexer);
                }
                else if (lexer->c >= '1' && lexer->c <= '9') {
                    state = StateNonzero;
                    next(lexer);
                }
                else {
                    state = StateError;
                }
                break;
            case StateNonzero:
                if (lexer->c >= '0' && lexer->c <= '9') {
                    next(lexer);
                }
                else {
                    state = StateDot;
                }
                break;
            case StateDot:
                if (lexer->c == '.') {
                    state = StateFractionalStart;
                    next(lexer);
                }
                else {
                    state = StateExponentMark;
                }
                break;
            case StateFractionalStart:
                if (lexer->c >= '0' && lexer->c <= '9') {
                    state = StateFractional;
                    next(lexer);
                }
                else {
                    state = StateError;
                }
                break;
            case StateFractional:
                if (lexer->c >= '0' && lexer->c <= '9') {
                    next(lexer);
                }
                else {
                    state = StateExponentMark;
                }
                break;
            case StateExponentMark:
                if (lexer->c == 'E' || lexer->c == 'e') {
                    state = StateExponentSign;
                    next(lexer);
                }
                else {
                    state = StateSuccess;
                }
                break;
            case StateExponentSign:
                if (lexer->c == '+' || lexer->c == '-') {
                    state = StateExponentValue;
                    next(lexer);
                }
                else {
                    state = StateExponentValue;
                }
                break;
            case StateExponentValueStart:
                if (lexer->c >= '0' && lexer->c <= '9') {
                    state = StateExponentValue;
                    next(lexer);
                }
                else {
                    state = StateError;
                }
                break;
            case StateExponentValue:
                if (lexer->c >= '0' && lexer->c <= '9') {
                    next(lexer);
                }
                else {
                    state = StateSuccess;
                }
                break;
            default:
                state = StateError;
                break;
        }
    }
    
    if (state == StateSuccess) {
        char *end;
        double number = strtod(lexer->source + start, &end);
        if (end == lexer->source + lexer->pointer) {
            token->number = number;
            return;
        }
    }
    
    lexer->error = "illegal number format";
}

VZTTokenType _lexerNext(VZTLexer *lexer, VZTToken *token) {
    
#define UNKNOWN_TOKEN                       \
    lexer->error = "invalid character";     \
    return VZTTokenTypeUnknown;
    
    for(;;) {
        lexer->token.offset = lexer->pointer;
        
        switch (lexer->c) {
            case 0:
                return 0;
            case ' ':
            case '\t':
                next(lexer);
                continue;
            case '\n':
            case '\r':
                _newline(lexer);
                continue;
            case '&':
                next(lexer);
                if (lexer->c == '&') {
                    next(lexer);
                    return VZTTokenTypeAnd;
                }
                else {
                    UNKNOWN_TOKEN
                }
            case '|':
                next(lexer);
                if (lexer->c == '|') {
                    next(lexer);
                    return VZTTokenTypeOr;
                }
                else {
                    UNKNOWN_TOKEN
                }
            case '=':
                next(lexer);
                if (lexer->c == '=') {
                    next(lexer);
                    return VZTTokenTypeEqual;
                }
                else {
                    UNKNOWN_TOKEN
                }
            case '!':
                next(lexer);
                if (lexer->c == '=') {
                    next(lexer);
                    return VZTTokenTypeNotEqual;
                }
                else {
                    return '!';
                }
            case '>':
                next(lexer);
                if (lexer->c == '=') {
                    next(lexer);
                    return VZTTokenTypeGreaterOrEqaul;
                }
                else {
                    return '>';
                }
            case '<':
                next(lexer);
                if (lexer->c == '=') {
                    next(lexer);
                    return VZTTokenTypeLessOrEqaul;
                }
                else {
                    return '<';
                }
            case '/':
                next(lexer);
                if (lexer->c == '/') { // single line comment
                    do {
                        next(lexer);
                    } while (!isNewLine(lexer->c) && lexer->c != 0);
                    continue;
                } else if (lexer->c == '*') { // multi line comment
                    bool closed = false;
                    do {
                        next(lexer);
                        if (isNewLine(lexer->c)) {
                            _newline(lexer);
                        }
                        else if (lexer->c == '*') {
                            next(lexer);
                            if (lexer->c == '/') {
                                closed = true;
                                next(lexer);
                                break;
                            }
                            else {
                                continue;
                            }
                        }
                    } while (lexer->c != 0);
                    if (!closed) {
                        lexer->error = "'*/' expected";
                    }
                    continue;
                } else {
                    return '/';
                }
            case '-':
                next(lexer);
                if (lexer->c == '>') {
                    next(lexer);
                    return VZTTokenTypeArrow;
                }
                else {
                    return '-';
                }
            case '+':
            case '*':
            case '%':
            case '(':
            case ')':
            case '[':
            case ']':
            case '{':
            case '}':
            case '.':
            case '?':
            case ':':
            case ',':
            {
                char type = lexer->c;
                next(lexer);
                return type;
            }
            default:
                if (lexer->c == '_' || isalpha(lexer->c)) {
                    size_t start = lexer->pointer;
                    do {
                        next(lexer);
                        if (!(lexer->c == '_' || isalnum(lexer->c))) {
                            break;
                        }
                    } while (lexer->c);
                    size_t len = lexer->pointer - start;
                    const char *idStart = lexer->source + start;
                    if ((len == 4 && memcmp(idStart, "null", 4) == 0)
                        || (len == 3 && memcmp(idStart, "nil", 4) == 0)) {
                        return VZTTokenTypeNull;
                    }
                    else if (len == 4 && memcmp(idStart, "true", 4) == 0) {
                        token->number = 1;
                        return VZTTokenTypeBoolean;
                    }
                    else if (len == 5 && memcmp(idStart, "false", 5) == 0) {
                        token->number = 0;
                        return VZTTokenTypeBoolean;
                    }
                    else {
                        token->string = strndup(idStart, len);
                        return VZTTokenTypeId;
                    }
                } else if (isdigit(lexer->c)) {
                    _readNumber(lexer, token);
                    return VZTTokenTypeNumber;
                } else if (isQuote(lexer->c)) {
                    _readString(lexer, token);
                    return VZTTokenTypeString;
                } else {
                    UNKNOWN_TOKEN
                }
        }
    }
    return 0;
}

void _freeTokenString(VZTToken *token) {
    if (token->type == VZTTokenTypeId || token->type == VZTTokenTypeString) {
        free((void*)token->string);
        token->type = VZTTokenTypeUnknown;
    }
}

void VZTLexer_next(VZTLexer *lexer) {
    if (lexer->lookAhead.type) {
        lexer->token = lexer->lookAhead;
        lexer->lookAhead.type = 0;
    }
    else {
        _freeTokenString(&lexer->token);
        lexer->token.type = _lexerNext(lexer, &lexer->token);
        lexer->token.length = lexer->pointer - lexer->token.offset;
        if (lexer->error) {
            lexer->token.type = 0;
        }
    }
}

void VZTLexer_lookAhead(VZTLexer *lexer) {
    _freeTokenString(&lexer->lookAhead);
    lexer->lookAhead.type = _lexerNext(lexer, &lexer->lookAhead);
    lexer->lookAhead.length = lexer->pointer - lexer->lookAhead.offset;
    if (lexer->error) {
        lexer->lookAhead.type = 0;
    }
}

VZTLexer * VZTLexer_new(const char* source) {
    VZTLexer *lexer = (VZTLexer *)malloc(sizeof(VZTLexer));
    lexer->source = source;
    lexer->length = strlen(source);
    lexer->line = 0;
    lexer->error = NULL;
    lexer->pointer = -1;
    lexer->lookAhead.type = 0;
    lexer->buffer = VZTVector_new();
    next(lexer);
    return lexer;
}

void VZTLexer_free(VZTLexer *lexer) {
    if (lexer) {
        VZTVector_free(lexer->buffer);
        _freeTokenString(&lexer->token);
        _freeTokenString(&lexer->lookAhead);
        free(lexer);
    }
}


NSString *vzt_tokenName(VZTTokenType type) {
    if (type == 0) {
        return @"<unknown>";
    }
    else if (type < 256) {
        return [NSString stringWithFormat:@"%c", (char)type];
    }
    else {
        return [NSString stringWithFormat:@"%s", vzt_tokenNames[type - 256]];
    }
}
