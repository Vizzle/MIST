//
//  VZFNode+Template.mm
//  MIST
//
//  Created by John Wong on 12/19/16.
//  Copyright © 2016 Vizlab. All rights reserved.
//

#import "VZFNode+Template.h"
#import "VZMistTemplateHelper.h"
#import "VZMistTemplateEvent.h"
#import "VZTExpressionNode.h"
#import "VZMist.h"
#import "VZMacros.h"
#import "VZDataStructure.h"
#import <VZFlexLayout/VZFNodeSubClass.h>
#import <VZFlexLayout/VZFScrollView.h>
#import <objc/runtime.h>
#import "VZMistInternal.h"

#define kVZTemplateLoopIndex    @"_index_"
#define kVZTemplateLoopItem     @"_item_"
#define kVZTemplateMistItem     @"_mistitem_"

using namespace std;
using namespace VZ;

namespace VZ
{
inline id __extractValue(id obj, id data)
{
    return [VZMistTemplateHelper extractValueForExpression:obj withContext:data];
}

inline double __numberValue(id obj, id data, double defaultValue = 0)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        if ([[obj lowercaseString] isEqualToString:@"1px"]) {
            return 1 / [UIScreen mainScreen].scale;
        }
        return [obj doubleValue];
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj doubleValue];
    }
    return defaultValue;
}

template <typename T>
inline T __value(id obj, id data, T defaultValue = {});

template <>
inline FlexLength __value(id obj, id data, FlexLength defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        if ([@"auto" isEqualToString:obj]) {
            return FlexLengthAuto;
        } else if ([@"content" isEqualToString:obj]) {
            return FlexLengthContent;
        } else {
            static NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^-?(0|[1-9]\\d*)(\\.\\d+)?([eE][+-]?\\d+)?" options:0 error:nil];
            NSTextCheckingResult *result = [regex firstMatchInString:obj options:0 range:NSMakeRange(0, [obj length])];
            if (result) {
                NSString *suffix = [obj substringFromIndex:result.range.length];
                FlexLengthType type;
                if ([@"%" isEqualToString:suffix]) {
                    type = FlexLengthTypePercent;
                } else if ([@"px" isEqualToString:suffix]) {
                    type = FlexLengthTypePx;
                } else if ([@"cm" isEqualToString:suffix]) {
                    type = FlexLengthTypeCm;
                } else if ([@"mm" isEqualToString:suffix]) {
                    type = FlexLengthTypeMm;
                } else if ([@"q" isEqualToString:suffix]) {
                    type = FlexLengthTypeQ;
                } else if ([@"in" isEqualToString:suffix]) {
                    type = FlexLengthTypeIn;
                } else if ([@"pc" isEqualToString:suffix]) {
                    type = FlexLengthTypePc;
                } else if ([@"pt" isEqualToString:suffix]) {
                    type = FlexLengthTypePt;
                    //                } else if ([@"em" isEqualToString:suffix]) {
                    //                    type = FlexLengthTypeEm;
                    //                } else if ([@"ex" isEqualToString:suffix]) {
                    //                    type = FlexLengthTypeEx;
                    //                } else if ([@"ch" isEqualToString:suffix]) {
                    //                    type = FlexLengthTypeCh;
                    //                } else if ([@"rem" isEqualToString:suffix]) {
                    //                    type = FlexLengthTypeRem;
                } else if ([@"vw" isEqualToString:suffix]) {
                    type = FlexLengthTypeVw;
                } else if ([@"vh" isEqualToString:suffix]) {
                    type = FlexLengthTypeVh;
                } else if ([@"vmin" isEqualToString:suffix]) {
                    type = FlexLengthTypeVmin;
                } else if ([@"vmax" isEqualToString:suffix]) {
                    type = FlexLengthTypeVmax;
                } else {
                    type = FlexLengthTypeDefault;
                }
                NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                nf.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *number = [nf numberFromString:[obj substringWithRange:result.range]];
                return flexLength([number floatValue], type);
            }
        }
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return flexLength([obj floatValue], FlexLengthTypeDefault);
    }
    return defaultValue;
}

template <>
inline VZFlexLayoutAlignment __value(id obj, id data, VZFlexLayoutAlignment defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"auto" : @(VZFlexInherit),
            @"start" : @(VZFlexStart),
            @"center" : @(VZFlexCenter),
            @"end" : @(VZFlexEnd),
            @"stretch" : @(VZFlexStretch),
            @"space-between" : @(VZFlexSpaceBetween),
            @"space-around" : @(VZFlexSpaceAround),
            @"baseline" : @(VZFlexBaseline),
        };
        obj = dict[obj];
        return obj ? (VZFlexLayoutAlignment)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline VZFlexLayoutWrapMode __value(id obj, id data, VZFlexLayoutWrapMode defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj boolValue] ? VZFlexWrap : VZFlexNoWrap;
    } else if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"nowrap" : @(VZFlexNoWrap),
            @"wrap" : @(VZFlexWrap),
            @"wrap-reverse" : @(VZFlexWrapReverse),
        };
        obj = dict[obj];
        return obj ? (VZFlexLayoutWrapMode)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline VZFlexLayoutDirection __value(id obj, id data, VZFlexLayoutDirection defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"horizontal" : @(VZFlexHorizontal),
            @"vertical" : @(VZFlexVertical),
            @"horizontal-reverse" : @(VZFlexHorizontalReverse),
            @"vertical-reverse" : @(VZFlexVerticalReverse),
        };
        obj = dict[obj];
        return obj ? (VZFlexLayoutDirection)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline VZ::ScrollDirection __value(id obj, id data, VZ::ScrollDirection defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"none" : @(VZ::ScrollNone),
            @"horizontal" : @(VZ::ScrollHorizontal),
            @"vertical" : @(VZ::ScrollVertical),
            @"both" : @(VZ::ScrollBoth),
        };
        obj = dict[obj];
        return obj ? (VZ::ScrollDirection)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline VZ::PagingDirection __value(id obj, id data, VZ::PagingDirection defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"horizontal" : @(VZ::PagingHorizontal),
            @"vertical" : @(VZ::PagingVertical),
        };
        obj = dict[obj];
        return obj ? (VZ::PagingDirection)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline UIViewContentMode __value(id obj, id data, UIViewContentMode defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"scale-to-fill" : @(UIViewContentModeScaleToFill),
            @"scale-aspect-fit" : @(UIViewContentModeScaleAspectFit),
            @"scale-aspect-fill" : @(UIViewContentModeScaleAspectFill),
            @"center" : @(UIViewContentModeCenter),
            @"top" : @(UIViewContentModeTop),
            @"bottom" : @(UIViewContentModeBottom),
            @"left" : @(UIViewContentModeLeft),
            @"right" : @(UIViewContentModeRight),
            @"top-left" : @(UIViewContentModeTopLeft),
            @"top-right" : @(UIViewContentModeTopRight),
            @"bottom-left" : @(UIViewContentModeBottomLeft),
            @"bottom-right" : @(UIViewContentModeBottomRight),
        };
        obj = dict[obj];
        return obj ? (UIViewContentMode)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline NSTextAlignment __value(id obj, id data, NSTextAlignment defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"left" : @(NSTextAlignmentLeft),
            @"center" : @(NSTextAlignmentCenter),
            @"right" : @(NSTextAlignmentRight),
            @"justify" : @(NSTextAlignmentJustified),
            @"natural" : @(NSTextAlignmentNatural),
        };
        obj = dict[obj];
        return obj ? (NSTextAlignment)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline NSLineBreakMode __value(id obj, id data, NSLineBreakMode defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"word" : @(NSLineBreakByWordWrapping),
            @"char" : @(NSLineBreakByCharWrapping),
            @"clip" : @(NSLineBreakByClipping),
            @"truncating-head" : @(NSLineBreakByTruncatingHead),
            @"truncating-middle" : @(NSLineBreakByTruncatingMiddle),
            @"truncating-tail" : @(NSLineBreakByTruncatingTail),
        };
        obj = dict[obj];
        return obj ? (NSLineBreakMode)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline VZFTextLineBreakMode __value(id obj, id data, VZFTextLineBreakMode defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"word" : @(VZFTextLineBreakByWord),
            @"char" : @(VZFTextLineBreakByChar),
        };
        obj = dict[obj];
        return obj ? (VZFTextLineBreakMode)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline VZFTextTruncationMode __value(id obj, id data, VZFTextTruncationMode defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"none" : @(VZFTextTruncatingNone),
            @"clip" : @(VZFTextTruncatingClip),
            @"truncating-head" : @(VZFTextTruncatingHead),
            @"truncating-middle" : @(VZFTextTruncatingMiddle),
            @"truncating-tail" : @(VZFTextTruncatingTail),
        };
        obj = dict[obj];
        return obj ? (VZFTextTruncationMode)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline VZFTextVerticalAlignment __value(id obj, id data, VZFTextVerticalAlignment defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"top" : @(VZFTextVerticalAlignmentTop),
            @"center" : @(VZFTextVerticalAlignmentCenter),
            @"bottom" : @(VZFTextVerticalAlignmentBottom),
        };
        obj = dict[obj];
        return obj ? (VZFTextVerticalAlignment)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline UIBaselineAdjustment __value(id obj, id data, UIBaselineAdjustment defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"none" : @(UIBaselineAdjustmentNone),
            @"baseline" : @(UIBaselineAdjustmentAlignBaselines),
            @"center" : @(UIBaselineAdjustmentAlignCenters),
        };
        obj = dict[obj];
        return obj ? (UIBaselineAdjustment)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline UIControlState __value(id obj, id data, UIControlState defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"normal" : @(UIControlStateNormal),
            @"highlighted" : @(UIControlStateHighlighted),
            @"disabled" : @(UIControlStateDisabled),
            @"selected" : @(UIControlStateSelected),
        };
        obj = dict[obj];
        return obj ? (UIControlState)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline VZFFontStyle __value(id obj, id data, VZFFontStyle defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"ultra-light" : @(VZFFontStyleUltraLight),
            @"thin" : @(VZFFontStyleThin),
            @"light" : @(VZFFontStyleLight),
            @"normal" : @(VZFFontStyleNormal),
            @"medium" : @(VZFFontStyleMedium),
            @"bold" : @(VZFFontStyleBold),
            @"heavy" : @(VZFFontStyleHeavy),
            @"black" : @(VZFFontStyleBlack),
            @"italic" : @(VZFFontStyleItalic),
            @"bold-italic" : @(VZFFontStyleBoldItalic),
        };
        obj = dict[obj];
        return obj ? (VZFFontStyle)[obj integerValue] : defaultValue;
    }
    return defaultValue;
}

template <>
inline NSString *__value(id obj, id data, NSString *defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *num = (NSNumber *)obj;
        return [num stringValue];
    }
    return defaultValue;
}

template <>
inline NSAttributedString *__value(id obj, id data, NSAttributedString *defaultValue)
{
    NSString *str = __value<NSString *>(obj, data);
    if (!str) {
        return defaultValue;
    } else if (str.length == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }

    return [VZMistTemplateHelper attributedStringFromHtml:str];
}

template <>
inline id __value(id obj, id data, id defaultValue)
{
    return __extractValue(obj, data) ?: defaultValue;
}

template <>
inline std::string __value(id obj, id data, std::string defaultValue)
{
    return [__value<NSString *>(obj, data, nil) UTF8String] ?: defaultValue;
}

template <>
inline UIColor *__value(id obj, id data, UIColor *defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[UIColor class]]) {
        return obj;
    }
    return [VZMistTemplateHelper colorFromString:obj] ?: defaultValue;
}

template <>
inline UIImage *__value(id obj, id data, UIImage *defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        UIImage *image = [VZMistTemplateHelper imageNamed:(NSString *)obj];
        if (image) {
            return image;
        }

        UIColor *color = __value<UIColor *>(obj, data);
        if (color) {
            return [VZMistTemplateHelper imageWithColor:color size:CGSizeMake(1, 1)];
        }
    } else if ([obj isKindOfClass:[UIImage class]]) {
        return obj;
    }
    return defaultValue;
}

template <>
inline NSURL *__value(id obj, id data, NSURL *defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        return [NSURL URLWithString:(NSString *)obj] ?: defaultValue;
    }
    return defaultValue;
}

template <>
inline UIFont *__value(id obj, id data, UIFont *defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [UIFont systemFontOfSize:[obj floatValue]];
    }
    UIFontDescriptorSymbolicTraits traits = UIFontDescriptorSymbolicTraits();
    CGFloat fontSize = [UIFont systemFontSize];
    NSString *fontName = nil;
    if ([obj isKindOfClass:[NSString class]]) {
        for (NSString *desc in [(NSString *)obj componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
            if ([@"bold" isEqualToString:desc]) {
                traits |= UIFontDescriptorTraitBold;
            } else if ([@"italic" isEqualToString:desc]) {
                traits |= UIFontDescriptorTraitItalic;
            } else {
                CGFloat size = __numberValue(desc, data);
                if (size > 0) {
                    fontSize = size;
                    continue;
                } else {
                    fontName = desc;
                }
            }
        }
        UIFontDescriptor *fontDescriptor;
        if (fontName.length > 0) {
            fontDescriptor = [UIFontDescriptor fontDescriptorWithName:fontName size:fontSize];
        } else {
            fontDescriptor = [[UIFontDescriptor alloc] init];
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:fontSize];
        }
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:traits];
        return [UIFont fontWithDescriptor:fontDescriptor size:0];
    }
    return nil;
}

template <>
inline CGSize __value(id obj, id data, CGSize defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
        float size = __numberValue(obj, data);
        return CGSizeMake(size, size);
    } else if ([obj isKindOfClass:[NSArray class]] && [(NSArray *)obj count] > 0) {
        NSArray *array = obj;
        NSCAssert(array.count <= 2, @"");
        CGSize size;
        if (array.count == 1) {
            size.width = size.height = __numberValue(array[0], data);
        } else {
            size.width = __numberValue(array[0], data);
            size.height = __numberValue(array[1], data);
        }
        return size;
    }
    return defaultValue;
}

template <typename T>
inline StatefulValue<T *> __statefulValue(id obj, id data)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        return __value<T *>(obj, data);
    }
    StatefulValue<T *> ret = StatefulValue<T *>();
    if ([obj isKindOfClass:[NSDictionary class]]) {
        for (id key in (NSDictionary *)obj) {
            UIControlState state = __value<UIControlState>(key, data);
            ret[state] = __value<T *>(obj[key], data);
        }
    }
    return ret;
}

template <>
inline UIKeyboardType __value(id obj, id data, UIKeyboardType defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"default" : @(UIKeyboardTypeDefault),
            @"ascii-capable" : @(UIKeyboardTypeASCIICapable),
            @"number-punctuation" : @(UIKeyboardTypeNumbersAndPunctuation),
            @"url" : @(UIKeyboardTypeURL),
            @"number" : @(UIKeyboardTypeNumberPad),
            @"phone" : @(UIKeyboardTypePhonePad),
            @"name-phone" : @(UIKeyboardTypeNamePhonePad),
            @"email" : @(UIKeyboardTypeEmailAddress),
            @"decimal" : @(UIKeyboardTypeDecimalPad),
            @"twitter" : @(UIKeyboardTypeTwitter),
            @"web" : @(UIKeyboardTypeWebSearch),
        };
        obj = dict[obj];
        return obj ? (UIKeyboardType)[obj integerValue] : UIKeyboardTypeDefault;
    }

    return UIKeyboardTypeDefault;
}

template <>
inline UIKeyboardAppearance __value(id obj, id data, UIKeyboardAppearance defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"default" : @(UIKeyboardAppearanceDefault),
            @"dark" : @(UIKeyboardAppearanceDark),
            @"light" : @(UIKeyboardAppearanceLight),
        };
        obj = dict[obj];
        return obj ? (UIKeyboardAppearance)[obj integerValue] : UIKeyboardAppearanceDefault;
    }

    return UIKeyboardAppearanceDefault;
}

template <>
inline UIReturnKeyType __value(id obj, id data, UIReturnKeyType defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"default" : @(UIReturnKeyDefault),
            @"go" : @(UIReturnKeyGo),
            @"google" : @(UIReturnKeyGoogle),
            @"join" : @(UIReturnKeyJoin),
            @"next" : @(UIReturnKeyNext),
            @"route" : @(UIReturnKeyRoute),
            @"search" : @(UIReturnKeySearch),
            @"send" : @(UIReturnKeySend),
            @"yahoo" : @(UIReturnKeyYahoo),
            @"done" : @(UIReturnKeyDone),
            @"emergency-call" : @(UIReturnKeyEmergencyCall),
        };
        obj = dict[obj];
        return obj ? (UIReturnKeyType)[obj integerValue] : UIReturnKeyDefault;
    }

    return UIReturnKeyDefault;
}

template <>
inline UITextFieldViewMode __value(id obj, id data, UITextFieldViewMode defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"never" : @(UITextFieldViewModeNever),
            @"while-editing" : @(UITextFieldViewModeWhileEditing),
            @"unless-editing" : @(UITextFieldViewModeUnlessEditing),
            @"always" : @(UITextFieldViewModeAlways),
        };
        obj = dict[obj];
        return obj ? (UITextFieldViewMode)[obj integerValue] : UITextFieldViewModeNever;
    }

    return UITextFieldViewModeNever;
}

template <>
inline NSDictionary *__value(id obj, id data, NSDictionary *defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return obj;
    }
    return nil;
}

template <>
inline NSArray<NSString *> *__value(id obj, id data, NSArray<NSString *> *defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSArray class]]) {
        return obj;
    }
    return nil;
}

template <>
inline MKMapType __value(id obj, id data, MKMapType defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSString class]]) {
        static NSDictionary *dict = @{
            @"standard" : @(MKMapTypeStandard),
            @"satellite" : @(MKMapTypeSatellite),
            @"hybrid" : @(MKMapTypeHybrid),
        };
        obj = dict[obj];
        return obj ? (MKMapType)[obj integerValue] : MKMapTypeStandard;
    }
    return MKMapTypeStandard;
}


template <>
inline MKCoordinateRegion __value(id obj, id data, MKCoordinateRegion defaultValue)
{
    obj = __extractValue(obj, data);
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return (MKCoordinateRegion){
            .center = {
                    [obj[@"latitude"] doubleValue],
                    [obj[@"longitude"] doubleValue],
            }, .span = {[obj[@"latitude-delta"] doubleValue], [obj[@"longitude-delta"] doubleValue]}};
    }
    return defaultValue;
}
}


#pragma mark - Display Event


@implementation VZFNode (DisplayEvent)

+ (void)load
{
    Method m1 = class_getInstanceMethod(self, @selector(didMount));
    Method m2 = class_getInstanceMethod(self, @selector(template_didMount));
    method_exchangeImplementations(m1, m2);
}

static const void *displayEventKey = &displayEventKey;

- (VZMistTemplateEvent *)displayEvent
{
    return objc_getAssociatedObject(self, displayEventKey);
}

- (void)setDisplayEvent:(VZMistTemplateEvent *)event
{
    objc_setAssociatedObject(self, displayEventKey, event, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)template_didMount
{
    [self template_didMount];

    VZMistTemplateEvent *displayEvent = [self displayEvent];
    if (displayEvent) {
        [displayEvent invokeWithSender:[self mountedView]];
    }
}

@end

// TODO 有 display 事件时，不能被拍平
//@implementation VZFStackNode (DisplayEvent)
//
//+ (void)load
//{
//    Method m1 = class_getClassMethod(self, @selector(shouldFlattenStackView:));
//    Method m2 = class_getClassMethod(self, @selector(template_shouldFlattenStackView:));
//    method_exchangeImplementations(m1, m2);
//}
//
//+ (BOOL)template_shouldFlattenStackView:(const NodeSpecs&)specs {
//    if has display event return NO;
//    return [self template_shouldFlattenStackView:specs];
//}
//
//@end

#pragma mark -


@implementation VZFNode (Template)

+ (instancetype)nodeFromTemplate:(VZMistTemplate *)tpl
                            data:(VZTExpressionContext *)data
                            item:(id<VZMistItem>)item
                    mistInstance:(VZMist *)mistInstance
{
    BOOL asyncDisplay = NO;

    if ([item conformsToProtocol:@protocol(VZMistAsyncDisplayItem)] && [item respondsToSelector:@selector(asyncDisplay)]) {
        //暂时只判断[(O2OFNodeListItem *)item asyncDisplay]，不判断模板里的
        asyncDisplay = tpl.asyncDisplay && [(id<VZMistAsyncDisplayItem>)item asyncDisplay];
    }

    return [self nodeFromTemplate:tpl.tplParsedResult
                             data:data
                             item:item
                     mistInstance:mistInstance
                       templateId:tpl.tplId
                           nodeId:@"root"
                       isRootNode:YES
                     asyncDisplay:asyncDisplay];
}

+ (instancetype)nodeFromTemplate:(NSDictionary *)tpl
                            data:(VZTExpressionContext *)data
                            item:(id<VZMistItem>)item
                    mistInstance:(VZMist *)mistInstance
                      templateId:(NSString *)tplId
                          nodeId:(NSString *)nodeId
                      isRootNode:(BOOL)isRootNode
                    asyncDisplay:(BOOL)asyncDisplay
{
    NSArray *vars = tpl[@"vars"];
    if ([vars isKindOfClass:[NSDictionary class]]) {
        vars = @[ vars ];
    }

    NSMutableArray *pushedVars = [NSMutableArray array];
    [data pushVariableWithKey:kVZTemplateNodeId value:nodeId];
    [data pushVariableWithKey:kVZTemplateMistItem value:item];
    @defer
    {
        [data popVariableWithKey:kVZTemplateMistItem];
        [data popVariableWithKey:kVZTemplateNodeId];
        for (NSString *key in pushedVars) {
            [data popVariableWithKey:key];
        }
    };

    if ([vars isKindOfClass:[NSArray class]]) {
        for (id obj in vars) {
            NSDictionary *vars = __extractValue(__vzDictionary(obj, nil), data);
            if (vars) {
                for (NSString *key in vars) {
                    id value = __extractValue(vars[key], data);
                    if ([pushedVars containsObject:key]) {
                        [data setValue:value forKey:key];
                    } else {
                        [data pushVariableWithKey:key value:value];
                        [pushedVars addObject:key];
                    }
                }
            }
        }
    }

    if (__vzBool(__extractValue(tpl[@"gone"], data), NO)) {
        return nil;
    }

    VZFNode *node;
    NodeSpecs specs = NodeSpecs();

    specs.asyncDisplay = asyncDisplay;

    VZMistTemplateEvent *tapEvent = [VZMistTemplateEvent eventWithName:@"on-tap" dict:tpl expressionContext:data item:item];
    if (tapEvent) {
        specs.gesture = [VZFBlockGesture tapGesture:^(id sender) {
            [tapEvent invokeWithSender:sender];
        }];
    }
    
    NSString *classStr = __vzString(__extractValue(tpl[@"class"], data), nil);
    NSArray *classes = [classStr componentsSeparatedByString:@" "];
    if (classes.count > 0) {
        NSMutableDictionary *mutableStyle = [NSMutableDictionary dictionary];
        for (NSString *cls in classes) {
            NSDictionary *style = __vzDictionary([item tpl].styles[cls], nil);
            if (style) {
                [mutableStyle setValuesForKeysWithDictionary:style];
            }
        }
        [mutableStyle setValuesForKeysWithDictionary:tpl[@"style"]];
        NSMutableDictionary *mutableTpl = tpl.mutableCopy;
        mutableTpl[@"style"] = mutableStyle;
        tpl = mutableTpl;
    }

    [self bindNodeSpecs:specs fromTemplate:tpl data:data];
    if (isRootNode && specs.identifier.length() == 0 && tplId.length > 0) {
        specs.identifier = string([tplId UTF8String]);
    }

    NSString *type = __value<NSString *>(tpl[@"type"], data);
    if (type.length == 0) {
        type = tpl[@"children"] ? @"stack" : @"node";
    }


    node = [mistInstance processTag:type
                          withSpecs:specs
                           template:tpl
                               item:item
                               data:data];

    if (node) {
    } else if ([type isEqualToString:@"node"]) {
        Class viewClass = nil;
        if (tpl[@"view-class"]) {
            viewClass = NSClassFromString(__value<NSString *>(tpl[@"view-class"], data));
        }
        node = [VZFNode newWithView:viewClass ?: [UIView class] NodeSpecs:specs];
    } else {
        StackNodeSpecs stackSpecs = StackNodeSpecs();
        [self bindStackNodeSpecs:stackSpecs fromTemplate:tpl data:data];

        NSArray *childTpl = ((NSArray *)tpl[@"children"]);
        vector<VZFNode *> list = {};
        if ([childTpl isKindOfClass:[NSArray class]]) {
            // 模版衍生
            for (__strong NSDictionary *obj in childTpl) {
                // node本身可以是表达式
                if ([obj isKindOfClass:[VZTExpressionNode class]]) {
                    obj = __vzDictionary(__extractValue(obj, data), @{});
                }

                // 引用ref作为node，并将其它属性覆盖ref里的属性
                if (obj[@"ref"]) {
                    NSMutableDictionary *ref = __vzDictionary(__extractValue(obj[@"ref"], data), @{}).mutableCopy;
                    for (NSString *key in obj) {
                        ref[key] = obj[key];
                    }
                    obj = ref;
                }

                if (obj[@"repeat"]) {
                    id repeat = [VZMistTemplateHelper extractValueForExpression:obj[@"repeat"] withContext:data];

                    NSArray *items = nil;
                    NSInteger count = 0;
                    if ([repeat isKindOfClass:[NSArray class]]) {
                        items = repeat;
                        count = items.count;
                    } else if ([repeat isKindOfClass:[NSNumber class]]) {
                        count = __vzInt(repeat, 0);
                    } else if (repeat) {
                        NSAssert(NO, @"'repeat' must be a number or an array");
                        NSLog(@"%@: 'repeat' must be a number or an array, but '%@' is provided", self.class, repeat);
                    }

                    [data pushVariableWithKey:kVZTemplateLoopIndex value:nil];
                    [data pushVariableWithKey:kVZTemplateLoopItem value:nil];
                    for (int i = 0; i < count; i++) {
                        [data setValue:@(i) forKey:kVZTemplateLoopIndex];
                        if (items) {
                            [data setValue:items[i] forKey:kVZTemplateLoopItem];
                        }
                        VZFNode *childNode = [self nodeFromTemplate:obj
                                                               data:data
                                                               item:item
                                                       mistInstance:mistInstance
                                                         templateId:tplId
                                                             nodeId:[nodeId stringByAppendingFormat:@">%lu", list.size()]
                                                         isRootNode:NO
                                                       asyncDisplay:asyncDisplay];
                        list.push_back(childNode);
                    }
                    [data popVariableWithKey:kVZTemplateLoopIndex];
                    [data popVariableWithKey:kVZTemplateLoopItem];
                } else {
                    VZFNode *childNode = [self nodeFromTemplate:obj
                                                           data:data
                                                           item:item
                                                   mistInstance:mistInstance
                                                     templateId:tplId
                                                         nodeId:[nodeId stringByAppendingFormat:@">%lu", list.size()]
                                                     isRootNode:NO
                                                   asyncDisplay:asyncDisplay];

                    list.push_back(childNode);
                }
            }
        }
        vector<VZFStackChildNode> children{};
        children.reserve(list.size());
        for (const auto &l : list) {
            children.push_back({l});
        }

        if ([@"stack" isEqualToString:type]) {
            node = [VZFStackNode newWithStackAttributes:stackSpecs NodeSpecs:specs Children:children];
        } else if ([@"scroll" isEqualToString:type]) {
            ScrollNodeSpecs scrollSpecs = ScrollNodeSpecs();
            [self bindScrollNodeSpecs:scrollSpecs fromTemplate:tpl data:data];
            
            NSString *backingView = __value<NSString *>(tpl[@"backing-view"], data);
            Class backingViewClass = nil;
            if (backingView.length > 0) {
                backingViewClass = NSClassFromString(backingView);
            }
            if (!backingViewClass || ![backingViewClass conformsToProtocol:@protocol(VZFNodeBackingViewInterface)]) {
                backingViewClass = [VZFScrollView class];
            }
            
            node = [VZFScrollNode newWithScrollAttributes:scrollSpecs StackAttributes:stackSpecs NodeSpecs:specs BackingViewClass:backingViewClass Children:list];
        } else if ([@"paging" isEqualToString:type]) {
            PagingNodeSpecs pagingSpecs = PagingNodeSpecs();
            [self bindPagingNodeSpecs:pagingSpecs fromTemplate:tpl data:data item:item];

            VZMistTemplateEvent *switchEvent = [VZMistTemplateEvent eventWithName:@"on-switch" dict:tpl expressionContext:data item:item];
            if (switchEvent) {
                pagingSpecs.switched = [VZFBlockAction action:^(id sender) {
                    [switchEvent invokeWithSender:sender];
                }];
            }

            node = [VZFPagingNode newWithPagingAttributes:pagingSpecs NodeSpecs:specs Children:list];
        } else {
            mistInstance.errorCallback([VZMistError templateNotRecognizedType:type]);
        }
    }

    if (node) {
        VZMistTemplateEvent *createEvent = [VZMistTemplateEvent eventWithName:@"on-create" dict:tpl expressionContext:data item:item];
        if (createEvent) {
            [createEvent invokeWithSender:node];
        }

        VZMistTemplateEvent *displayEvent = [VZMistTemplateEvent eventWithName:@"on-display" dict:tpl expressionContext:data item:item];
        if (displayEvent) {
            [node setDisplayEvent:displayEvent];
        }
    }

    return node;
}

// 因为太多if会被PMD扫描报圈复杂度太高，此处用函数替换掉if
template <typename T, typename U>
static inline void vz_bindProperty(U &prop, id value, id data, T defaultValue = {})
{
    if (value) {
        prop = __value<T>(value, data, defaultValue);
    }
}
template <typename T, typename U>
static inline void vz_bindNumberProperty(U &prop, id value, id data, T defaultValue = {})
{
    if (value) {
        prop = (T)__numberValue(value, data, defaultValue);
    }
}
template <typename T>
static inline void vz_bindStatefulProperty(StatefulValue<T *> &prop, id value, id data)
{
    if (value) {
        prop = __statefulValue<T>(value, data);
    }
}
#define VZ_BIND_PROPERTY(type, prop, value, ...) vz_bindProperty<type>(prop, value, __VA_ARGS__)
#define VZ_BIND_NUMBER_PROPERTY(type, prop, value, ...) vz_bindNumberProperty<type>(prop, value, __VA_ARGS__)
#define VZ_BIND_STATEFUL_PROPERTY(type, prop, value, data) vz_bindStatefulProperty<type>(prop, value, data)
#define VZ_BIND_EVENT_PROPERTY(prop, eventName, tpl, data, item)                                      \
    {                                                                                                 \
        VZMistTemplateEvent *event = [VZMistTemplateEvent eventWithName:eventName                     \
                                                                   dict:tpl                           \
                                                      expressionContext:data                          \
                                                                   item:item];                        \
        if (event) {                                                                                  \
            prop = ^(NSDictionary * body) {                                                           \
                for (NSString * key in body) {                                                        \
                    [event addEventParamWithName:key object:body[key]];                               \
                }                                                                                     \
                [event invokeWithSender:body[@"sender"]];                                             \
            };                                                                                        \
        }                                                                                             \
    }


+ (void)bindTextNodeSpecs:(TextNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    NSDictionary *style = tpl[@"style"];
    VZ_BIND_PROPERTY(NSAttributedString *, specs._attributedString, style[@"html-text"], data);
    /* gencode start TextNodeSpecs */
    VZ_BIND_PROPERTY(NSString *, specs.text, style[@"text"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.color, style[@"color"], data);
    VZ_BIND_NUMBER_PROPERTY(float, specs.fontSize, style[@"font-size"], data);
    VZ_BIND_PROPERTY(NSString *, specs.fontName, style[@"font-name"], data);
    VZ_BIND_PROPERTY(VZFFontStyle, specs.fontStyle, style[@"font-style"], data);
    VZ_BIND_NUMBER_PROPERTY(float, specs.miniScaleFactor, style[@"mini-scale-factor"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.adjustsFontSize, style[@"adjusts-font-size"], data);
    VZ_BIND_PROPERTY(UIBaselineAdjustment, specs.baselineAdjustment, style[@"baseline-adjustment"], data);
    VZ_BIND_PROPERTY(NSTextAlignment, specs.alignment, style[@"alignment"], data);
    VZ_BIND_PROPERTY(VZFTextVerticalAlignment, specs.verticalAlignment, style[@"vertical-alignment"], data);
    VZ_BIND_PROPERTY(VZFTextLineBreakMode, specs.lineBreakMode, style[@"line-break-mode"], data);
    VZ_BIND_PROPERTY(VZFTextTruncationMode, specs.truncationMode, style[@"truncation-mode"], data);
    VZ_BIND_NUMBER_PROPERTY(unsigned int, specs.lines, style[@"lines"], data, DefaultFlexAttributesValue::lines);
    VZ_BIND_NUMBER_PROPERTY(float, specs.kern, style[@"kern"], data);
    VZ_BIND_NUMBER_PROPERTY(float, specs.lineSpacing, style[@"line-spacing"], data);
    /* gencode end */
}

+ (void)bindImageNodeSpecs:(ImageNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start ImageNodeSpecs */
    VZ_BIND_PROPERTY(UIImage *, specs.image, style[@"image"], data);
    VZ_BIND_PROPERTY(NSString *, specs.imageUrl, style[@"image-url"], data);
    VZ_BIND_PROPERTY(UIImage *, specs.errorImage, style[@"error-image"], data);
    VZ_BIND_PROPERTY(UIViewContentMode, specs.contentMode, style[@"content-mode"], data);
    /* gencode end */

    VZMistTemplateEvent *completeEvent = [VZMistTemplateEvent eventWithName:@"on-complete" dict:tpl expressionContext:data item:item];
    if (completeEvent) {
        specs.completion = [VZFBlockAction action:^(id sender) {
            [completeEvent invokeWithSender:sender];
        }];
    }

    NSMutableDictionary *context = [NSMutableDictionary dictionary];
    [context addEntriesFromDictionary:__vzDictionary(__extractValue(tpl, data), @{})];
    specs.context = context;
}

+ (void)bindButtonNodeSpecs:(ButtonNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start ButtonNodeSpecs */
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.fontSize, style[@"font-size"], data);
    VZ_BIND_PROPERTY(NSString *, specs.fontName, style[@"font-name"], data);
    VZ_BIND_PROPERTY(VZFFontStyle, specs.fontStyle, style[@"font-style"], data);
    VZ_BIND_STATEFUL_PROPERTY(NSString, specs.title, style[@"title"], data);
    VZ_BIND_STATEFUL_PROPERTY(UIColor, specs.titleColor, style[@"title-color"], data);
    VZ_BIND_STATEFUL_PROPERTY(UIImage, specs.backgroundImage, style[@"background-image"], data);
    VZ_BIND_STATEFUL_PROPERTY(UIImage, specs.image, style[@"image"], data);
    VZ_BIND_PROPERTY(CGSize, specs.enlargeSize, style[@"enlarge-size"], data, DefaultButtonAttributesValue::enlargeSize);
    /* gencode end */
}

+ (void)bindScrollNodeSpecs:(ScrollNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start ScrollNodeSpecs */
    VZ_BIND_PROPERTY(ScrollDirection, specs.scrollDirection, style[@"scroll-direction"], data, DefaultFlexAttributesValue::scrollDirection);
    VZ_BIND_NUMBER_PROPERTY(bool, specs.scrollEnabled, style[@"scroll-enabled"], data, DefaultFlexAttributesValue::scrollEnabled);
    VZ_BIND_NUMBER_PROPERTY(bool, specs.paging, style[@"paging"], data);

    /* gencode end */
}

+ (void)bindPagingNodeSpecs:(PagingNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start PagingNodeSpecs */
    VZ_BIND_PROPERTY(PagingDirection, specs.direction, style[@"direction"], data);
    VZ_BIND_NUMBER_PROPERTY(bool, specs.scrollEnabled, style[@"scroll-enabled"], data, PagingNodeSpecsDefault::scrollEnabled);
    VZ_BIND_NUMBER_PROPERTY(bool, specs.paging, style[@"paging"], data, PagingNodeSpecsDefault::scrollEnabled);
    VZ_BIND_NUMBER_PROPERTY(float, specs.autoScroll, style[@"auto-scroll"], data);
    VZ_BIND_NUMBER_PROPERTY(bool, specs.infiniteLoop, style[@"infinite-loop"], data);
    VZ_BIND_NUMBER_PROPERTY(float, specs.animationDuration, tpl[@"animation-duration"], data, PagingNodeSpecsDefault::animationDuration);
    VZ_BIND_NUMBER_PROPERTY(bool, specs.pageControl, style[@"page-control"], data);
    VZ_BIND_PROPERTY(FlexLength, specs.pageControlMarginLeft, style[@"page-control-margin-left"], data, PagingNodeSpecsDefault::margin);
    VZ_BIND_PROPERTY(FlexLength, specs.pageControlMarginRight, style[@"page-control-margin-right"], data, PagingNodeSpecsDefault::margin);
    VZ_BIND_PROPERTY(FlexLength, specs.pageControlMarginTop, style[@"page-control-margin-top"], data, PagingNodeSpecsDefault::margin);
    VZ_BIND_PROPERTY(FlexLength, specs.pageControlMarginBottom, style[@"page-control-margin-bottom"], data, PagingNodeSpecsDefault::margin);
    VZ_BIND_NUMBER_PROPERTY(float, specs.pageControlScale, style[@"page-control-scale"], data, PagingNodeSpecsDefault::pageControlScale);
    VZ_BIND_PROPERTY(UIColor *, specs.pageControlColor, style[@"page-control-color"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.pageControlSelectedColor, style[@"page-control-selected-color"], data);

    /* gencode end */
}


+ (void)bindIndicatorNodeSpecs:(IndicatorNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start IndicatorNodeSpecs */
    VZ_BIND_PROPERTY(UIColor *, specs.color, style[@"color"], data);

    /* gencode end */
}

+ (void)bindLineNodeSpecs:(LineNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start LineNodeSpecs */
    VZ_BIND_PROPERTY(UIColor *, specs.color, style[@"color"], data);
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.dashLength, style[@"dash-length"], data);
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.spaceLength, style[@"space-length"], data);
    /* gencode end */
}

+ (void)bindStackNodeSpecs:(StackNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start StackNodeSpecs */
    VZ_BIND_PROPERTY(VZFlexLayoutWrapMode, specs.wrap, style[@"wrap"], data, DefaultStackAttributesValue::wrap);
    VZ_BIND_NUMBER_PROPERTY(unsigned int, specs.lines, style[@"lines"], data);
    VZ_BIND_NUMBER_PROPERTY(unsigned int, specs.itemsPerLine, style[@"items-per-line"], data);
    VZ_BIND_PROPERTY(VZFlexLayoutDirection, specs.direction, style[@"direction"], data, DefaultStackAttributesValue::direction);
    VZ_BIND_PROPERTY(VZFlexLayoutAlignment, specs.justifyContent, style[@"justify-content"], data, DefaultStackAttributesValue::justifyContent);
    VZ_BIND_PROPERTY(VZFlexLayoutAlignment, specs.alignItems, style[@"align-items"], data, DefaultStackAttributesValue::alignItems);
    VZ_BIND_PROPERTY(VZFlexLayoutAlignment, specs.alignContent, style[@"align-content"], data, DefaultStackAttributesValue::alignContent);
    VZ_BIND_PROPERTY(FlexLength, specs.spacing, style[@"spacing"], data, DefaultStackAttributesValue::spacing);
    VZ_BIND_PROPERTY(FlexLength, specs.lineSpacing, style[@"line-spacing"], data, DefaultStackAttributesValue::lineSpacing);

    /* gencode end */
}

+ (void)bindNodeSpecs:(NodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start NodeSpecs */
    VZ_BIND_PROPERTY(std::string, specs.identifier, tpl[@"identifier"], data);
    VZ_BIND_NUMBER_PROPERTY(NSInteger, specs.tag, tpl[@"tag"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.clip, style[@"clip"], data);
    VZ_BIND_NUMBER_PROPERTY(float, specs.alpha, style[@"alpha"], data, DefaultAttributesValue::alpha);
    VZ_BIND_NUMBER_PROPERTY(int, specs.userInteractionEnabled, style[@"user-interaction-enabled"], data, DefaultAttributesValue::userInteractionEnabled);
    VZ_BIND_PROPERTY(UIColor *, specs.backgroundColor, style[@"background-color"], data, DefaultAttributesValue::backgroundColor);
    VZ_BIND_PROPERTY(UIColor *, specs.highlightBackgroundColor, style[@"highlight-background-color"], data, DefaultAttributesValue::highlightBackgroundColor);
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.cornerRadius, style[@"corner-radius"], data);
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.cornerRadiusTopLeft, style[@"corner-radius-top-left"], data, DefaultAttributesValue::cornerRadiusUndefined);
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.cornerRadiusTopRight, style[@"corner-radius-top-right"], data, DefaultAttributesValue::cornerRadiusUndefined);
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.cornerRadiusBottomLeft, style[@"corner-radius-bottom-left"], data, DefaultAttributesValue::cornerRadiusUndefined);
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.cornerRadiusBottomRight, style[@"corner-radius-bottom-right"], data, DefaultAttributesValue::cornerRadiusUndefined);
    VZ_BIND_NUMBER_PROPERTY(CGFloat, specs.borderWidth, style[@"border-width"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.borderColor, style[@"border-color"], data);
    VZ_BIND_PROPERTY(UIImage *, specs.contents, style[@"contents"], data);
    VZ_BIND_PROPERTY(FlexLength, specs.width, style[@"width"], data, DefaultAttributesValue::width);
    VZ_BIND_PROPERTY(FlexLength, specs.height, style[@"height"], data, DefaultAttributesValue::height);
    VZ_BIND_PROPERTY(FlexLength, specs.maxWidth, style[@"max-width"], data, DefaultAttributesValue::maxWidth);
    VZ_BIND_PROPERTY(FlexLength, specs.maxHeight, style[@"max-height"], data, DefaultAttributesValue::maxHeight);
    VZ_BIND_PROPERTY(FlexLength, specs.minWidth, style[@"min-width"], data, DefaultAttributesValue::minWidth);
    VZ_BIND_PROPERTY(FlexLength, specs.minHeight, style[@"min-height"], data, DefaultAttributesValue::minHeight);
    VZ_BIND_PROPERTY(FlexLength, specs.marginLeft, style[@"margin-left"], data, DefaultAttributesValue::marginLeft);
    VZ_BIND_PROPERTY(FlexLength, specs.marginRight, style[@"margin-right"], data, DefaultAttributesValue::marginRight);
    VZ_BIND_PROPERTY(FlexLength, specs.marginTop, style[@"margin-top"], data, DefaultAttributesValue::marginTop);
    VZ_BIND_PROPERTY(FlexLength, specs.marginBottom, style[@"margin-bottom"], data, DefaultAttributesValue::marginBottom);
    VZ_BIND_PROPERTY(FlexLength, specs.paddingLeft, style[@"padding-left"], data, DefaultAttributesValue::paddingLeft);
    VZ_BIND_PROPERTY(FlexLength, specs.paddingRight, style[@"padding-right"], data, DefaultAttributesValue::paddingRight);
    VZ_BIND_PROPERTY(FlexLength, specs.paddingTop, style[@"padding-top"], data, DefaultAttributesValue::paddingTop);
    VZ_BIND_PROPERTY(FlexLength, specs.paddingBottom, style[@"padding-bottom"], data, DefaultAttributesValue::paddingBottom);
    VZ_BIND_PROPERTY(FlexLength, specs.margin, style[@"margin"], data, DefaultAttributesValue::margin);
    VZ_BIND_PROPERTY(FlexLength, specs.padding, style[@"padding"], data, DefaultAttributesValue::padding);
    VZ_BIND_NUMBER_PROPERTY(float, specs.flexGrow, style[@"flex-grow"], data, DefaultAttributesValue::flexGrow);
    VZ_BIND_NUMBER_PROPERTY(float, specs.flexShrink, style[@"flex-shrink"], data, DefaultAttributesValue::flexShrink);
    VZ_BIND_PROPERTY(FlexLength, specs.flexBasis, style[@"flex-basis"], data, DefaultAttributesValue::flexBasis);
    VZ_BIND_PROPERTY(VZFlexLayoutAlignment, specs.alignSelf, style[@"align-self"], data, DefaultAttributesValue::alignSelf);
    VZ_BIND_NUMBER_PROPERTY(bool, specs.fixed, style[@"fixed"], data, DefaultAttributesValue::fixed);
    VZ_BIND_NUMBER_PROPERTY(int, specs.isAccessibilityElement, style[@"is-accessibility-element"], data, DefaultAttributesValue::userInteractionEnabled);
    VZ_BIND_PROPERTY(NSString *, specs.accessibilityLabel, style[@"accessibility-label"], data);
    /* gencode end */

    NSDictionary *properties = __vzDictionary(__extractValue(style[@"properties"], data), nil);
    NSMutableDictionary *originalProperties = [NSMutableDictionary dictionary];
    if (properties.count > 0) {
        specs.applicator = ^(UIView *view) {
            for (NSString *key in properties) {
                originalProperties[key] = [view valueForKeyPath:key] ?: [NSNull null];
                id value = properties[key];
                value = value == [NSNull null] ? nil : value;
                [view setValue:value forKeyPath:key];
            }
        };
        specs.unapplicator = ^(UIView *view) {
            for (NSString *key in originalProperties) {
                id value = originalProperties[key];
                value = value == [NSNull null] ? nil : value;
                [view setValue:value forKeyPath:key];
            }
        };
    }
}

+ (void)bindTextFieldNodeSpecs:(TextFieldNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start TextFieldNodeSpecs */
    VZ_BIND_PROPERTY(NSString *, specs.text, style[@"text"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.color, style[@"color"], data);
    VZ_BIND_NUMBER_PROPERTY(float, specs.fontSize, style[@"font-size"], data);
    VZ_BIND_PROPERTY(NSString *, specs.fontName, style[@"font-name"], data);
    VZ_BIND_PROPERTY(VZFFontStyle, specs.fontStyle, style[@"font-style"], data);
    VZ_BIND_PROPERTY(NSTextAlignment, specs.alignment, style[@"alignment"], data);
    VZ_BIND_PROPERTY(NSString *, specs.placeholder, style[@"placeholder"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.placeholderColor, style[@"placeholder-color"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.editable, style[@"editable"], data, DefaultControlAttrValue::able);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.secureTextEntry, style[@"secure-text-entry"], data);
    VZ_BIND_PROPERTY(UIKeyboardType, specs.keyboardType, style[@"keyboard-type"], data);
    VZ_BIND_PROPERTY(UIKeyboardAppearance, specs.keyboardAppearance, style[@"keyboard-appearance"], data);
    VZ_BIND_PROPERTY(UIReturnKeyType, specs.returnKeyType, style[@"return-key-type"], data);
    VZ_BIND_PROPERTY(UITextFieldViewMode, specs.clearButtonMode, style[@"clear-button-mode"], data);
    VZ_BIND_NUMBER_PROPERTY(NSUInteger, specs.maxLength, style[@"max-length"], data, DefaultTextFieldAttrValue::defaultMaxLength);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.blurOnSubmit, style[@"blur-on-submit"], data, DefaultControlAttrValue::able);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.autoFocus, style[@"auto-focus"], data, DefaultControlAttrValue::disable);
    VZ_BIND_EVENT_PROPERTY(specs.onFocus, @"on-focus", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onBlur, @"on-blur", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onChange, @"on-change", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onSubmit, @"on-submit", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onEnd, @"on-end", tpl, data, item);
    /* gencode end */
}

+ (void)bindTextViewNodeSpecs:(VZ::TextViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start TextViewNodeSpecs */
    VZ_BIND_PROPERTY(NSString *, specs.text, style[@"text"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.color, style[@"color"], data);
    VZ_BIND_NUMBER_PROPERTY(float, specs.fontSize, style[@"font-size"], data);
    VZ_BIND_PROPERTY(NSString *, specs.fontName, style[@"font-name"], data);
    VZ_BIND_PROPERTY(VZFFontStyle, specs.fontStyle, style[@"font-style"], data);
    VZ_BIND_PROPERTY(NSTextAlignment, specs.alignment, style[@"alignment"], data);
    VZ_BIND_PROPERTY(NSString *, specs.placeholder, style[@"placeholder"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.placeholderColor, style[@"placeholder-color"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.editable, style[@"editable"], data, DefaultControlAttrValue::able);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.autoFocus, style[@"auto-focus"], data, DefaultControlAttrValue::disable);
    VZ_BIND_PROPERTY(UIKeyboardType, specs.keyboardType, style[@"keyboard-type"], data);
    VZ_BIND_PROPERTY(UIKeyboardAppearance, specs.keyboardAppearance, style[@"keyboard-appearance"], data);
    VZ_BIND_PROPERTY(UIReturnKeyType, specs.returnKeyType, style[@"return-key-type"], data);
    VZ_BIND_NUMBER_PROPERTY(NSUInteger, specs.maxLength, style[@"max-length"], data, DefaultTextViewAttrValue::defaultMaxLength);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.blurOnSubmit, style[@"blur-on-submit"], data, DefaultControlAttrValue::disable);
    VZ_BIND_EVENT_PROPERTY(specs.onFocus, @"on-focus", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onBlur, @"on-blur", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onChange, @"on-change", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onSubmit, @"on-submit", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onEnd, @"on-end", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onScroll, @"on-scroll", tpl, data, item);
    /* gencode end */
}

+ (void)bindSwitchNodeSpecs:(VZ::SwitchNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start SwitchNodeSpecs */
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.on, style[@"on"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.enabled, style[@"enabled"], data, DefaultControlAttrValue::able);
    VZ_BIND_PROPERTY(UIColor *, specs.onTintColor, style[@"on-tint-color"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.thumbTintColor, style[@"thumb-tint-color"], data);
    VZ_BIND_EVENT_PROPERTY(specs.onChange, @"on-change", tpl, data, item);
    /* gencode end */
}

+ (void)bindSegmentedControlNodeSpecs:(VZ::SegmentedControlNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start SegmentedControlNodeSpecs */
    VZ_BIND_PROPERTY(NSArray<NSString *> *, specs.items, style[@"items"], data);
    VZ_BIND_EVENT_PROPERTY(specs.onChange, @"on-change", tpl, data, item);
    VZ_BIND_NUMBER_PROPERTY(NSInteger, specs.selectedSegmentedIndex, style[@"selected-segmented-index"], data, DefaultAttributesValue::noSegment);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.enabled, style[@"enabled"], data, DefaultControlAttrValue::able);
    /* gencode end */
}

+ (void)bindPickerNodeSpecs:(VZ::PickerNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start PickerNodeSpecs */
    VZ_BIND_PROPERTY(NSArray<NSString *> *, specs.items, style[@"items"], data);
    VZ_BIND_NUMBER_PROPERTY(NSInteger, specs.selectedIndex, style[@"selected-index"], data, DefaultAttributesValue::selectedIndex);
    VZ_BIND_EVENT_PROPERTY(specs.onChange, @"on-change", tpl, data, item);
    /* gencode end */
}

+ (void)bindWebViewNodeSpecs:(VZ::WebViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start WebViewNodeSpecs */
    VZ_BIND_PROPERTY(NSDictionary *, specs.source, style[@"source"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.scalesPageToFit, style[@"scales-page-to-fit"], data);
    VZ_BIND_EVENT_PROPERTY(specs.onLoadingStart, @"on-loading-start", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onLoadingFinish, @"on-loading-finish", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onLoadingError, @"on-loading-error", tpl, data, item);
    /* gencode end */
}

+ (void)bindMapViewNodeSpecs:(VZ::MapViewNodeSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data item:(id<VZMistItem>)item
{
    NSDictionary *style = tpl[@"style"];
    /* gencode start MapViewNodeSpecs */
    VZ_BIND_PROPERTY(MKMapType, specs.mapType, style[@"map-type"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.showsUserLocation, style[@"shows-user-location"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.followUserLocation, style[@"follow-user-location"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.showsAnnotationCallouts, style[@"shows-annotation-callouts"], data);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.zoomEnabled, style[@"zoom-enabled"], data, DefaultControlAttrValue::able);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.scrollEnabled, style[@"scroll-enabled"], data, DefaultControlAttrValue::able);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.rotateEnabled, style[@"rotate-enabled"], data, DefaultControlAttrValue::able);
    VZ_BIND_NUMBER_PROPERTY(BOOL, specs.pitchEnabled, style[@"pitch-enabled"], data, DefaultControlAttrValue::able);
    VZ_BIND_PROPERTY(MKCoordinateRegion, specs.region, style[@"region"], data, DefaultAttributesValue::undefinedRegion);
    VZ_BIND_EVENT_PROPERTY(specs.onAnnotationPress, @"on-annotation-press", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onAnnotationFocus, @"on-annotation-focus", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onAnnotationBlur, @"on-annotation-blur", tpl, data, item);
    VZ_BIND_EVENT_PROPERTY(specs.onAnnotationDragStateChange, @"on-annotation-drag-state-change", tpl, data, item);
    /* gencode end */

    if ([style[@"annotations"] isKindOfClass:[NSArray class]]) {
        std::vector<MapAnnotationSpecs> annotations;
        for (NSDictionary *dict in style[@"annotations"]) {
            if (![dict isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            MapAnnotationSpecs annotationSpec = MapAnnotationSpecs();
            [self bindMapAnnotationSpecs:annotationSpec fromTemplate:dict data:data];
            annotations.push_back(annotationSpec);
        }
        if (annotations.size() > 0) {
            specs.annotations = annotations;
        }
    }

    if ([style[@"overlays"] isKindOfClass:[NSArray class]]) {
        std::vector<MapOverlaySpecs> overlays;
        for (NSDictionary *dict in style[@"overlays"]) {
            if (![dict isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            MapOverlaySpecs overlaySpec = MapOverlaySpecs();
            [self bindMapOverlaySpecs:overlaySpec fromTemplate:dict data:data];
            overlays.push_back(overlaySpec);
        }
        if (overlays.size() > 0) {
            specs.overlays = overlays;
        }
    }
}

+ (void)bindMapAnnotationSpecs:(MapAnnotationSpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    VZ_BIND_PROPERTY(NSString *, specs.identifier, tpl[@"id"], data);
    VZ_BIND_NUMBER_PROPERTY(double, specs.latitude, tpl[@"latitude"], data);
    VZ_BIND_NUMBER_PROPERTY(double, specs.longitude, tpl[@"longitude"], data);
    VZ_BIND_PROPERTY(NSString *, specs.title, tpl[@"title"], data);
    VZ_BIND_PROPERTY(NSString *, specs.subTitle, tpl[@"subtitle"], data);
    VZ_BIND_PROPERTY(UIImage *, specs.image, tpl[@"image"], data);
    VZ_BIND_NUMBER_PROPERTY(double, specs.animateDrop, tpl[@"animate-drop"], data);
    VZ_BIND_NUMBER_PROPERTY(double, specs.draggable, tpl[@"draggable"], data);
}

+ (void)bindMapOverlaySpecs:(MapOverlaySpecs &)specs fromTemplate:(NSDictionary *)tpl data:(VZTExpressionContext *)data
{
    VZ_BIND_PROPERTY(NSString *, specs.identifier, tpl[@"id"], data);
    VZ_BIND_PROPERTY(UIColor *, specs.strokeColor, tpl[@"stroke-color"], data);
    VZ_BIND_NUMBER_PROPERTY(float, specs.lineWidth, tpl[@"line-width"], data);

    if (![tpl[@"coordinates"] isKindOfClass:[NSArray class]]) {
        return;
    }
    NSArray *coordinateSpecs = __extractValue(tpl[@"coordinates"], data);
    std::vector<CLLocationCoordinate2D> coordinates;
    for (NSDictionary *dict in coordinateSpecs) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        coordinates.push_back((CLLocationCoordinate2D) {
            .latitude = __vzDouble(dict[@"latitude"], 0),
            .longitude = __vzDouble(dict[@"longitude"], 0)
        });
    }
    if (coordinates.size() > 0) {
        specs.coordinates = coordinates;
    }
}

@end
