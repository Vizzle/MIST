//
//  VZTLexer.h
//  VZFlexEditor
//
//  Created by Sleen on 16/4/14.
//  Copyright © 2016年 O2O. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, VZTTokenType) {
    VZTTokenTypeUnknown,
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
};

NSString *vzt_tokenName(VZTTokenType type);

@interface VZTToken : NSObject

@property (nonatomic, strong, readonly) id value;
@property (nonatomic, readonly) VZTTokenType type;
@property (nonatomic, readonly) NSRange range;

- (instancetype)initWithValue:(id)value type:(VZTTokenType)type range:(NSRange)range;

@end


@interface VZTLexer : NSObject

@property (nonatomic, strong, readonly) NSString *error;
@property (nonatomic, strong, readonly) VZTToken *lastToken;

@property (nonatomic, assign) NSInteger pointer;
@property (nonatomic, strong) NSMutableArray *lookAheadStack;

- (instancetype)initWithString:(NSString *)str;

- (VZTToken *)nextToken;
- (VZTToken *)lookAhead;
- (VZTToken *)lookAhead:(NSInteger)number;
- (NSString *)getTokenText:(VZTToken *)token;

@end
