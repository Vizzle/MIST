//
//  VZTLexer.cpp
//  VZFlexEditor
//
//  Created by Sleen on 16/4/14.
//  Copyright © 2016年 O2O. All rights reserved.
//

#include "VZTLexer.h"


@implementation VZTToken

- (instancetype)initWithToken:(NSString *)token type:(VZTTokenType)type range:(NSRange)range
{
    if (self = [super init]) {
        _token = token;
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
}

- (NSString *)error
{
    return _error;
}

- (instancetype)initWithString:(NSString *)str
{
    if (self = [super init]) {
        _source = str;
        _pointer = 0;
        _line = 0;
        _lookAheadStack = [NSMutableArray array];
    }
    return self;
}

- (void)skipSpaces
{
    while (_pointer < _source.length) {
        unichar c = [_source characterAtIndex:_pointer];
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

- (NSRegularExpression *)numberRegex
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^(0|[1-9]\\d*)(\\.\\d+)?([eE][+-]?\\d+)?" options:0 error:nil];
    });
    return regex;
}

- (NSRegularExpression *)unicodeRegex
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^[a-fA-F0-9]{4}" options:0 error:nil];
    });
    return regex;
}

- (VZTToken *)_nextToken
{
#define VZF_JSON_ERROR(msg) \
    do {                    \
        _error = msg;       \
        return nil;         \
    } while (0)

    [self skipSpaces];

    if (_pointer >= _source.length) {
        return nil;
    }

    VZTTokenType type;
    NSString *text;

    NSInteger start = _pointer;
    unichar c = [_source characterAtIndex:_pointer];

    if (c == '_' || isalpha(c)) {
        type = VZTTokenTypeId;
        while (++_pointer < _source.length) {
            c = [_source characterAtIndex:_pointer];
            if (!(c == '_' || isalpha(c) || isdigit(c))) {
                break;
            }
        }
        text = [_source substringWithRange:NSMakeRange(start, _pointer - start)];
    } else if (isdigit(c)) {
        type = VZTTokenTypeNumber;
        NSTextCheckingResult *result = [[self numberRegex] firstMatchInString:_source options:0 range:NSMakeRange(start, _source.length - start)];
        if (result) {
            text = [_source substringWithRange:result.range];
            _pointer += result.range.length;
        } else {
            VZF_JSON_ERROR(@"illegal number format");
        }
    } else if (c == '"' || c == '\'') {
        unichar quote = c;
        type = VZTTokenTypeString;
        NSMutableString *str = [NSMutableString new];
        bool closed = false;
        while (++_pointer < _source.length) {
            c = [_source characterAtIndex:_pointer];
            if (c == '\\') {
                unichar esc = 0;
                bool failed = false;
                if (++_pointer < _source.length) {
                    switch ([_source characterAtIndex:_pointer]) {
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
                            if (_pointer + 4 < _source.length) {
                                NSTextCheckingResult *result = [[self unicodeRegex] firstMatchInString:_source options:0 range:NSMakeRange(_pointer + 1, 4)];
                                if (result) {
                                    esc = strtol([_source substringWithRange:result.range].UTF8String, NULL, 16);
                                    _pointer += 4;
                                } else {
                                    failed = true;
                                    VZF_JSON_ERROR(@"illegal format of escaping unicode character");
                                }
                            } else {
                                failed = true;
                            }
                            break;
                        default:
                            failed = true;
                    }
                    if (!failed) {
                        [str appendString:[NSString stringWithCharacters:&esc length:1]];
                    }
                } else {
                    failed = true;
                }

                if (failed) {
                    VZF_JSON_ERROR(@"illegal escaped character");
                }
            } else if (c == '\n') {
                VZF_JSON_ERROR(@"unclosed string literal at end of line");
            } else if (c == '\t') {
                VZF_JSON_ERROR(@"tab character in string is not allowed");
            } else if (c == quote) {
                closed = true;
                break;
            } else {
                [str appendString:[NSString stringWithCharacters:&c length:1]];
            }
        }
        if (closed) {
            text = str;
            _pointer++;
        } else {
            VZF_JSON_ERROR(@"unclosed string literal at end of file");
        }
    } else {
        type = VZTTokenTypeOperator;
        switch (c) {
            case '&':
            case '|':
            case '=':
                if (++_pointer >= _source.length || [_source characterAtIndex:_pointer] != c) {
                    _pointer--;
                    type = VZTTokenTypeUnknown;
                }
                break;
            case '!':
            case '>':
            case '<':
                if (++_pointer >= _source.length || [_source characterAtIndex:_pointer] != '=') {
                    _pointer--;
                }
                break;
            case '/':
                if (++_pointer < _source.length) {
                    c = [_source characterAtIndex:_pointer];
                    if (c == '/') { // single line comment
                        while (++_pointer < _source.length && [_source characterAtIndex:_pointer] != '\n')
                            ;
                        return [self nextToken];
                    } else if (c == '*') { // multi line comment
                        bool closed = false;
                        if (++_pointer < _source.length && [_source characterAtIndex:_pointer] == '\n') {
                            _line++;
                        }
                        while (++_pointer < _source.length) {
                            c = [_source characterAtIndex:_pointer];
                            if (c == '\n') {
                                _line++;
                            } else if (c == '/' && [_source characterAtIndex:_pointer - 1] == '*') {
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
                if (++_pointer >= _source.length || [_source characterAtIndex:_pointer] != '>') {
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
        text = [_source substringWithRange:NSMakeRange(start, _pointer - start)];
    }

    return [[VZTToken alloc] initWithToken:text type:type range:NSMakeRange(start, _pointer - start)];
#undef VZF_JSON_ERROR
}

@end
