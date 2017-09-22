//
//  VZTExpressionPerformanceTests.m
//  MIST
//
//  Created by Sleen on 2017/9/5.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "VZTExpressionHelper.h"

#import <JavaScriptCore/JavaScriptCore.h>

@interface VZTExpressionPerformanceTests : XCTestCase

@end

@implementation VZTExpressionPerformanceTests

- (NSArray *)expressions {
    static NSArray *exps;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exps = @[
                 @"bigBuy.gmtStart",
                 @"bigBuy.gmtEnd",
                 @"_width_ > 400",
                 @"_width_ < 350",
                 @"dotSize",
                 @"dotSize",
                 @"dotSize",
                 @"dotSize",
                 @"dotSize",
                 @"dotSize / 2",
                 @"plus ? 11 : 10",
                 @"small ? 65 : plus ? 91 : 76",
                 @"small ? 80 : plus ? 107 : 90",
                 @"plus ? 16 : 15",
                 @"small ? 13 : 14",
                 @"bigBuy.itemList.count == 0 ? 'promo' : exclusivePromo.itemList.count > 0 ? 'both' : 'bigBuy'",
                 @"bigBuy.itemList.count > 0 ? '大牌快抢' : ''",
                 @"exclusivePromo.itemList.count > 0 ? '专属优惠' : ''",
                 @"state.status != 'not_started'",
                 @"digit_layout",
                 @"state.time.substring(0, 2)",
                 @"dot_layout",
                 @"digit_layout",
                 @"state.time.substring(3, 2)",
                 @"dot_layout",
                 @"digit_layout",
                 @"state.time.substring(6, 2)",
                 @"state.status != 'started'",
                 @"!(state.status == 'stoped' && style == 'both')",
                 @"bigBuy.endDesc ?: '本场已结束'",
                 @"!(state.status == 'stoped' && style != 'both')",
                 @"bigBuy.endDesc ?: '本场已结束'",
                 @"bigBuy.promoSchema",
                 @"titles.filter(t -> t.length > 0).join(';')",
                 @"style != 'promo'",
                 @"titleSize",
                 @"!(style == 'promo' && exclusivePromo.itemList.count == 3)",
                 @"exclusivePromo.itemList.count",
                 @"exclusivePromo.itemList[_index_]",
                 @"bigImageWidth",
                 @"_index_ == 0 ? 0 : 1",
                 @"1 + _index_",
                 @"item.jumpUrl",
                 @"1 + _index_",
                 @"_index_ == 0",
                 @"bigImageWidth",
                 @"bigImageWidth * 0.75",
                 @"item.imageUrl",
                 @"item.name",
                 @"nameSize",
                 @"item.itemDesc",
                 @"!(style == 'promo' && exclusivePromo.itemList.count == 2)",
                 @"-spacing",
                 @"-spacing",
                 @"exclusivePromo.itemList.count",
                 @"exclusivePromo.itemList[_index_]",
                 @"1 + _index_",
                 @"item.jumpUrl",
                 @"1 + _index_",
                 @"_index_ == 0",
                 @"item.name",
                 @"nameSize",
                 @"item.itemDesc",
                 @"smallImageWidth",
                 @"smallImageWidth * 0.75",
                 @"item.imageUrl",
                 @"style != 'bigBuy'",
                 @"bigBuy.itemList[0]",
                 @"promoAction",
                 @"titleSize",
                 @"plus ? 5 : 2",
                 @"time_layout",
                 @"size / 2",
                 @"item.imageUrl",
                 @"item.name",
                 @"item.itemName.length == 0",
                 @"item.itemName",
                 @"item.itemName.length == 0 ? 4 : 0",
                 @"item.mainDesc",
                 @"item.subDesc.length > 0 ? 24 : 18",
                 @"item.subDesc.length > 0 ? (plus ? 21 : 18) : 15",
                 @"item.subDesc.length > 0 ? -5 : 0",
                 @"item.subDesc",
                 @"plus ? 13 : 12",
                 @"plus ? 13 : 12",
                 @"item.originalPrice",
                 @"style != 'both'",
                 @"bigBuy.itemList.count == 0",
                 @"bigBuy.itemList[0]",
                 @"promoAction",
                 @"titleSize",
                 @"time_layout",
                 @"small",
                 @"item.name",
                 @"nameSize",
                 @"item.mainDesc",
                 @"item.subDesc.length > 0 ? 18 : 15",
                 @"item.subDesc.length > 0 ? -3 : 0",
                 @"item.subDesc",
                 @"item.originalPrice",
                 @"smallImageWidth",
                 @"smallImageWidth * 0.75",
                 @"item.imageUrl",
                 @"titleSize",
                 @"exclusivePromo.itemList[0]",
                 @"item.jumpUrl",
                 @"item.name",
                 @"nameSize",
                 @"item.itemDesc",
                 @"plus ? 15 : 14",
                 @"smallImageWidth",
                 @"smallImageWidth * 0.75",
                 @"item.imageUrl",
                 ];
    });
    return exps;
}

- (void)testPerformanceParseSimple {
    [self measureBlock:^{
        for (int i=0;i<1000;i++) {
            [VZTParser parse:@"1 + 1" error:nil];
        }
    }];
}

- (void)testPerformanceComputeSimple {
    VZTExpressionNode *node = [VZTParser parse:@"1 + 1" error:nil];
    [self measureBlock:^{
        for (int i=0;i<1000;i++) {
            [node compute];
        }
    }];
}

- (void)testPerformanceJSCoreSimple {
    JSContext *jsContext = [JSContext new];
    [self measureBlock:^{
        for (int i=0;i<1000;i++) {
            [jsContext evaluateScript:@"1 + 1"];
        }
    }];
}

- (void)testPerformanceParseComplex {
    [self measureBlock:^{
        for (int i=0;i<1000;i++) {
            [VZTParser parse:@"max(1 + (2 + 3) * 4, XX.xx.xx(xx, [1, 2, {'a': xxx, 'b': []}], xxxx(xx, xx))).xxxx(xxx, aaa) ? xxx + assd : asdq.asda.asd(xxxx + asd / ads, asdd ? asds : asd + adasdasd / asdsad.asddq(xxas, asda) / asdasd.xxasd).asdad(xasd, asd + asdD) * adasd" error:nil];
        }
    }];
}

- (void)testPerformanceComputeComplex {
    VZTExpressionNode *node = [VZTParser parse:@"max(1 + (2 + 3) * 4, XX.xx.xx(xx, [1, 2, {'a': xxx, 'b': []}], xxxx(xx, xx))).xxxx(xxx, aaa) ? xxx + assd : asdq.asda.asd(xxxx + asd / ads, asdd ? asds : asd + adasdasd / asdsad.asddq(xxas, asda) / asdasd.xxasd).asdad(xasd, asd + asdD) * adasd" error:nil];
    VZTExpressionContext *cxt = [VZTExpressionContext new];
    [self measureBlock:^{
        for (int i=0;i<1000;i++) {
            [node compute:cxt];
        }
    }];
}

- (void)testPerformanceJSCoreComplex {
    JSContext *jsContext = [JSContext new];
    [self measureBlock:^{
        for (int i=0;i<1000;i++) {
            [jsContext evaluateScript:@"max(1 + (2 + 3) * 4, XX.xx.xx(xx, [1, 2, {'a': xxx, 'b': []}], xxxx(xx, xx))).xxxx(xxx, aaa) ? xxx + assd : asdq.asda.asd(xxxx + asd / ads, asdd ? asds : asd + adasdasd / asdsad.asddq(xxas, asda) / asdasd.xxasd).asdad(xasd, asd + asdD) * adasd"];
        }
    }];
}

- (void)testPerformanceParseMany {
    NSArray *exps = [self expressions];
    [self measureBlock:^{
        for (NSString *exp in exps) {
            [VZTParser parse:exp error:nil];
        }
    }];
}

- (void)testPerformanceComputeMany {
    NSArray *exps = [self expressions];
    NSMutableArray *nodes = [NSMutableArray new];
    for (NSString *exp in exps) {
        [nodes addObject:[VZTParser parse:exp error:nil]];
    }
    NSDictionary *dict = @{
                           @"bigBuy": @{
                                   @"gmtStart": @2463244693000,
                                   @"gmtEnd": @1463154693000,
                                   @"currentTime": @1461406730000,
                                   @"promoSchema": @"https://tmall.com",
                                   @"objectId": @"埋点字段",
                                   @"endDesc": @"今日已结束",
                                   @"itemList": @[
                                           @{
                                               @"imageUrl": @"VbnGu100R06JFeZvp9GSWAAAACMAAQED",
                                               @"name": @"胖哥俩肉蟹煲",
                                               @"itemName": @"招牌肉蟹煲小份招牌肉蟹煲小份",
                                               @"mainDesc": @"20",
                                               @"subDesc": @"元",
                                               @"originalPrice": @"36元"
                                               }
                                           ]
                                   },
                           @"exclusivePromo": @{
                                   @"itemList": @[
                                           @{
                                               @"jumpUrl": @"https://tmall.com",
                                               @"imageUrl": @"VbnGu100R06JFeZvp9GSWAAAACMAAQED",
                                               @"name": @"大娘水饺",
                                               @"itemDesc": @"20元券"
                                               },
                                           @{
                                               @"jumpUrl": @"https://taobao.com",
                                               @"imageUrl": @"VbnGu100R06JFeZvp9GSWAAAACMAAQED",
                                               @"name": @"乐高活动11111111111111",
                                               @"itemDesc": @"20元券"
                                               },
                                           @{
                                               @"jumpUrl": @"https://weibo.com",
                                               @"imageUrl": @"VbnGu100R06JFeZvp9GSWAAAACMAAQED",
                                               @"name": @"乐高活动",
                                               @"itemDesc": @"20元券"
                                               }
                                           ]
                                   }
                           };
    VZTExpressionContext *cxt = [VZTExpressionContext new];
    [cxt pushVariables:dict];
    [self measureBlock:^{
        for (VZTExpressionNode *node in nodes) {
            [node compute:cxt];
        }
    }];
}

- (void)testPerformanceJSCoreMany {
    NSArray *exps = [self expressions];
    JSContext *jsContext = [JSContext new];
    NSDictionary *dict = @{
                           @"bigBuy": @{
                                   @"gmtStart": @2463244693000,
                                   @"gmtEnd": @1463154693000,
                                   @"currentTime": @1461406730000,
                                   @"promoSchema": @"https://tmall.com",
                                   @"objectId": @"埋点字段",
                                   @"endDesc": @"今日已结束",
                                   @"itemList": @[
                                           @{
                                               @"imageUrl": @"VbnGu100R06JFeZvp9GSWAAAACMAAQED",
                                               @"name": @"胖哥俩肉蟹煲",
                                               @"itemName": @"招牌肉蟹煲小份招牌肉蟹煲小份",
                                               @"mainDesc": @"20",
                                               @"subDesc": @"元",
                                               @"originalPrice": @"36元"
                                               }
                                           ]
                                   },
                           @"exclusivePromo": @{
                                   @"itemList": @[
                                           @{
                                               @"jumpUrl": @"https://tmall.com",
                                               @"imageUrl": @"VbnGu100R06JFeZvp9GSWAAAACMAAQED",
                                               @"name": @"大娘水饺",
                                               @"itemDesc": @"20元券"
                                               },
                                           @{
                                               @"jumpUrl": @"https://taobao.com",
                                               @"imageUrl": @"VbnGu100R06JFeZvp9GSWAAAACMAAQED",
                                               @"name": @"乐高活动11111111111111",
                                               @"itemDesc": @"20元券"
                                               },
                                           @{
                                               @"jumpUrl": @"https://weibo.com",
                                               @"imageUrl": @"VbnGu100R06JFeZvp9GSWAAAACMAAQED",
                                               @"name": @"乐高活动",
                                               @"itemDesc": @"20元券"
                                               }
                                           ]
                                   }
                           };
    for (NSString *key in dict) {
        jsContext[key] = dict[key];
    }
    [self measureBlock:^{
        for (NSString *exp in exps) {
            [jsContext evaluateScript:exp];
        }
    }];
}

- (NSString *)jsonString {
    return @"{\n\
    \"native\": \"home_discount_list_year\",\n\
    \"controller\": \"O2OPromoTemplateController\",\n\
    \"config\": {\n\
    \"gmtStart\": \"${bigBuy.gmtStart}\",\n\
    \"gmtEnd\": \"${bigBuy.gmtEnd}\"\n\
    },\n\
    \"template\": {\n\
    \"background-color\": \"#FA5145\",\n\
    \"padding-left\": 10,\n\
    \"padding-right\": 10,\n\
    \"padding-bottom\": \"${_next_ == 'home_pop_eye_year' ? 0 : _next_.hasSuffix('_year') ? 3 : 10}\",\n\
    \"direction\": \"vertical\",\n\
    \"children\": [\n\
    {\n\
    \"vars\": [\n\
    {\n\
    \"plus\": \"${_width_ > 400}\",\n\
    \"small\": \"${_width_ < 350}\",\n\
    \"dotSize\": 2.28\n\
    },\n\
    {\n\
    \"bigBuyTitle\": \"大牌秒杀\",\n\
    \"dot_layout\": {\n\
    \"direction\": \"vertical\",\n\
    \"spacing\": \"${dotSize}\",\n\
    \"justify-content\": \"center\",\n\
    \"margin-left\": \"${dotSize}\",\n\
    \"margin-right\": \"${dotSize}\",\n\
    \"children\": [\n\
    {\n\
    \"repeat\": 2,\n\
    \"width\": \"${dotSize}\",\n\
    \"height\": \"${dotSize}\",\n\
    \"corner-radius\": \"${dotSize / 2}\",\n\
    \"background-color\": \"#464646\"\n\
    }\n\
    ]\n\
    },\n\
    \"digit_layout\": {\n\
    \"type\": \"text\",\n\
    \"width\": \"${plus ? 16 : 14}\",\n\
    \"height\": \"${plus ? 16 : 14}\",\n\
    \"font-name\": \"Helvetica Neue\",\n\
    \"font-size\": \"${plus ? 11 : 10}\",\n\
    \"font-style\": \"medium\",\n\
    \"background-color\": \"#464646\",\n\
    \"corner-radius\": 1,\n\
    \"color\": \"white\",\n\
    \"alignment\": \"center\"\n\
    }\n\
    },\n\
    {\n\
    \"smallImageWidth\": \"${small ? 65 : plus ? 91 : 76}\",\n\
    \"bigImageWidth\": \"${small ? 80 : plus ? 107 : 90}\",\n\
    \"titleSize\": \"${plus ? 16 : 15}\",\n\
    \"nameSize\": \"${small ? 13 : 14}\",\n\
    \"style\": \"${bigBuy.itemList.count == 0 ? 'promo' : exclusivePromo.itemList.count > 0 ? 'both' : 'bigBuy'}\",\n\
    \"titles\": [\n\
    \"${bigBuy.itemList.count > 0 ? bigBuyTitle : ''}\",\n\
    \"${exclusivePromo.itemList.count > 0 ? '专属优惠' : ''}\"\n\
    ],\n\
    \"time_layout\": {\n\
    \"flex-shrink\": \"${state.status == 'not_started' ? 0 : 1}\",\n\
    \"align-items\": \"center\",\n\
    \"children\": [\n\
    {\n\
    \"gone\": \"${state.status != 'not_started'}\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"距开始\",\n\
    \"color\": \"#666\",\n\
    \"font-size\": 10,\n\
    \"margin-right\": 2\n\
    },\n\
    {\n\
    \"ref\": \"${digit_layout}\",\n\
    \"text\": \"${state.time.substring(0, 2)}\"\n\
    },\n\
    \"${dot_layout}\",\n\
    {\n\
    \"ref\": \"${digit_layout}\",\n\
    \"text\": \"${state.time.substring(3, 2)}\"\n\
    },\n\
    \"${dot_layout}\",\n\
    {\n\
    \"ref\": \"${digit_layout}\",\n\
    \"text\": \"${state.time.substring(6, 2)}\"\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"gone\": \"${state.status != 'started'}\",\n\
    \"align-items\": \"center\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"image\",\n\
    \"flex-shrink\": 0,\n\
    \"image\": \"O2O.bundle/home_promo_hot\"\n\
    },\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${bigBuy.startDesc ?: '火热进行中'}\",\n\
    \"color\": \"#f3363e\",\n\
    \"font-size\": 14,\n\
    \"font-style\": \"medium\",\n\
    \"margin-left\": 1\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"gone\": \"${!(state.status == 'stoped' && style == 'both')}\",\n\
    \"type\": \"text\",\n\
    \"text\": \"${bigBuy.endDesc ?: '本场已结束'}\",\n\
    \"color\": \"white\",\n\
    \"font-size\": 10,\n\
    \"background-color\": \"#ccc\",\n\
    \"corner-radius\": 1,\n\
    \"height\": 16,\n\
    \"padding-left\": 4,\n\
    \"padding-right\": 4,\n\
    \"font-style\": \"medium\"\n\
    },\n\
    {\n\
    \"gone\": \"${!(state.status == 'stoped' && style != 'both')}\",\n\
    \"type\": \"text\",\n\
    \"text\": \"${bigBuy.endDesc ?: '本场已结束'}\",\n\
    \"font-size\": 13,\n\
    \"color\": \"#888\"\n\
    }\n\
    ]\n\
    },\n\
    \"promoAction\": {\n\
    \"url\": \"${bigBuy.promoSchema}\",\n\
    \"log\": {\n\
    \"seed\": \"a13.b42.c3551.1\",\n\
    \"params\": {\n\
    \"title\": \"${bigBuyTitle}\"\n\
    }\n\
    }\n\
    }\n\
    }\n\
    ],\n\
    \"direction\": \"vertical\",\n\
    \"spm-tag\": \"a13.b42.c3551\",\n\
    \"exposure-log\": {\n\
    \"seed\": \"a13.b42.c3551\",\n\
    \"params\": {\n\
    \"title\": \"${titles.filter(t -> t.length > 0).join(';')}\"\n\
    }\n\
    },\n\
    \"view-properties\": {\n\
    \"layer.shadowOpacity\": 1,\n\
    \"layer.shadowRadius\": 6,\n\
    \"layer.shouldRasterize\": true,\n\
    \"layer.rasterizationScale\": \"${UIScreen.mainScreen.scale}\",\n\
    \"layer.shadowColor\": \"${cgcolor('#C72E00')}\",\n\
    \"layer.shadowOffset\": \"${size(0, 2)}\"\n\
    },\n\
    \"children\": [\n\
    {\n\
    \"gone\": \"${style != 'promo'}\",\n\
    \"spacing\": 5,\n\
    \"padding\": 10,\n\
    \"padding-bottom\": 0,\n\
    \"background-color\": \"white\",\n\
    \"align-items\": \"center\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"image\",\n\
    \"flex-shrink\": 0,\n\
    \"image\": \"O2O.bundle/home_discount_list\",\n\
    \"width\": 15,\n\
    \"height\": 15,\n\
    \"content-mode\": \"scale-aspect-fit\"\n\
    },\n\
    {\n\
    \"type\": \"text\",\n\
    \"flex-shrink\": 0,\n\
    \"color\": \"#333\",\n\
    \"font-style\": \"bold\",\n\
    \"font-size\": \"${titleSize}\",\n\
    \"text\": \"专属优惠\"\n\
    },\n\
    {\n\
    \"type\": \"text\",\n\
    \"color\": \"#F3363E\",\n\
    \"font-style\": \"medium\",\n\
    \"font-size\": 14,\n\
    \"text\": \"${exclusivePromo.subTitle}\"\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"background-color\": \"white\",\n\
    \"padding\": 10,\n\
    \"gone\": \"${!(style == 'promo' && exclusivePromo.itemList.count == 3)}\",\n\
    \"children\": [\n\
    {\n\
    \"repeat\": \"${exclusivePromo.itemList.count}\",\n\
    \"vars\": {\n\
    \"item\": \"${exclusivePromo.itemList[_index_]}\"\n\
    },\n\
    \"width\": \"${bigImageWidth}\",\n\
    \"flex-grow\": \"${_index_ == 0 ? 0 : 1}\",\n\
    \"spm-tag\": \"a13.b42.c3551.${1 + _index_}\",\n\
    \"action\": {\n\
    \"url\": \"${item.jumpUrl}\",\n\
    \"log\": {\n\
    \"seed\": \"a13.b42.c3551.${1 + _index_}\",\n\
    \"params\": {\n\
    \"title\": \"专属优惠\"\n\
    }\n\
    }\n\
    },\n\
    \"children\": [\n\
    {\n\
    \"gone\": \"${_index_ == 0}\",\n\
    \"width\": \"1px\",\n\
    \"background-color\": \"#ddd\",\n\
    \"margin-left\": \"auto\",\n\
    \"margin-right\": \"auto\"\n\
    },\n\
    {\n\
    \"width\": \"${bigImageWidth}\",\n\
    \"direction\": \"vertical\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"image\",\n\
    \"content-mode\": \"scale-aspect-fill\",\n\
    \"height\": \"${bigImageWidth * 0.75}\",\n\
    \"border-width\": \"1px\",\n\
    \"border-color\": \"#ddd\",\n\
    \"clip\": true,\n\
    \"image\": \"O2O.bundle/imageLoading\",\n\
    \"image-url\": \"${item.imageUrl}\"\n\
    },\n\
    {\n\
    \"margin-top\": 5,\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.name}\",\n\
    \"font-size\": \"${nameSize}\",\n\
    \"color\": \"#313131\",\n\
    \"align-self\": \"center\"\n\
    },\n\
    {\n\
    \"margin-top\": 1,\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.itemDesc}\",\n\
    \"font-size\": 14,\n\
    \"font-style\": \"medium\",\n\
    \"color\": \"#F3363E\",\n\
    \"align-self\": \"center\"\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"background-color\": \"white\",\n\
    \"padding-top\": 10,\n\
    \"padding-bottom\": 10,\n\
    \"gone\": \"${!(style == 'promo' && exclusivePromo.itemList.count == 2)}\",\n\
    \"vars\": {\n\
    \"spacing\": 10\n\
    },\n\
    \"children\": [\n\
    {\n\
    \"repeat\": \"${exclusivePromo.itemList.count}\",\n\
    \"vars\": {\n\
    \"item\": \"${exclusivePromo.itemList[_index_]}\"\n\
    },\n\
    \"flex-grow\": 1,\n\
    \"flex-basis\": 0,\n\
    \"spm-tag\": \"a13.b42.c3551.${1 + _index_}\",\n\
    \"action\": {\n\
    \"url\": \"${item.jumpUrl}\",\n\
    \"log\": {\n\
    \"seed\": \"a13.b42.c3551.${1 + _index_}\",\n\
    \"params\": {\n\
    \"title\": \"专属优惠\"\n\
    }\n\
    }\n\
    },\n\
    \"children\": [\n\
    {\n\
    \"gone\": \"${_index_ == 0}\",\n\
    \"width\": \"1px\",\n\
    \"background-color\": \"#ddd\"\n\
    },\n\
    {\n\
    \"margin-left\": 10,\n\
    \"margin-right\": 5,\n\
    \"direction\": \"vertical\",\n\
    \"justify-content\": \"center\",\n\
    \"spacing\": 7,\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.name}\",\n\
    \"font-size\": \"${nameSize}\",\n\
    \"color\": \"#313131\"\n\
    },\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.itemDesc}\",\n\
    \"font-size\": 14,\n\
    \"font-style\": \"medium\",\n\
    \"color\": \"#F3363E\"\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"margin-right\": 10,\n\
    \"type\": \"image\",\n\
    \"content-mode\": \"scale-aspect-fill\",\n\
    \"flex-shrink\": 0,\n\
    \"width\": \"${smallImageWidth}\",\n\
    \"height\": \"${smallImageWidth * 0.75}\",\n\
    \"margin-left\": \"auto\",\n\
    \"border-width\": \"1px\",\n\
    \"border-color\": \"#ddd\",\n\
    \"image\": \"O2O.bundle/imageLoading\",\n\
    \"image-url\": \"${item.imageUrl}\",\n\
    \"clip\": true\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"background-color\": \"white\",\n\
    \"padding\": 10,\n\
    \"gone\": \"${style != 'bigBuy'}\",\n\
    \"vars\": {\n\
    \"item\": \"${bigBuy.itemList[0]}\"\n\
    },\n\
    \"spm-tag\": \"a13.b42.c3551.1\",\n\
    \"action\": \"${promoAction}\",\n\
    \"direction\": \"vertical\",\n\
    \"children\": [\n\
    {\n\
    \"align-items\": \"center\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"flex-shrink\": 0,\n\
    \"text\": \"${bigBuyTitle}\",\n\
    \"color\": \"#313131\",\n\
    \"font-size\": \"${titleSize}\",\n\
    \"font-style\": \"medium\",\n\
    \"margin-right\": \"${plus ? 5 : 2}\"\n\
    },\n\
    {\n\
    \"ref\": \"${time_layout}\",\n\
    \"margin-left\": \"auto\"\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"margin-top\": 6,\n\
    \"margin-bottom\": 3,\n\
    \"children\": [\n\
    {\n\
    \"type\": \"image\",\n\
    \"flex-shrink\": 0,\n\
    \"width\": 100,\n\
    \"height\": 75,\n\
    \"corner-radius\": \"${size / 2}\",\n\
    \"border-width\": \"1px\",\n\
    \"border-color\": \"#ddd\",\n\
    \"clip\": true,\n\
    \"content-mode\": \"scale-aspect-fill\",\n\
    \"image\": \"O2O.bundle/imageLoading\",\n\
    \"image-url\": \"${item.imageUrl}\"\n\
    },\n\
    {\n\
    \"margin-left\": 10,\n\
    \"margin-top\": 2,\n\
    \"margin-bottom\": 2,\n\
    \"flex-grow\": 1,\n\
    \"direction\": \"vertical\",\n\
    \"justify-content\": \"space-between\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.name}\",\n\
    \"font-size\": 15,\n\
    \"font-style\": \"medium\",\n\
    \"color\": \"#313131\"\n\
    },\n\
    {\n\
    \"gone\": \"${item.itemName.length == 0}\",\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.itemName}\",\n\
    \"font-size\": 14,\n\
    \"color\": \"#888\"\n\
    },\n\
    {\n\
    \"margin-top\": \"${item.itemName.length == 0 ? 4 : 0}\",\n\
    \"align-items\": \"end\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.mainDesc}\",\n\
    \"color\": \"#F3363E\",\n\
    \"font-size\": \"${item.subDesc.length > 0 ? 24 : 18}\",\n\
    \"font-size1\": \"${item.subDesc.length > 0 ? (plus ? 21 : 18) : 15}\",\n\
    \"margin-bottom\": \"${item.subDesc.length > 0 ? -5 : 0}\",\n\
    \"font-style\": \"bold\"\n\
    },\n\
    {\n\
    \"flex-shrink\": 1000,\n\
    \"align-items\": \"end\",\n\
    \"wrap\": true,\n\
    \"clip\": true,\n\
    \"height\": 14,\n\
    \"line-spacing\": 20,\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.subDesc}\",\n\
    \"color\": \"#F3363E\",\n\
    \"font-size\": \"${plus ? 13 : 12}\",\n\
    \"font-style\": \"medium\"\n\
    },\n\
    {\n\
    \"type\": \"text\",\n\
    \"margin-left\": 1,\n\
    \"color\": \"#888888\",\n\
    \"font-size\": \"${plus ? 13 : 12}\",\n\
    \"html-text\": \"<s>${item.originalPrice}</s>\"\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"flex-shrink\": 0,\n\
    \"margin-left\": \"auto\",\n\
    \"margin-top\": \"auto\",\n\
    \"margin-bottom\": -2,\n\
    \"type\": \"text\",\n\
    \"width\": 70,\n\
    \"height\": 26,\n\
    \"text\": \"人气秒杀\",\n\
    \"alignment\": \"center\",\n\
    \"color\": \"white\",\n\
    \"font-size\": 13,\n\
    \"font-style\": \"medium\",\n\
    \"corner-radius\": 2,\n\
    \"background-color\": \"#F3363E\"\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"gone\": \"${style != 'both'}\",\n\
    \"spacing\": 3,\n\
    \"children\": [\n\
    {\n\
    \"background-color\": \"white\",\n\
    \"padding\": 10,\n\
    \"gone\": \"${bigBuy.itemList.count == 0}\",\n\
    \"vars\": {\n\
    \"item\": \"${bigBuy.itemList[0]}\"\n\
    },\n\
    \"spm-tag\": \"a13.b42.c3551.1\",\n\
    \"action\": \"${promoAction}\",\n\
    \"flex-grow\": 1,\n\
    \"flex-basis\": 1000,\n\
    \"direction\": \"vertical\",\n\
    \"children\": [\n\
    {\n\
    \"align-items\": \"center\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"flex-shrink\": 0,\n\
    \"text\": \"${bigBuyTitle}\",\n\
    \"color\": \"#313131\",\n\
    \"font-size\": \"${titleSize}\",\n\
    \"font-style\": \"medium\",\n\
    \"margin-right\": 5\n\
    },\n\
    {\n\
    \"ref\": \"${time_layout}\",\n\
    \"gone\": \"${small}\"\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"align-items\": \"center\",\n\
    \"margin-top\": 10,\n\
    \"children\": [\n\
    {\n\
    \"margin-right\": 5,\n\
    \"direction\": \"vertical\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.name}\",\n\
    \"font-size\": \"${nameSize}\",\n\
    \"color\": \"#313131\"\n\
    },\n\
    {\n\
    \"height\": 23,\n\
    \"align-items\": \"end\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.mainDesc}\",\n\
    \"color\": \"#F3363E\",\n\
    \"font-size\": \"${item.subDesc.length > 0 ? 18 : 15}\",\n\
    \"margin-bottom\": \"${item.subDesc.length > 0 ? -3 : 0}\",\n\
    \"font-style\": \"bold\"\n\
    },\n\
    {\n\
    \"flex-shrink\": 1000,\n\
    \"align-items\": \"end\",\n\
    \"wrap\": true,\n\
    \"clip\": true,\n\
    \"height\": 14,\n\
    \"line-spacing\": 20,\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.subDesc}\",\n\
    \"color\": \"#F3363E\",\n\
    \"font-size\": 12,\n\
    \"font-style\": \"medium\"\n\
    },\n\
    {\n\
    \"type\": \"text\",\n\
    \"margin-left\": 1,\n\
    \"color\": \"#888888\",\n\
    \"font-size\": 12,\n\
    \"html-text\": \"<s>${item.originalPrice}</s>\"\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"margin-left\": \"auto\",\n\
    \"type\": \"image\",\n\
    \"flex-shrink\": 0,\n\
    \"width\": \"${smallImageWidth}\",\n\
    \"height\": \"${smallImageWidth * 0.75}\",\n\
    \"border-width\": \"1px\",\n\
    \"border-color\": \"#ddd\",\n\
    \"clip\": true,\n\
    \"content-mode\": \"scale-aspect-fill\",\n\
    \"image\": \"O2O.bundle/imageLoading\",\n\
    \"image-url\": \"${item.imageUrl}\"\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"background-color\": \"white\",\n\
    \"padding\": 10,\n\
    \"flex-grow\": 1,\n\
    \"flex-basis\": 1000,\n\
    \"direction\": \"vertical\",\n\
    \"children\": [\n\
    {\n\
    \"spacing\": 5,\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"flex-shrink\": 0,\n\
    \"text\": \"专属优惠\",\n\
    \"color\": \"#313131\",\n\
    \"font-size\": \"${titleSize}\",\n\
    \"font-style\": \"medium\"\n\
    },\n\
    {\n\
    \"gone\": \"${small}\",\n\
    \"type\": \"text\",\n\
    \"color\": \"#F3363E\",\n\
    \"font-style\": \"medium\",\n\
    \"font-size\": 14,\n\
    \"text\": \"${exclusivePromo.subTitle}\"\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"vars\": {\n\
    \"item\": \"${exclusivePromo.itemList[0]}\"\n\
    },\n\
    \"margin-top\": \"auto\",\n\
    \"align-items\": \"center\",\n\
    \"spm-tag\": \"a13.b42.c3551.2\",\n\
    \"action\": {\n\
    \"url\": \"${item.jumpUrl}\",\n\
    \"log\": {\n\
    \"seed\": \"a13.b42.c3551.2\",\n\
    \"params\": {\n\
    \"title\": \"专属优惠\"\n\
    }\n\
    }\n\
    },\n\
    \"children\": [\n\
    {\n\
    \"margin-right\": 5,\n\
    \"direction\": \"vertical\",\n\
    \"children\": [\n\
    {\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.name}\",\n\
    \"font-size\": \"${nameSize}\",\n\
    \"color\": \"#313131\"\n\
    },\n\
    {\n\
    \"height\": 23,\n\
    \"children\": [\n\
    {\n\
    \"margin-top\": \"auto\",\n\
    \"type\": \"text\",\n\
    \"text\": \"${item.itemDesc}\",\n\
    \"font-size\": \"${plus ? 15 : 14}\",\n\
    \"font-style\": \"medium\",\n\
    \"color\": \"#F3363E\"\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    },\n\
    {\n\
    \"type\": \"image\",\n\
    \"content-mode\": \"scale-aspect-fill\",\n\
    \"flex-shrink\": 0,\n\
    \"width\": \"${smallImageWidth}\",\n\
    \"height\": \"${smallImageWidth * 0.75}\",\n\
    \"margin-left\": \"auto\",\n\
    \"border-width\": \"1px\",\n\
    \"border-color\": \"#ddd\",\n\
    \"image\": \"O2O.bundle/imageLoading\",\n\
    \"image-url\": \"${item.imageUrl}\",\n\
    \"clip\": true\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    }\n\
    ]\n\
    }\n\
    }";
}

- (void)testPerformanceJson {
    NSString *json = [self jsonString];
    [self measureBlock:^{
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }];
}

- (void)testPerformanceJsonByExpression {
    NSString *json = [self jsonString];
    id d1 = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    id d2 = VZT_COMPUTE(json);
    XCTAssertEqualObjects(d1, d2);
    [self measureBlock:^{
        VZT_COMPUTE(json);
    }];
}

- (void)testPerformanceLexer {
    NSString *text = [self jsonString];

    [self measureBlock:^{
        for (int i=0;i<100;i++) {
            VZTLexer *lexer = VZTLexer_new(text.UTF8String);
            while (lexer->token.type) {
                VZTLexer_next(lexer);
            }
            XCTAssert(lexer->error == NULL);
            VZTLexer_free(lexer);
        }
    }];
}

@end
