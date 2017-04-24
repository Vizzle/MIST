//
//  MistExpressionDemoController.m
//  MIST-Example
//
//  Created by Sleen on 2017/4/5.
//  Copyright © 2017年 vizlab. All rights reserved.
//

#import "MistExpressionDemoController.h"
#import <VZFlexLayout/VZFTextView.h>

@implementation MistExpressionDemoController
{
    CGFloat _keyboardTop;
}

+ (NSString *)toString:(id)obj {
    if (!obj) {
        return @"null";
    }
    if ([obj isKindOfClass:[NSNumber class]] && (strcmp([obj objCType], @encode(BOOL)) == 0 || [obj objCType][0] == 'c')) {
        return [obj boolValue] ? @"true" : @"false";
    }
    if ([obj isKindOfClass:[NSString class]]) {
        return [NSString stringWithFormat:@"'%@'", obj];
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableString *str = [NSMutableString new];
        [str appendString:@"["];
        for (int i = 0; i < [obj count]; i++) {
            if (i > 0) {
                [str appendString:@", "];
            }
            [str appendString:[self toString:obj[i]]];
        }
        [str appendString:@"]"];
        return str;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableString *str = [NSMutableString new];
        [str appendString:@"{"];
        for (int i = 0; i < [obj count]; i++) {
            if (i > 0) {
                [str appendString:@", "];
            }
            NSString *key = ((NSDictionary *)obj).allKeys[i];
            [str appendString:[self toString:key]];
            [str appendString:@": "];
            [str appendString:[self toString:obj[key]]];
        }
        [str appendString:@"}"];
        return str;
    }
    return [obj description];
}

- (instancetype)initWithItem:(id<VZMistItem>)item {
    if (self = [super initWithItem:item]) {
        _keyboardTop = [UIScreen mainScreen].bounds.size.height;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateFrame {
    UIView *tryView = [self viewWithTag:2];
    CGRect frame = tryView.frame;
    frame.origin.y = _keyboardTop - frame.size.height - 64;
    tryView.frame = frame;
    
    UIView *scrollView = [self viewWithTag:1];
    frame = scrollView.frame;
    frame.size.height = tryView.frame.origin.y;
    scrollView.frame = frame;
}

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    CGRect rect = [keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    _keyboardTop = rect.origin.y;
    [self updateFrame];
}

- (void)onTextChange:(id)param body:(NSDictionary *)body {
    [self updateState:@{
                        @"exp": ((UITextField *)body[@"sender"]).text
                        }];
}

- (void)onDisplay:(id)param sender:(VZFTextView *)view {
    view.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    [self updateFrame];
}

@end
