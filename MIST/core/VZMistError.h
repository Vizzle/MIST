//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSInteger const VZMistErrorTemplateEmpty;
extern NSInteger const VZMistErrorTemplateNotFount;
extern NSInteger const VZMistErrorTemplateExpressionParse;
extern NSInteger const VZMistErrorTemplateNotRecognized;

extern NSString *const VZMistErrorDomain;


@interface VZMistError : NSError

+ (instancetype)templateEmptyErrorWithTemplateId:(NSString *)templateId;
+ (instancetype)templateNotFoundErrorWithTemplateId:(NSString *)templateId;
+ (instancetype)templateParseErrorWithExpression:(NSString *)expression Message:(NSString *)errorMessage;
+ (instancetype)templateNotRecognizedType:(NSString *)type;

@end
