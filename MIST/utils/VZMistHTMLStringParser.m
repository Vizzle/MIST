//
//  VZMistHTMLStringParser.m
//  MIST
//
//  Created by moxin on 2016/12/7.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZMistHTMLStringParser.h"
#import "VZMistTemplateHelper.h"
#if __has_include(<O2OReact/VZFNode.h>)
#else
#import "VZDataStructure.h"
#endif

#import <CoreText/CoreText.h>

static NSString *const kImagePlaceholder = @"__mist__image_placeholder";


@interface VZMistHTMLStringParser () <NSXMLParserDelegate>
@property (nonatomic, strong, readonly) NSAttributedString *attributedString;
@end


@implementation VZMistHTMLStringParser
{
    NSMutableArray<NSDictionary *> *_attrStack;

    // 这两个一一对应，连成一个 NSAttributedString
    NSMutableArray<NSString *> *_strs;
    NSMutableArray<NSDictionary *> *_attrs;

    NSMutableString *_currStr;
}

- (instancetype)initWithHtml:(NSString *)html
{
    if (self = [super init]) {
        _attrStack = [NSMutableArray new];
        _strs = [NSMutableArray new];
        _attrs = [NSMutableArray new];
        _currStr = [NSMutableString new];

        // 这里设置 NSStrikethroughStyleAttributeName 是因为 iOS 的一个 bug，见：http://www.nicnocquee.com/ios/2014/09/22/nsattributedstring-with-nsstrikethroughstyleattributename-bug-in-ios-8.html
        [_attrStack addObject:@{ //NSFontAttributeName:[UIFont systemFontOfSize:[UIFont systemFontSize]],
            NSStrikethroughStyleAttributeName : @(NSUnderlineStyleNone)
        }];

        // XML 不允许有未闭合节点，所以把<br>替换成<br/>
        NSString *newHtml = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"<br/>"];

        // XML 要求有一个根节点，这里的body随便加的，没啥特殊意义
        newHtml = [NSString stringWithFormat:@"<body>%@</body>", newHtml];

        // NSXMLParser 解析到&nbsp;时会报错（或许是我没用对）
        newHtml = [newHtml stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@"#nbsp;"];
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[newHtml dataUsingEncoding:NSUTF8StringEncoding]];
        parser.shouldProcessNamespaces = NO;
        parser.delegate = self;
        if ([parser parse]) {
            NSMutableAttributedString *attrStr = [NSMutableAttributedString new];
            for (int i = 0; i < _strs.count; i++) {
                if ([_strs[i] isEqualToString:kImagePlaceholder]) {
                    NSAttributedString *attchmentAttrText = [NSAttributedString attributedStringWithAttachment:_attrs[i][NSAttachmentAttributeName]];
                    [attrStr appendAttributedString:attchmentAttrText];
                } else {
                    [attrStr appendAttributedString:[[NSAttributedString alloc] initWithString:_strs[i] attributes:_attrs[i]]];
                }
            }
            _attributedString = attrStr;
        } else {
            NSLog(@"failed to parse XML(%@): %@", parser.parserError, html);
        }
    }
    return self;
}

// 开始一个新段落
- (void)paragraphStart
{
    if (_strs.count > 0 && ![_strs.lastObject hasSuffix:@"\n"]) {
        _strs[_strs.count - 1] = [_strs.lastObject stringByAppendingString:@"\n"];
    }
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict
{
    NSMutableDictionary *attrs = (_attrStack.lastObject ?: @{}).mutableCopy;
    [_attrStack addObject:attrs];

    // 富文本-图片
    if ([@"img" isEqualToString:elementName]) {
        UIImage *image = [UIImage imageNamed:attributeDict[@"src"]];
        if (image) {
            NSTextAttachment *attch = [[NSTextAttachment alloc] init];
            attch.image = image;
            attrs[NSAttachmentAttributeName] = attch;
            [_strs addObject:@"\uFFFC"];
            [_attrs addObject:@{NSAttachmentAttributeName : attch}];
        }
    }
    // 加粗
    else if ([@"b" isEqualToString:elementName] || [@"strong" isEqualToString:elementName]) {
        UIFont *oldFont = attrs[NSFontAttributeName] ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
        UIFontDescriptor *fontDescriptor = [oldFont.fontDescriptor fontDescriptorWithSymbolicTraits:oldFont.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold];
        UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:0];
        attrs[NSFontAttributeName] = font;
    }
    // 斜体
    else if ([@"i" isEqualToString:elementName] || [@"em" isEqualToString:elementName] || [@"dfn" isEqualToString:elementName] || [@"cite" isEqualToString:elementName]) {
        UIFont *oldFont = attrs[NSFontAttributeName] ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
        UIFontDescriptor *fontDescriptor = [oldFont.fontDescriptor fontDescriptorWithSymbolicTraits:oldFont.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic];
        UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:0];
        attrs[NSFontAttributeName] = font;
    }
    // 等宽字体
    else if ([@"tt" isEqualToString:elementName]) {
        // 试了各种方法，都不能完美实现只改变字体face，这里只保留字体size，不保留bold等样式
        UIFont *oldFont = attrs[NSFontAttributeName] ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
        UIFont *font = [UIFont fontWithName:@"Courier" size:oldFont.pointSize];
        attrs[NSFontAttributeName] = font;
    } else if ([@"big" isEqualToString:elementName]) {
        UIFont *oldFont = attrs[NSFontAttributeName] ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
        attrs[NSFontAttributeName] = [oldFont fontWithSize:oldFont.pointSize * 1.25];
    } else if ([@"small" isEqualToString:elementName]) {
        UIFont *oldFont = attrs[NSFontAttributeName] ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
        attrs[NSFontAttributeName] = [oldFont fontWithSize:oldFont.pointSize * 0.8];
    }
    // 指定字体名、尺寸、粗体、颜色
    else if ([@"font" isEqualToString:elementName]) {
        UIFont *oldFont = attrs[NSFontAttributeName] ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
        NSString *value;
        // 试了各种方法，都不能完美实现只改变字体face，这里只保留字体size，不保留bold等样式
        if ((value = attributeDict[@"face"])) {
            oldFont = [UIFont fontWithName:value size:oldFont.pointSize];
        }
        if ((value = attributeDict[@"size"])) {
            oldFont = [oldFont fontWithSize:__vzDouble(value, oldFont.pointSize)];
        }
        if ((value = attributeDict[@"weight"]) && [@"bold" isEqualToString:value]) {
            UIFontDescriptor *fontDescriptor = [oldFont.fontDescriptor fontDescriptorWithSymbolicTraits:oldFont.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold];
            oldFont = [UIFont fontWithDescriptor:fontDescriptor size:0];
        }
        if ((value = attributeDict[@"color"])) {
            attrs[NSForegroundColorAttributeName] = [VZMistTemplateHelper colorFromString:value];
        }
        attrs[NSFontAttributeName] = oldFont;
    }
    // 标题
    else if ([@"h1" isEqualToString:elementName] || [@"h2" isEqualToString:elementName] || [@"h3" isEqualToString:elementName] || [@"h4" isEqualToString:elementName] || [@"h5" isEqualToString:elementName] || [@"h6" isEqualToString:elementName]) {
        static float sizes[] = {2, 1.5, 1.17, 1, 0.83, 0.67};       // 字体大小
        static float margins[] = {0.67, 0.83, 1, 1.33, 1.67, 2.33}; // 上下边距
        int n = [elementName characterAtIndex:1] - '1';

        UIFont *oldFont = attrs[NSFontAttributeName] ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
        CGFloat fontSize = [UIFont systemFontSize] * sizes[n];
        UIFontDescriptor *fontDescriptor = [oldFont.fontDescriptor fontDescriptorWithSize:fontSize];
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:oldFont.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold];
        attrs[NSFontAttributeName] = [UIFont fontWithDescriptor:fontDescriptor size:0];

        NSMutableParagraphStyle *paragraphStyle = [(attrs[NSParagraphStyleAttributeName] ?: [NSParagraphStyle new])mutableCopy];
        paragraphStyle.paragraphSpacing = fontSize * margins[n];
        attrs[NSParagraphStyleAttributeName] = paragraphStyle;

        [self paragraphStart];
    }
    // 段落
    else if ([@"p" isEqualToString:elementName]) {
        UIFont *oldFont = attrs[NSFontAttributeName] ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
        NSMutableParagraphStyle *paragraphStyle = [(attrs[NSParagraphStyleAttributeName] ?: [NSParagraphStyle new])mutableCopy];
        paragraphStyle.paragraphSpacing = oldFont.pointSize;
        attrs[NSParagraphStyleAttributeName] = paragraphStyle;

        [self paragraphStart];
    }
    // 链接
    else if ([@"a" isEqualToString:elementName]) {
        attrs[NSLinkAttributeName] = attributeDict[@"href"];
    }
    // 下划线
    else if ([@"u" isEqualToString:elementName]) {
        attrs[NSUnderlineStyleAttributeName] = @(NSUnderlinePatternSolid | NSUnderlineStyleSingle);
    }
    // 删除线
    else if ([@"strike" isEqualToString:elementName] || [@"s" isEqualToString:elementName]) {
        attrs[NSStrikethroughStyleAttributeName] = @(NSUnderlinePatternSolid | NSUnderlineStyleSingle);
    }
    // 上标
    else if ([@"sup" isEqualToString:elementName]) {
        attrs[(__bridge NSString *)kCTSuperscriptAttributeName] = @1;
    }
    // 下标
    else if ([@"sub" isEqualToString:elementName]) {
        attrs[(__bridge NSString *)kCTSuperscriptAttributeName] = @-1;
    }
    // 换行
    else if ([@"br" isEqualToString:elementName]) {
        // '\n' 在 NSAttributedString 中是段落结束符，这里需要使用 unicode line separator 来换行
        if (_strs.count > 0) {
            _strs[_strs.count - 1] = [_strs.lastObject stringByAppendingString:@"\u2028"];
        } else {
            [_currStr appendString:@"\u2028"];
        }
    } else if ([@"blockquote" isEqualToString:elementName]) {
        [self paragraphStart];
    }
}

static inline BOOL o2o_isWhitespace(unichar c)
{
    return [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c];
}

// 连续的空白字符只保留一个空格
- (NSString *)reduceWhitespaces:(NSString *)str
{
    NSMutableString *newStr = [NSMutableString new];
    int start = -1;
    for (int i = 0; i < str.length; i++) {
        unichar c = [str characterAtIndex:i];
        if (o2o_isWhitespace(c)) {
            if (start != -1) {
                [newStr appendString:[str substringWithRange:NSMakeRange(start, i - start)]];
                [newStr appendString:@" "];
                start = -1;
            }
        } else if (start == -1) {
            start = i;
        }
    }
    if (start != -1) {
        [newStr appendString:[str substringFromIndex:start]];
    }
    return newStr;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // img 标签中的字符不保留
    if (_attrStack.lastObject[NSAttachmentAttributeName]) {
        return;
    }

    BOOL leadingSpace = o2o_isWhitespace([string characterAtIndex:0]);
    BOOL trailingSpace = string.length > 1 && o2o_isWhitespace([string characterAtIndex:string.length - 1]);

    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    string = [self reduceWhitespaces:string];
    string = [string stringByReplacingOccurrencesOfString:@"#nbsp;" withString:@" "];

    // 根据情况保留前导或后向空格
    if (trailingSpace && string.length > 0) {
        string = [string stringByAppendingString:@" "];
    }
    if (leadingSpace && _strs.count > 0 && !o2o_isWhitespace([_strs.lastObject characterAtIndex:_strs.lastObject.length - 1])) {
        string = [@" " stringByAppendingString:string];
    }

    if (string.length == 0) {
        return;
    }

    [_currStr appendString:string];
    [_strs addObject:_currStr];
    [_attrs addObject:_attrStack.lastObject];
    _currStr = [NSMutableString new];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [_attrStack removeLastObject];
    // 段落结束时加一个段落结束符
    if ([@"h1" isEqualToString:elementName] || [@"h2" isEqualToString:elementName] || [@"h3" isEqualToString:elementName] || [@"h4" isEqualToString:elementName] || [@"h5" isEqualToString:elementName] || [@"h6" isEqualToString:elementName] || [@"p" isEqualToString:elementName] || [@"blockquote" isEqualToString:elementName]) {
        _strs[_strs.count - 1] = [_strs.lastObject stringByAppendingString:@"\n"];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"parseErrorOccurred:%@", parseError);
}

+ (NSAttributedString *)attributedStringFromHtml:(NSString *)html
{
    VZMistHTMLStringParser *helper = [[VZMistHTMLStringParser alloc] initWithHtml:html];
    return helper.attributedString;
}

+ (NSString *)htmlEncodedString:(NSString *)str
{
    str = [str stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    str = [str stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    str = [str stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    str = [str stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    return str;
}
@end
