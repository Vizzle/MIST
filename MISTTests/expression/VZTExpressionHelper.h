//
//  VZTExpressionHelper.h
//  MIST
//
//  Created by Sleen on 2017/9/5.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#ifndef VZTExpressionHelper_h
#define VZTExpressionHelper_h

#import "VZTLexer.h"
#import "VZTParser.h"
#import "VZTExpressionNode.h"

#define XCTAssertExpression(EXP, RESULT)                                                    \
do {                                                                                        \
    NSError *error = nil;                                                                   \
    VZTExpressionNode *exp = [VZTParser parse:EXP error:&error];                            \
    XCTAssertNil(error, @"'%@' expression not valid: %@", EXP, error.localizedDescription); \
    XCTAssertEqualObjects([exp compute], RESULT, @"'%@' not equals to '%@'", EXP, RESULT);  \
} while (0)

#define XCTAssertSameExpression(EXP) XCTAssertExpression(@"" #EXP, @(EXP))

#define VZT_COMPUTE_WITH_CONTEXT(EXP, CXT) \
({                                                                                          \
    NSError *error = nil;                                                                   \
    VZTExpressionNode *exp = [VZTParser parse:EXP error:&error];                            \
    XCTAssertNil(error, @"'%@' expression not valid: %@", EXP, error.localizedDescription); \
    [exp compute:CXT];                                                                      \
})

#define VZT_COMPUTE(EXP) VZT_COMPUTE_WITH_CONTEXT(EXP, [VZTExpressionContext new])

#define XCTAssertExpressionNotCompiled(EXP)                                                 \
do {                                                                                        \
    NSError *error = nil;                                                                   \
    [VZTParser parse:EXP error:&error];                                                     \
    XCTAssertNotNil(error, @"'%@' expression parsed without error", EXP);                   \
} while (0)
#define XCTAssertExpressionCompiled(EXP)                                                    \
do {                                                                                        \
    NSError *error = nil;                                                                   \
    [VZTParser parse:EXP error:&error];                                                     \
    XCTAssertNil(error);                                                                    \
} while (0)

#define XCTAssertExpressionErrorDesc(EXP, desc)                                             \
do {                                                                                        \
    NSError *error = nil;                                                                   \
    [VZTParser parse:EXP error:&error];                                                     \
    XCTAssertEqualObjects(error.localizedDescription, desc);                                \
} while (0)


#endif /* VZTExpressionHelper_h */
