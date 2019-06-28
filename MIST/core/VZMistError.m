//
//  Copyright © 2016年 Vizlab. All rights reserved.
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
    NSInteger errorCode = VZMistErrorTemplateExpressionParse;
    return [self errorWithDomain:VZMistErrorDomain
                            code:errorCode
                        userInfo:@{
                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"expression: %@\nerror: %@ (%ld)", expression, errorMessage, errorCode]
                        }];
}

+ (instancetype)templateNotRecognizedType:(NSString *)type
{
    NSInteger errorCode = VZMistErrorTemplateNotRecognized;
    return [self errorWithDomain:VZMistErrorDomain
                            code:errorCode
                        userInfo:@{
                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"type not recognized: %@ (%ld)", type, errorCode]
                        }];
}

@end
