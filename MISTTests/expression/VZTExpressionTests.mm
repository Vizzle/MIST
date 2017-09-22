//
//  VZTExpressionTests.m
//  MIST
//
//  Created by Sleen on 2017/6/16.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "VZTExpressionHelper.h"

@interface ExpressionUnitTest : XCTestCase

@end

@implementation ExpressionUnitTest

- (void)testTypes {
    // Number
    XCTAssertSameExpression(1);
    XCTAssertSameExpression(0);
    XCTAssertSameExpression(-1);
    XCTAssertSameExpression(0.0000001);
    XCTAssertSameExpression(1.23456789);
    XCTAssertSameExpression(1.2345e3);
    XCTAssertSameExpression(1.2345e-3);
    
    // String
    XCTAssertExpression(@"'abc'", @"abc");
    XCTAssertExpression(@"\"abc\"", @"abc");
    XCTAssertExpression(@"'\"'", @"\"");
    XCTAssertExpression(@"\"'\"", @"'");
    XCTAssertExpression(@"'\\r\\n\\t\\f\\b\\\"\\\'\\\\\\/'", @"\r\n\t\f\b\"\'\\/");
    XCTAssertExpression(@"'\\uface'", @"\uface");
    XCTAssertExpression(@"'a\\nb'", @"a\nb");
    XCTAssertExpression(@"'abc\\tdef\\\\\\n'", @"abc\tdef\\\n");
    XCTAssertExpression(@"'\\nabcd\\u1234'", @"\nabcd\u1234");
    XCTAssertExpression(@"'\\u1234abcd\\u1234ab'", @"\u1234abcd\u1234ab");
    
    // true / false / null
    XCTAssertExpression(@"true", @YES);
    XCTAssertExpression(@"false", @NO);
    XCTAssertExpression(@"null", nil);
    XCTAssertExpression(@"nil", nil);
    
    // Array
    XCTAssertExpression(@"['a', 1, true]", (@[@"a", @1, @YES]));
    XCTAssertExpression(@"[]", @[]);
    XCTAssertExpression(@"[1, 2, [3, 4]]", (@[@1, @2, @[@3, @4]]));
    
    // Dictionary
    XCTAssertExpression(@"{'a': 1, 'b': 2}", (@{@"a": @1, @"b": @2}));
    XCTAssertExpression(@"{}", @{});
    XCTAssertExpression(@"{1: 2, 3: 4}", (@{@1: @2, @3: @4}));
    XCTAssertExpression(@"{'a': true, 'b': {'c': 'd'}}", (@{@"a": @YES, @"b": @{@"c": @"d"}}));
}

- (void)testComments {
    XCTAssertExpression(@"'abc' // comment", @"abc");
    XCTAssertExpression(@"'abc' /* comment */", @"abc");
    XCTAssertExpression(@"'abc'\n /* comment\ncomment\n */", @"abc");
    XCTAssertExpression(@"'abc' //", @"abc");
    XCTAssertExpression(@"'abc' /**/", @"abc");
    XCTAssertExpression(@"/* comment */'abc'", @"abc");
    XCTAssertExpression(@"/* comment */\n'abc'", @"abc");
    XCTAssertExpression(@"1/* comment */ + /* comment */1", @2);
}

- (void)testOperators {
    XCTAssertSameExpression(1 + 1);
    XCTAssertSameExpression(5 * 5);
    XCTAssertSameExpression(10 - 5);
    XCTAssertSameExpression(10 - 5 - 5);
    XCTAssertSameExpression(1.0 / 10);
    XCTAssertSameExpression(1.0 / 10 / 10);
    XCTAssertSameExpression(-1 - 10);
    XCTAssertSameExpression(-(1 - 10));
    XCTAssertSameExpression(10 + 5 * 2);
    XCTAssertSameExpression(1+(2-3)*(4.0/5-6)+((7-8)-(9+10)));
    
    XCTAssertSameExpression(5 > 0);
    XCTAssertSameExpression(5 > 5);
    XCTAssertSameExpression(5 > 10);
    XCTAssertSameExpression(5 < 0);
    XCTAssertSameExpression(5 < 5);
    XCTAssertSameExpression(5 < 10);
    XCTAssertSameExpression(5 >= 0);
    XCTAssertSameExpression(5 >= 5);
    XCTAssertSameExpression(5 >= 10);
    XCTAssertSameExpression(5 <= 0);
    XCTAssertSameExpression(5 <= 5);
    XCTAssertSameExpression(5 <= 10);
    XCTAssertSameExpression(5 == 10);
    XCTAssertSameExpression(5 == 5);
    XCTAssertSameExpression(5 != 10);
    XCTAssertSameExpression(5 != 5);
    XCTAssertSameExpression(1 + 1 == 2);
    XCTAssertSameExpression(1 + 1 != 2);
    
    XCTAssertSameExpression(true);
    XCTAssertSameExpression(false);
    XCTAssertSameExpression(!true);
    XCTAssertSameExpression(!false);
    XCTAssertSameExpression(!!true);
    XCTAssertSameExpression(!!false);
    XCTAssertSameExpression(true && true);
    XCTAssertSameExpression(true && false);
    XCTAssertSameExpression(false && true);
    XCTAssertSameExpression(true || true);
    XCTAssertSameExpression(true || false);
    XCTAssertSameExpression(false || true);
    XCTAssertSameExpression(!true && true);
    XCTAssertSameExpression(!true && false);
    XCTAssertSameExpression(!false && true);
    XCTAssertSameExpression(!true || true);
    XCTAssertSameExpression(!true || false);
    XCTAssertSameExpression(!false || true);
    XCTAssertSameExpression(true && !true);
    XCTAssertSameExpression(true && !false);
    XCTAssertSameExpression(false && !true);
    XCTAssertSameExpression(true || !true);
    XCTAssertSameExpression(true || !false);
    XCTAssertSameExpression(false || !true);
    XCTAssertSameExpression(!(true && true));
    XCTAssertSameExpression(!(true && false));
    XCTAssertSameExpression(!(false && true));
    XCTAssertSameExpression(!(true || true));
    XCTAssertSameExpression(!(true || false));
    XCTAssertSameExpression(!(false || true));
    XCTAssertSameExpression(false || false || true);
    XCTAssertSameExpression(false || false && true);
    XCTAssertSameExpression((false || false) && true);
    XCTAssertSameExpression(false || (false && true));
    XCTAssertSameExpression(true && false || true || false);
    XCTAssertSameExpression(true || false || true && true || false || true && false);
    
    XCTAssertSameExpression(true ? 1 : 0);
    XCTAssertSameExpression(false ? 1 : 0);
    XCTAssertSameExpression(true ? true ? 1 : 0 : 0);
    XCTAssertSameExpression(false ? true ? 1 : 0 : 0);
    XCTAssertSameExpression(false ? false ? 1 : 0 : 0);
    XCTAssertSameExpression(false ? true ? 1 : 0 : 0);
    XCTAssertSameExpression(true ? 1 : true ? 1 : 0);
    XCTAssertSameExpression(false ? 1 : true ? 1 : 0);
    XCTAssertSameExpression(true ? 1 : false ? 1 : 0);
    XCTAssertSameExpression(false ? 1 : false ? 1 : 0);
    XCTAssertSameExpression(true ? 1 : true ? 1 : 0 + 5);
    XCTAssertSameExpression(false ? 1 : true ? 1 : 0 + 5);
    XCTAssertSameExpression(true ? 1 : false ? 1 : 0 + 5);
    XCTAssertSameExpression(false ? 1 : false ? 1 : 0 + 5);
    XCTAssertSameExpression(3 + 2 >= 5 ? 1 : 1 - 1 == 0 ? 1 : 0);
    
    NSArray *arr1 = @[@1, @2, @"a", @"b"];
    NSArray *arr2 = @[arr1, @2, arr1];
    NSDictionary *dict1 = @{@"a": @1, @"b": @2, @"c": @"3"};
    NSDictionary *dict2 = @{@"a": dict1, @"b": arr2, @3: @"c"};
    VZTExpressionContext *context = [VZTExpressionContext new];
    [context pushVariables:@{@"arr1": arr1, @"arr2": arr2, @"dict1": dict1, @"dict2": dict2}];
    
#define XCTAssertSubscriptExpression(EXP)                                                       \
do {                                                                                            \
NSError *error = nil;                                                                       \
NSString *expText = [@"" #EXP stringByReplacingOccurrencesOfString:@"@" withString:@""];    \
VZTExpressionNode *exp = [VZTParser parse:expText error:&error];                            \
XCTAssertNil(error, @"'%@' expression not valid: %@", expText, error.localizedDescription); \
XCTAssertEqualObjects([exp compute:context], EXP, @"'%@' not equals to '%@'", expText, EXP);\
} while (0)
    
    XCTAssertSubscriptExpression(arr1[0]);
    XCTAssertSubscriptExpression(arr1[1]);
    XCTAssertSubscriptExpression(arr1[2]);
    XCTAssertSubscriptExpression(arr1[3]);
    XCTAssertSubscriptExpression(arr2[0]);
    XCTAssertSubscriptExpression(arr2[1]);
    XCTAssertSubscriptExpression(arr2[2]);
    XCTAssertSubscriptExpression(arr2[0][0]);
    XCTAssertSubscriptExpression(arr2[0][1]);
    XCTAssertSubscriptExpression(arr2[2][0]);
    XCTAssertSubscriptExpression(dict1[@"a"]);
    XCTAssertSubscriptExpression(dict1[@"b"]);
    XCTAssertSubscriptExpression(dict1[@"c"]);
    XCTAssertSubscriptExpression(dict2[@"a"]);
    XCTAssertSubscriptExpression(dict2[@"b"]);
    XCTAssertSubscriptExpression(dict2[@3]);
    XCTAssertSubscriptExpression(dict2[@"a"][@"a"]);
    XCTAssertSubscriptExpression(dict2[@"b"][0][1]);
    XCTAssertEqualObjects([[VZTParser parse:@"dict1.a" error:nil] compute:context], dict1[@"a"]);
    XCTAssertEqualObjects([[VZTParser parse:@"dict2.a.a" error:nil] compute:context], dict2[@"a"][@"a"]);
}

+ (int)foo:(int)a :(int)b {
    return a + b;
}

static NSString *status;

+ (void)bar:(NSString *)text {
    status = text;
}

- (void)testFunctionCall {
    XCTAssertExpressionCompiled(@"a()");
    
    XCTAssert([VZT_COMPUTE(@"NSObject.alloc.init") isMemberOfClass:[NSObject class]]);
    XCTAssertExpression(@"NSObject.class", NSObject.class);
    XCTAssertExpression(@"NSNumber.isSubclassOfClass(NSObject.class)", @([NSNumber isSubclassOfClass:NSObject.class]));
    XCTAssertExpression(@"'abcabc'.stringByReplacingOccurrencesOfString_withString('a', '1')", [@"abcabc" stringByReplacingOccurrencesOfString:@"a" withString:@"1"]);
    XCTAssertExpression(@"ExpressionUnitTest.foo(1, 2)", @([self.class foo:1 :2]));
    
    VZT_COMPUTE(@"ExpressionUnitTest.bar('void function called')");
    XCTAssertEqualObjects(status, @"void function called");
}

- (void)testLambda {
    XCTAssertExpression(@"[1, 2, 3].select(n->n*2)", (@[@2, @4, @6]));
    NSLog(@"%@", VZT_COMPUTE(@"for(2, 100).filter(n -> for(2, n).all(m -> n % m != 0))"));
    XCTAssertExpression(@"for(2, 100).filter(n -> for(2, n).all(m -> n % m != 0))", (@[@2, @3, @5, @7, @11, @13, @17, @19, @23, @29, @31, @37, @41, @43, @47, @53, @59, @61, @67, @71, @73, @79, @83, @89, @97]));
}

- (void)testScope {
    VZTExpressionContext *context = [VZTExpressionContext new];
    XCTAssertEqualObjects(VZT_COMPUTE_WITH_CONTEXT(@"a", context), nil);
    [context pushVariableWithKey:@"a" value:@1];
    XCTAssertEqualObjects(VZT_COMPUTE_WITH_CONTEXT(@"a", context), @1);
    [context pushVariableWithKey:@"a" value:@2];
    XCTAssertEqualObjects(VZT_COMPUTE_WITH_CONTEXT(@"a", context), @2);
    [context popVariableWithKey:@"a"];
    XCTAssertEqualObjects(VZT_COMPUTE_WITH_CONTEXT(@"a", context), @1);
    [context popVariableWithKey:@"a"];
    XCTAssertEqualObjects(VZT_COMPUTE_WITH_CONTEXT(@"a", context), nil);
}

- (void)testErrors {
    XCTAssertExpressionErrorDesc(@"1 +", @"expression expected");
    XCTAssertExpressionErrorDesc(@"+", @"expression expected");
    XCTAssertExpressionErrorDesc(@"(1+1", @"')' expected");
    XCTAssertExpressionErrorDesc(@"a,", @"unexpected token");
    XCTAssertExpressionErrorDesc(@"a=", @"invalid character");
    XCTAssertExpressionErrorDesc(@"a=1", @"invalid character");
    XCTAssertExpressionErrorDesc(@"()", @"expression expected");
    XCTAssertExpressionErrorDesc(@".a", @"expression expected");
    XCTAssertExpressionErrorDesc(@"a.", @"identifier expected");
    XCTAssertExpressionErrorDesc(@"a(", @"')' expected");
    XCTAssertExpressionErrorDesc(@"1+1)", @"unexpected token");
    XCTAssertExpressionErrorDesc(@"1.23.3", @"identifier expected");
    XCTAssertExpressionErrorDesc(@"1.a", @"illegal number format");
    XCTAssertExpressionErrorDesc(@".123", @"expression expected");
    XCTAssertExpressionErrorDesc(@"/**", @"'*/' expected");
    XCTAssertExpressionErrorDesc(@"", @"empty expression");
    XCTAssertExpressionErrorDesc(@"   ", @"empty expression");
    XCTAssertExpressionErrorDesc(@"\n/** comment*/ // comment \n //", @"empty expression");
    XCTAssertExpressionErrorDesc(@"test.test(1, )", @"expression expected");
    XCTAssertExpressionErrorDesc(@"test.()", @"identifier expected");
    XCTAssertExpressionErrorDesc(@"test(,123)", @"unexpected ','");
    XCTAssertExpressionErrorDesc(@"a ? 1", @"':' expected");
    XCTAssertExpressionErrorDesc(@"a 1 : 2", @"unexpected token");
    XCTAssertExpressionErrorDesc(@"2abc + 1", @"unexpected token");
    XCTAssertExpressionErrorDesc(@"$abc", @"invalid character");
    XCTAssertExpressionErrorDesc(@"'\t'", @"invalid characters in string. control characters must be escaped");
    XCTAssertExpressionErrorDesc(@"'abc", @"unclosed string literal");
    XCTAssertExpressionErrorDesc(@"'abc\n'", @"unclosed string literal");
    XCTAssertExpressionErrorDesc(@"'abc\\", @"unclosed string literal");
    XCTAssertExpressionErrorDesc(@"'abc\\'", @"unclosed string literal");
    XCTAssertExpressionErrorDesc(@"'abc\\uag12'", @"invalid unicode sequence in string");
    XCTAssertExpressionErrorDesc(@"'abc\\u'", @"invalid unicode sequence in string");
    XCTAssertExpressionErrorDesc(@"'abc\\q'", @"invalid escaped character in string");
    XCTAssertExpressionErrorDesc(@"'abc\\u123'", @"invalid unicode sequence in string");
    XCTAssertExpressionErrorDesc(@"'''", @"unclosed string literal");
    XCTAssertExpressionErrorDesc(@"[1,2,]", @"expression expected");
    XCTAssertExpressionErrorDesc(@"[,2,3]", @"unexpected ','");
    XCTAssertExpressionErrorDesc(@"{'a':b,}", @"expression expected");
    XCTAssertExpressionErrorDesc(@"lambda(a->)", @"expression expected");
    XCTAssertExpressionErrorDesc(@"lambda(->b)", @"argument identifier expected");
    XCTAssertExpressionErrorDesc(@"lambda(a- >b)", @"expression expected");
    XCTAssertExpressionErrorDesc(@"a[]", @"expression expected");
    XCTAssertExpressionErrorDesc(@"a(,)", @"unexpected ','");
}

@end
