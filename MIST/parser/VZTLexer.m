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

@implementation VZTToken

- (instancetype)initWithToken:(NSString *)token value:(id)value type:(VZTTokenType)type range:(NSRange)range
{
    if (self = [super init]) {
        _token = token;
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

- (NSString *)error
{
    return _error;
}

- (instancetype)initWithString:(NSString *)str
{
    if (self = [super init]) {
        _source = str;
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
        _pointer++;
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

#define VZF_JSON_ERROR(msg) \
    do {                    \
        _error = msg;       \
        return nil;         \
    } while (0)

- (NSString *)_readString:(char)quote {
    VZTVector *chars = NULL; // used for escaped string
    
    size_t start = _pointer + 1;
    size_t segment_len = 0;
#define PUSH_CURRENT_SEGMENT                                                \
if (!chars) {                                                               \
    chars = VZTVector_new();                                                \
}                                                                           \
if (segment_len > 0) {                                                      \
    VZTVector_push(chars, c_str + _pointer - segment_len, segment_len);     \
    segment_len = 0;                                                        \
}
    
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
    _pointer++;
    if (chars) {
        PUSH_CURRENT_SEGMENT
        NSString *str = [[NSString alloc] initWithBytes:chars->data length:chars->size encoding:NSUTF8StringEncoding];
        return str;
    }
    else {
        return [[NSString alloc] initWithBytes:c_str + start length:segment_len encoding:NSUTF8StringEncoding];
    }
    
#undef PUSH_CURRENT_SEGMENT
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
                    _pointer++;
                }
                else if (c >= '1' && c <= '9') {
                    state = StateNonzero;
                    _pointer++;
                }
                else {
                    state = StateError;
                }
                break;
            case StateNonzero:
                if (c >= '0' && c <= '9') {
                    _pointer++;
                }
                else {
                    state = StateDot;
                }
                break;
            case StateDot:
                if (c == '.') {
                    state = StateFractionalStart;
                    _pointer++;
                }
                else {
                    state = StateExponentMark;
                }
                break;
            case StateFractionalStart:
                if (c >= '0' && c <= '9') {
                    state = StateFractional;
                    _pointer++;
                }
                else {
                    state = StateError;
                }
                break;
            case StateFractional:
                if (c >= '0' && c <= '9') {
                    _pointer++;
                }
                else {
                    state = StateExponentMark;
                }
                break;
            case StateExponentMark:
                if (c == 'E' || c == 'e') {
                    state = StateExponentSign;
                    _pointer++;
                }
                else {
                    state = StateSuccess;
                }
                break;
            case StateExponentSign:
                if (c == '+' || c == '-') {
                    state = StateExponentValue;
                    _pointer++;
                }
                else {
                    state = StateExponentValue;
                }
                break;
            case StateExponentValueStart:
                if (c >= '0' && c <= '9') {
                    state = StateExponentValue;
                    _pointer++;
                }
                else {
                    state = StateError;
                }
                break;
            case StateExponentValue:
                if (c >= '0' && c <= '9') {
                    _pointer++;
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
    NSString *text;
    id value;

    NSInteger start = _pointer;
    char c = c_str[_pointer];

    if (c == '_' || isalpha(c)) {
        type = VZTTokenTypeId;
        while (++_pointer < c_len) {
            c = c_str[_pointer];
            if (!(c == '_' || isalpha(c) || isdigit(c))) {
                break;
            }
        }
        text = [[NSString alloc] initWithBytes:c_str + start length:_pointer - start encoding:NSUTF8StringEncoding];
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
        type = VZTTokenTypeOperator;
        switch (c) {
            case '&':
            case '|':
            case '=':
                if (++_pointer >= c_len || c_str[_pointer] != c) {
                    _pointer--;
                    type = VZTTokenTypeUnknown;
                }
                break;
            case '!':
            case '>':
            case '<':
                if (++_pointer >= c_len || c_str[_pointer] != '=') {
                    _pointer--;
                }
                break;
            case '/':
                if (++_pointer < c_len) {
                    c = c_str[_pointer];
                    if (c == '/') { // single line comment
                        while (++_pointer < c_len && c_str[_pointer] != '\n')
                            ;
                        return [self nextToken];
                    } else if (c == '*') { // multi line comment
                        bool closed = false;
                        if (++_pointer < c_len && c_str[_pointer] == '\n') {
                            _line++;
                        }
                        while (++_pointer < c_len) {
                            c = c_str[_pointer];
                            if (c == '\n') {
                                _line++;
                            } else if (c == '/' && c_str[_pointer - 1] == '*') {
                                _pointer++;
                                closed = true;
                                break;
                            }
                        }
                        if (!closed) {
                            VZF_JSON_ERROR(@"unclosed comment block at end of file");
                        }
                        return [self nextToken];
                    } else {
                        _pointer--;
                    }
                }
                else {
                    _pointer--;
                }
                break;
            case '-':
                if (++_pointer >= c_len || c_str[_pointer] != '>') {
                    _pointer--;
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
                break;
            default:
                type = VZTTokenTypeUnknown;
                break;
        }
        _pointer++;
        text = [[NSString alloc] initWithBytes:c_str + start length:_pointer - start encoding:NSUTF8StringEncoding];
    }

    return [[VZTToken alloc] initWithToken:text value:value type:type range:NSMakeRange(start, _pointer - start)];
}

@end

#undef VZF_JSON_ERROR
