//
//  VZTLexer.cpp
//  VZFlexEditor
//
//  Created by Sleen on 16/4/14.
//  Copyright © 2016年 O2O. All rights reserved.
//

#include "VZTLexer.h"


typedef struct {
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
        free(vector->data);
        vector->capacity *= 1.5;
        vector->data = malloc(sizeof(vector->capacity));
    }
    memcpy(vector->data + vector->size - len, data, len);
}

#define VZTVector_free(vector) do { \
    free(vector->data);             \
    free(vector);                   \
    vector = NULL;                  \
} while(0)


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


@implementation VZTToken

- (instancetype)initWithValue:(id)value type:(VZTTokenType)type range:(NSRange)range
{
    if (self = [super init]) {
        _value = value;
        _type = type;
        _range = range;
    }
    return self;
}

@end


@implementation VZTLexer
{
    NSInteger _line;
    NSString *_error;
    const char *c_str;
    NSInteger c_len;
}

#define next() _pointer++;

#define VZF_JSON_ERROR(msg) \
    do {                    \
        _error = msg;       \
        return nil;         \
    } while (0)

- (NSString *)error
{
    return _error;
}

- (instancetype)initWithString:(NSString *)str
{
    if (self = [super init]) {
        c_str = str.UTF8String;
        c_len = strlen(c_str);
        _pointer = 0;
        _line = 0;
        _lookAheadStack = [NSMutableArray array];
    }
    return self;
}

- (void)skipSpaces
{
    while (_pointer < c_len) {
        char c = c_str[_pointer];
        if (c == '\n') {
            _line++;
        } else if (!(c == ' ' || c == '\t' || c == '\r')) {
            return;
        }
        next();
    }
}

- (VZTToken *)lookAhead
{
    return [self lookAhead:0];
}

- (VZTToken *)lookAhead:(NSInteger)number
{
    while (_lookAheadStack.count <= number) {
        VZTToken *token = [self _nextToken];
        if (!token) return nil;
        [_lookAheadStack addObject:token];
    }
    return [_lookAheadStack objectAtIndex:number];
}

- (VZTToken *)nextToken
{
    if (_lookAheadStack.count > 0) {
        VZTToken *token = _lookAheadStack.firstObject;
        [_lookAheadStack removeObjectAtIndex:0];
        _lastToken = token;
    } else {
        _lastToken = [self _nextToken];
    }

    return _lastToken;
}

- (NSString *)_readString:(char)quote {
    VZTVector *chars = NULL; // used for escaped string
    
    size_t start = _pointer + 1;
    size_t segment_start = start;
    size_t segment_len = 0;
#define PUSH_CURRENT_SEGMENT                                                \
if (!chars) {                                                               \
    chars = VZTVector_new();                                                \
}                                                                           \
if (segment_len > 0) {                                                      \
    VZTVector_push(chars, c_str + segment_start, segment_len);              \
    segment_len = 0;                                                        \
}                                                                           \
segment_start = _pointer + 1;
    
    char c;
    bool closed = false;
    while (++_pointer < c_len) {
        c = c_str[_pointer];
        if (c == '\\') {
            char esc = 0;
            bool failed = false;
            if (++_pointer < c_len) {
                switch (c_str[_pointer]) {
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
                        if (_pointer + 4 < c_len) {
                            bool valid = true;
                            unichar unicode = 0;
                            for (int i = 0; i < 4; i++) {
                                char c = c_str[_pointer + i + 1];
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
                            }
                            if (valid) {
                                _pointer += 4;
                                NSString *unicodeStr = [NSString stringWithCharacters:&unicode length:1];
                                PUSH_CURRENT_SEGMENT
                                const char *unicodeChars = unicodeStr.UTF8String;
                                VZTVector_push(chars, unicodeChars, strlen(unicodeChars));
                                continue;
                            } else {
                                VZF_JSON_ERROR(@"illegal format of escaping unicode character");
                            }
                        } else {
                            VZF_JSON_ERROR(@"illegal escaped character");
                        }
                        break;
                    default:
                        failed = true;
                }
            } else {
                failed = true;
            }
            
            if (failed) {
                VZF_JSON_ERROR(@"illegal escaped character");
            }
            PUSH_CURRENT_SEGMENT
            VZTVector_push(chars, &esc, 1);
        } else if (c == '\n') {
            VZF_JSON_ERROR(@"unclosed string literal at end of line");
        } else if (c == '\t') {
            VZF_JSON_ERROR(@"tab character in string is not allowed");
        } else if (c == quote) {
            closed = true;
            break;
        } else {
            segment_len++;
        }
    }
    if (!closed) {
        VZF_JSON_ERROR(@"unclosed string literal at end of file");
    }
    next();
    if (chars) {
        PUSH_CURRENT_SEGMENT
        NSString *str = [[NSString alloc] initWithBytes:chars->data length:chars->size encoding:NSUTF8StringEncoding];
        return str;
    }
    else {
        return [[NSString alloc] initWithBytes:c_str + start length:segment_len encoding:NSUTF8StringEncoding];
    }
}

- (NSNumber *)_readNumber {
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
    size_t start = _pointer;
    
    while (state != StateSuccess && state != StateError) {
        char c = _pointer < c_len ? c_str[_pointer] : 0;
        
        switch (state) {
            case StateStart:
                if (c == '0') {
                    state = StateDot;
                    next();
                }
                else if (c >= '1' && c <= '9') {
                    state = StateNonzero;
                    next();
                }
                else {
                    state = StateError;
                }
                break;
            case StateNonzero:
                if (c >= '0' && c <= '9') {
                    next();
                }
                else {
                    state = StateDot;
                }
                break;
            case StateDot:
                if (c == '.') {
                    state = StateFractionalStart;
                    next();
                }
                else {
                    state = StateExponentMark;
                }
                break;
            case StateFractionalStart:
                if (c >= '0' && c <= '9') {
                    state = StateFractional;
                    next();
                }
                else {
                    state = StateError;
                }
                break;
            case StateFractional:
                if (c >= '0' && c <= '9') {
                    next();
                }
                else {
                    state = StateExponentMark;
                }
                break;
            case StateExponentMark:
                if (c == 'E' || c == 'e') {
                    state = StateExponentSign;
                    next();
                }
                else {
                    state = StateSuccess;
                }
                break;
            case StateExponentSign:
                if (c == '+' || c == '-') {
                    state = StateExponentValue;
                    next();
                }
                else {
                    state = StateExponentValue;
                }
                break;
            case StateExponentValueStart:
                if (c >= '0' && c <= '9') {
                    state = StateExponentValue;
                    next();
                }
                else {
                    state = StateError;
                }
                break;
            case StateExponentValue:
                if (c >= '0' && c <= '9') {
                    next();
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
        double number = strtod(c_str + start, &end);
        if (end - c_str == _pointer) {
            return @(number);
        }
    }
    
    VZF_JSON_ERROR(@"illegal number format");
}

- (VZTToken *)_nextToken
{
    [self skipSpaces];

    if (_pointer >= c_len) {
        return nil;
    }

    VZTTokenType type;
    id value;

    NSInteger start = _pointer;
    char c = c_str[_pointer];

    if (c == '_' || isalpha(c)) {
        while (++_pointer < c_len) {
            c = c_str[_pointer];
            if (!(c == '_' || isalpha(c) || isdigit(c))) {
                break;
            }
        }
        size_t len = _pointer - start;
        const char *idStart = c_str + start;
        if ((len == 4 && memcmp(idStart, "null", 4) == 0)
            || (len == 3 && memcmp(idStart, "nil", 4) == 0)) {
            type = VZTTokenTypeNull;
        }
        else if (len == 4 && memcmp(idStart, "true", 4) == 0) {
            type = VZTTokenTypeBoolean;
            value = @YES;
        }
        else if (len == 5 && memcmp(idStart, "false", 5) == 0) {
            type = VZTTokenTypeBoolean;
            value = @NO;
        }
        else {
            type = VZTTokenTypeId;
            value = [[NSString alloc] initWithBytes:c_str + start length:_pointer - start encoding:NSUTF8StringEncoding];
        }
    } else if (isdigit(c)) {
        type = VZTTokenTypeNumber;
        value = [self _readNumber];
        if (!value) {
            return nil;
        }
    } else if (c == '"' || c == '\'') {
        type = VZTTokenTypeString;
        value = [self _readString:c];
        if (!value) {
            return nil;
        }
    } else {
        switch (c) {
            case '&':
                next();
                if (c_str[_pointer] == '&') {
                    type = VZTTokenTypeAnd;
                    next();
                }
                else {
                    type = VZTTokenTypeUnknown;
                }
                break;
            case '|':
                next();
                if (c_str[_pointer] == '|') {
                    type = VZTTokenTypeOr;
                    next();
                }
                else {
                    type = VZTTokenTypeUnknown;
                }
                break;
            case '=':
                next();
                if (c_str[_pointer] == '=') {
                    type = VZTTokenTypeEqual;
                    next();
                }
                else {
                    type = VZTTokenTypeUnknown;
                }
                break;
            case '!':
                next();
                if (c_str[_pointer] == '=') {
                    type = VZTTokenTypeNotEqual;
                    next();
                }
                else {
                    type = '!';
                }
                break;
            case '>':
                next();
                if (c_str[_pointer] == '=') {
                    type = VZTTokenTypeGreaterOrEqaul;
                    next();
                }
                else {
                    type = '>';
                }
                break;
            case '<':
                next();
                if (c_str[_pointer] == '=') {
                    type = VZTTokenTypeLessOrEqaul;
                    next();
                }
                else {
                    type = '<';
                }
                break;
            case '/':
                next();
                c = c_str[_pointer];
                if (c == '/') { // single line comment
                    do {
                        next();
                        c = c_str[_pointer];
                    } while (c != '\n' && c != 0);
                    return [self nextToken];
                } else if (c == '*') { // multi line comment
                    bool closed = false;
                    if (++_pointer < c_len && c_str[_pointer] == '\n') {
                        _line++;
                    }
                    size_t start = _pointer;
                    do {
                        next();
                        c = c_str[_pointer];
                        if (c == '\n') {
                            _line++;
                        }
                        else if (c == '/' && c_str[_pointer - 1] == '*' && _pointer - 2 >= start) {
                            next();
                            closed = true;
                            break;
                        }
                    } while (c != 0);
                    if (!closed) {
                        VZF_JSON_ERROR(@"unclosed comment block at end of file");
                    }
                    return [self nextToken];
                } else {
                    type = '/';
                }
                break;
            case '-':
                next();
                if (c_str[_pointer] == '>') {
                    type = VZTTokenTypeArrow;
                    next();
                }
                else {
                    type = '-';
                }
                break;
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
                next();
                type = c;
                break;
            default:
                type = VZTTokenTypeUnknown;
                break;
        }
    }

    return [[VZTToken alloc] initWithValue:value type:type range:NSMakeRange(start, _pointer - start)];
}

- (NSString *)getTokenText:(VZTToken *)token {
    return [[NSString alloc] initWithBytes:c_str + token.range.location length:token.range.length encoding:NSUTF8StringEncoding];
}

@end
