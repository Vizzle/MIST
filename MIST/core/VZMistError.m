//
//  VZMistError.m
//  MIST
//
//  Created by John Wong on 12/8/16.
//  Copyright © 2016 Vizlab. All rights reserved.
//

#import "VZMistError.h"

NSInteger const VZMistErrorTemplateEmpty = 30001;
NSInteger const VZMistErrorTemplateNotFount = 30002;
NSInteger const VZMistErrorTemplateExpressionParse = 30003;
NSInteger const VZMistErrorTemplateNotRecognized = 30004;

NSString *const VZMistErrorDomain = @"com.vizlab.Mist.Error";


@implementation VZMistError

+ (instancetype)templateEmptyErrorWithTemplateId:(NSString *)templateId
{
    NSInteger errorCode = VZMistErrorTemplateEmpty;
    return [self errorWithDomain:VZMistErrorDomain
                            code:errorCode
                        userInfo:@{
                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"模板内容空%@（%ld）", templateId, errorCode]
                        }];
}

+ (instancetype)templateNotFoundErrorWithTemplateId:(NSString *)templateId
{
    NSInteger errorCode = VZMistErrorTemplateNotFount;
    return [self errorWithDomain:VZMistErrorDomain
                            code:errorCode
                        userInfo:@{
                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"模板找不到%@（%ld）", templateId, errorCode]
                        }];
}

+ (instancetype)templateParseErrorWithExpression:(NSString *)expression Message:(NSString *)errorMessage
{
    return [self errorWithDomain:VZMistErrorDomain
                            code:VZMistErrorTemplateExpressionParse
                        userInfo:@{
                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"expression: %@\nerror: %@", expression, errorMessage]
                        }];
}

+ (instancetype)templateNotRecognizedType:(NSString *)type
{
    return [self errorWithDomain:VZMistErrorDomain
                            code:VZMistErrorTemplateNotRecognized
                        userInfo:@{
                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"type not recognized: %@", type]
                        }];
}

@end
