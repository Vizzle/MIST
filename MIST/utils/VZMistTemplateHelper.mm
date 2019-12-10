//
//  VZMistTemplateHelper.m
//  MIST
//
//  Created by moxin on 2016/12/6.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZMistTemplateHelper.h"
#import "VZMistHTMLStringParser.h"
#import "VZTExpressionNode.h"
#import "VZTLiteralNode.h"
#import "VZTUtils.h"
#import "VZTParser.h"
#import "VZImageCache.h"
#import "VZMistError.h"
#import "VZMist.h"
#import "VZTGlobalFunctions.h"
#import <VZFlexLayout/VZFTextNodeRenderer.h>

#include <cassert>
#include <string>
#include <unordered_map>
#import <ImageIO/ImageIO.h>


namespace VZ
{
UIColor *colorFromRgba(int r, int g, int b, int a = 0xff)
{
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}

int numberFromHexString(const char *str, size_t len)
{
    int r = 0;
    for (int i = 0; i < len; i++) {
        char c = str[i];
        int n = 0;
        if (isdigit(c)) {
            n = c - '0';
        } else if (c >= 'A' && c <= 'F') {
            n = c - 'A' + 10;
        } else if (c >= 'a' && c <= 'f') {
            n = c - 'a' + 10;
        } else {
            return 256;
        }
        r *= 16;
        r += n;
    }
    return r;
}

std::string numberToHexString(int number)
{
    char str[3];
    char c = number / 16;
    c += c < 10 ? '0' : ('A' - 10);
    str[0] = c;
    c = number % 16;
    c += c < 10 ? '0' : ('A' - 10);
    str[1] = c;
    str[2] = 0;
    return str;
}

UIColor *colorFromHex(const char *hex)
{
    size_t len = strlen(hex);

    if (len != 4 && len != 5 && len != 7 && len != 9) {
        return nil;
    } else {
        for (int i = 1; i < len; i++) {
            if (!ishexnumber(hex[i])) {
                return nil;
            }
        }
    }

    switch (len) {
        case 4:
            return colorFromRgba(numberFromHexString(hex + 1, 1) * 255 / 15,
                                 numberFromHexString(hex + 2, 1) * 255 / 15,
                                 numberFromHexString(hex + 3, 1) * 255 / 15);
        case 5:
            return colorFromRgba(numberFromHexString(hex + 2, 1) * 255 / 15,
                                 numberFromHexString(hex + 3, 1) * 255 / 15,
                                 numberFromHexString(hex + 4, 1) * 255 / 15,
                                 numberFromHexString(hex + 1, 1) * 255 / 15);
        case 7:
            return colorFromRgba(numberFromHexString(hex + 1, 2),
                                 numberFromHexString(hex + 3, 2),
                                 numberFromHexString(hex + 5, 2));
        case 9:
            return colorFromRgba(numberFromHexString(hex + 3, 2),
                                 numberFromHexString(hex + 5, 2),
                                 numberFromHexString(hex + 7, 2),
                                 numberFromHexString(hex + 1, 2));
    }

    return nil;
}
}


@interface VZTStringConcatExpressionNode : VZTExpressionNode

@property (nonatomic, strong) NSMutableArray<VZTExpressionNode *> *expressions;

@end


@implementation VZTStringConcatExpressionNode

- (instancetype)init
{
    if (self = [super init]) {
        _expressions = [NSMutableArray array];
    }
    return self;
}

- (id)compute:(VZTExpressionContext *)context
{
    NSMutableString *result = [[NSMutableString alloc] init];
    for (VZTExpressionNode *expression in _expressions) {
        id value = [expression compute:context];
        [result appendString:vzt_stringValue(value)];
    }
    return result;
}

@end


@implementation VZMistTemplateHelper

// 例如[1, 2, 3, 4, 5]切分2，结果是[[1, 2], [3, 4], [5]]
+ (NSArray *)sliceList:(NSArray *)list forCount:(NSUInteger)count
{
    if (![list isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:list.count / count];
    NSMutableArray *subList = nil;
    int i = 0;
    for (NSDictionary *subDict in list) {
        if (i == 0) {
            subList = [NSMutableArray arrayWithCapacity:count];
        }
        [subList addObject:subDict];
        i++;
        if (i == count) {
            [ret addObject:[subList copy]];
            i = 0;
        }
    }
    if (i != 0) {
        [ret addObject:[subList copy]];
    }
    return [ret copy];
}

+ (UIColor *)colorFromName:(NSString *)name
{
    static NSDictionary *colorNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorNames = @{
            @"black" : [UIColor blackColor],
            @"darkgray" : [UIColor darkGrayColor],
            @"lightgray" : [UIColor lightGrayColor],
            @"white" : [UIColor whiteColor],
            @"gray" : [UIColor grayColor],
            @"red" : [UIColor redColor],
            @"green" : [UIColor greenColor],
            @"blue" : [UIColor blueColor],
            @"cyan" : [UIColor cyanColor],
            @"yellow" : [UIColor yellowColor],
            @"magenta" : [UIColor magentaColor],
            @"orange" : [UIColor orangeColor],
            @"purple" : [UIColor purpleColor],
            @"brown" : [UIColor brownColor],
            @"clear" : [UIColor clearColor],
            @"transparent" : [UIColor clearColor]
        };
    });

    return colorNames[name.lowercaseString];
}

+ (UIColor *)colorFromString:(NSString *)string
{
    if (![string isKindOfClass:[NSString class]] || string.length == 0) {
        return nil;
    } else if ([string characterAtIndex:0] == '#') {
        return VZ::colorFromHex(string.UTF8String);
    } else {
        return [self colorFromName:string];
    }
}

+ (NSRegularExpression *)expressionRegex
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\$\\{.*?\\}" options:0 error:nil];
    });
    return regex;
}


+ (id)extractValueForExpression:(id)expression withContext:(VZTExpressionContext *)context
{
    if ([expression isKindOfClass:[VZTExpressionNode class]]) {
        return [expression compute:context];
    } else if ([expression isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id child in expression) {
            id value = [self extractValueForExpression:child withContext:context];
            if (value) {
                [array addObject:value];
            } else {
                NSAssert(NO, @"value cannot be nil");
            }
        }
        return array;
    } else if ([expression isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (id key in expression) {
            id value = [expression objectForKey:key];
            dictionary[key] = [self extractValueForExpression:value withContext:context];
        }
        return dictionary;
    } else {
        return expression;
    }
}

+ (id)valueForExpression:(NSString *)fullPath inData:(NSDictionary *)data
{
    try {
        //quickly use standard valueForKeyPath if no arrays are found
        if ([fullPath rangeOfString:@"["].location == NSNotFound) {
            return [data valueForKeyPath:fullPath];
        }

        NSArray *parts = [fullPath componentsSeparatedByString:@"."];
        id currentObj = data;
        for (NSString *part in parts) {
            NSRange range = [part rangeOfString:@"["];
            if (range.location == NSNotFound) {
                currentObj = [currentObj valueForKey:part];
            } else {
                NSString *arrayKey = [part substringToIndex:range.location];
                int index = [[[part substringToIndex:part.length - 1] substringFromIndex:range.location + 1] intValue];
                currentObj = [[currentObj valueForKey:arrayKey] objectAtIndex:index];
            }
        }
        return currentObj;
    } catch (NSException *exception) {
        return nil;
    }
}

+ (NSDictionary *)parseExpressionsInTemplate:(NSDictionary *)tpl mistInstance:(VZMist *)mistInstance
{
    return [self parseExpressionsInObject:tpl mistInstance:mistInstance];
}

+ (id)parseExpressionsInObject:(id)obj mistInstance:(VZMist *)mistInstance
{
    if ([obj isKindOfClass:[NSString class]]) {
        return [self parseExpression:obj mistInstance:mistInstance];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id child in obj) {
            [array addObject:[self parseExpressionsInObject:child mistInstance:mistInstance]];
        }
        return array;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (id key in obj) {
            id value = [obj objectForKey:key];
            dictionary[key] = [self parseExpressionsInObject:value mistInstance:mistInstance];
        }
        return dictionary;
    } else {
        return obj;
    }
}

+ (id)parseExpression:(NSString *)value mistInstance:(VZMist *)mistInstance
{
    if (![value isKindOfClass:[NSString class]]) {
        return value;
    }

    VZTExpressionNode *exp;
    NSArray<NSTextCheckingResult *> *results = [[self expressionRegex] matchesInString:value options:0 range:NSMakeRange(0, [value length])];

    if (results.count == 0) {
        return value;
    } else if (results.count == 1 && results[0].range.length == value.length) {
        NSString *expression = [value substringWithRange:NSMakeRange(2, value.length - 3)];
        exp = [self _parseExpression:expression mistInstance:mistInstance];
    } else {
        VZTStringConcatExpressionNode *resultExpression = [[VZTStringConcatExpressionNode alloc] init];
        NSUInteger lastLocation = 0;
        for (NSTextCheckingResult *result in results) {
            if (result.range.location > lastLocation) {
                [resultExpression.expressions addObject:[[VZTLiteralNode alloc] initWithValue:[value substringWithRange:NSMakeRange(lastLocation, result.range.location - lastLocation)]]];
            }
            NSString *expression = [value substringWithRange:NSMakeRange(result.range.location + 2, result.range.length - 3)];
            VZTExpressionNode *expressionNode = [self _parseExpression:expression mistInstance:mistInstance];
            if (expressionNode) {
                [resultExpression.expressions addObject:expressionNode];
            }
            lastLocation = result.range.location + result.range.length;
        }
        if (lastLocation < value.length) {
            [resultExpression.expressions addObject:[[VZTLiteralNode alloc] initWithValue:[value substringWithRange:NSMakeRange(lastLocation, value.length - lastLocation)]]];
        }
        exp = resultExpression;
    }

    return exp;
}

+ (VZTExpressionNode *)_parseExpression:(NSString *)expression mistInstance:(VZMist *)mistInstance
{
    NSError *error;
    VZTExpressionNode *node = [VZTParser parse:expression error:&error];
    if (!node) {
        NSString *errorDesc = error.localizedDescription ?: @"parse expression failure";
        VZMistError *mistError = [VZMistError templateParseErrorWithExpression:expression Message:errorDesc];
        mistInstance.errorCallback(mistError);
    }
    return node;
}

+ (NSAttributedString *)attributedStringFromHtml:(NSString *)html
{
    return [VZMistHTMLStringParser attributedStringFromHtml:html];
}

+ (UIImage *)imageNamed:(NSString *)imageName
{
    NSString *key = [NSString stringWithFormat:@"o2o_%@", imageName];

    UIImage *image = [[VZImageCache sharedInstance] imageForKey:key];

    if (!image) {
        if ([imageName hasSuffix:@"gif"]) {
            return [self gifImageNamed:imageName];
        }

        if (![imageName containsString:@"/"]) {
            NSString *file = [NSString stringWithFormat:@"%@/%@", [NSBundle mainBundle].bundlePath, imageName];

            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                image = [UIImage imageNamed:imageName];
            } else {
                image = [UIImage imageWithContentsOfFile:file];
            }
        } else {
            image = [self bundledImageWithName:imageName];
        }

        if (image) {
            [[VZImageCache sharedInstance] storeImage:image WithKey:key];
        } else {
            NSLog(@"%@: failed to load image '%@'", self.class, imageName);
        }
    }

    return image;
}

+ (UIImage *)gifImageNamed:(NSString *)gifName
{
    NSString *key = [NSString stringWithFormat:@"o2o_%@", gifName];

    UIImage *image = [[VZImageCache sharedInstance] imageForKey:key];

    if (!image) {
        NSString *path = [NSString stringWithFormat:@"%@/%@", [NSBundle mainBundle].bundlePath, gifName];
        NSData *data = [NSData dataWithContentsOfFile:path];
        image = [self apmm_animatedGIFWithData:data];

        if (image) {
            [[VZImageCache sharedInstance] storeImage:image WithKey:key];
        } else {
            NSLog(@"+[O2OHelper gifImageNamed:] failed to load image '%@'", gifName);
        }
    }

    return image;
}

+ (UIImage *)bundledImageWithName:(NSString *)name {
    if (![name containsString:@"/"]) {
        return nil;
    }
    
    NSArray *slices = [name componentsSeparatedByString:@"/"];
    if (slices.count != 2) {
        return nil;
    }
    
    NSString *bundleName = slices[0];
    //normally Foo.bundle/image, Foo/image is also ok.
    bundleName = [bundleName hasSuffix:@".bundle"] ? bundleName : [NSString stringWithFormat:@"%@.bundle", bundleName];
    NSString *imageName = slices[1];
    
    NSString *bundlePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], bundleName] ;
    //raw image file
    UIImage *ret = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", bundlePath, imageName]];
    if (!ret) {
        //image in Assets.car
        ret = [UIImage imageNamed:imageName inBundle:[NSBundle bundleWithPath:bundlePath] compatibleWithTraitCollection:nil];
    }
    return ret;
}

+ (UIImage *)apmm_animatedGIFWithData:(NSData *)data
{
    if (!data) {
        return nil;
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;

    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    } else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;

        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            duration += [self apmm_frameDurationAtIndex:i source:source];
            //scale必须设置为1.0，否则iamge size会变小，请看注释
            /*
             The scale factor to use when interpreting the image data. Specifying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of the image. Applying a different scale factor changes the size of the image as reported by the size property
             */
            UIImage *imageTmp = [UIImage imageWithCGImage:image scale:1.0 orientation:UIImageOrientationUp];
            [images addObject:imageTmp];
            CGImageRelease(image);
        }
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }

    CFRelease(source);
    return animatedImage;
}

+ (float)apmm_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary];

    NSNumber *delayTimeUnclampedProp = gifProperties[(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    } else {
        NSNumber *delayTimeProp = gifProperties[(__bridge NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }

    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.

    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }

    CFRelease(cfFrameProperties);
    return frameDuration;
}

+ (UIImage *)resizableImage:(NSString *)imageName top:(CGFloat)top left:(CGFloat)left bottom:(CGFloat)bottom right:(CGFloat)right
{
    return [[self imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right)];
}

+ (UIImage *)resizableImageStretch:(NSString *)imageName top:(CGFloat)top left:(CGFloat)left bottom:(CGFloat)bottom right:(CGFloat)right
{
    return [[self imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right) resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGRect fillRect = CGRectMake(0, 0, size.width, size.height);
    CGContextSetFillColorWithColor(currentContext, color.CGColor);
    CGContextFillRect(currentContext, fillRect);
    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return colorImage;
}

@end


@implementation NSString (TemplateHelper)

- (UIColor *)vzt_toColor
{
    return [VZMistTemplateHelper colorFromString:self];
}

- (CGFloat)vzt_heightWithFontSize:(CGFloat)size width:(CGFloat)width height:(CGFloat)height
{
    return [self boundingRectWithSize:CGSizeMake(width, height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:size] } context:nil].size.height;
}

- (CGFloat)vzt_heightWithFontSize:(CGFloat)size width:(CGFloat)width lineSpacing:(CGFloat)lineSpacing
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineSpacing];

    NSDictionary *attributes = @{NSFontAttributeName : [UIFont systemFontOfSize:size], NSParagraphStyleAttributeName : paragraphStyle};
    CGRect rect = [self boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];

    return rect.size.height;
}

- (NSUInteger)linesWithFontSize:(CGFloat)size width:(CGFloat)width
{
    VZFTextNodeRenderer *renderer = [[VZFTextNodeRenderer alloc] init];
    renderer.text = [[NSAttributedString alloc] initWithString:self attributes:@{
        NSFontAttributeName : [UIFont systemFontOfSize:size]
    }];
    renderer.maxSize = CGSizeMake(width, CGFLOAT_MAX);
    return renderer.linesCount;
}

@end


@implementation VZTGlobalFunctions (ColorHelper)

+ (UIColor *)color:(NSString *)str
{
    return [VZMistTemplateHelper colorFromString:str];
}

+ (CGColorRef)cgcolor:(NSString *)str
{
    return [VZMistTemplateHelper colorFromString:str].CGColor;
}

+ (UIColor *)rgb:(double)r :(double)g :(double)b
{
    return [self rgba:r :g :b :1];
}

+ (UIColor *)rgba:(double)r :(double)g :(double)b :(double)a
{
    return [UIColor colorWithRed:r / 255 green:g / 255 blue:b / 255 alpha:a];
}

@end


#ifdef DEBUG

@implementation VZTGlobalFunctions (Debug)

+ (id)print:(id)obj {
    NSLog(@"Mist Debug: %@", obj);
    return obj;
}

+ (id)alert:(id)obj {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Mist Debug"
                                                            message:[NSString stringWithFormat:@"%@", obj]
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
    });
    return obj;
}

@end

#endif
