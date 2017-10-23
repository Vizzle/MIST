//
//  VZMistTemplate.m
//  MIST
//
//  Created by moxin on 2016/12/6.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZMistTemplate.h"
#import "VZDataStructure.h"
#import "VZMistTemplateHelper.h"
#import "VZMistTemplateController.h"
#import "VZMist.h"
#import "VZMistError.h"
#import "VZMistCallHelper.h"
#import "VZMistTemplateAction.h"

@implementation VZMistTemplate

- (instancetype)initWithTemplateId:(NSString *)tplId content:(NSDictionary *)content mistInstance:(VZMist *)mistInstance
{
    if (self = [super init]) {
        if (![content isKindOfClass:[NSDictionary class]]) {
            NSAssert(content, @"%@: a template with empty content %@", self.class, content);
            VZMistError *error = [VZMistError templateEmptyErrorWithTemplateId:tplId];
            mistInstance.errorCallback(error);
            return nil;
        }
        NSDictionary *layout = __vzDictionary(content[@"layout"], nil);
        if (!layout) {
            NSAssert(layout, @"%@: a template with empty content %@", self.class, content);
            VZMistError *error = [VZMistError templateEmptyErrorWithTemplateId:tplId];
            mistInstance.errorCallback(error);
            return nil;
        }

        _tplId = tplId;
        _script = content[@"script"];
        if (_script.length) {
            [[VZMistCallHelper shared] run:_script];
        }
        
        _tplRawContent = [content copy];
        _tplParsedResult = [VZMistTemplateHelper parseExpressionsInTemplate:layout mistInstance:mistInstance];
        _tplControllerClass = NSClassFromString(content[@"controller"]);
        NSAssert(!_tplControllerClass || [_tplControllerClass isSubclassOfClass:[VZMistTemplateController class]], @"controller must be inherited from VZMistTemplateController");
        if (![_tplControllerClass isSubclassOfClass:[VZMistTemplateController class]]) {
            _tplControllerClass = nil;
        }
        _initialState = [VZMistTemplateHelper parseExpressionsInTemplate:content[@"state"] mistInstance:mistInstance];
        _data = [VZMistTemplateHelper parseExpressionsInTemplate:content[@"data"] mistInstance:mistInstance];
        _actions = [VZMistTemplateHelper parseExpressionsInTemplate:__vzDictionary(content[@"actions"], nil) mistInstance:mistInstance];
        _notifications = [VZMistTemplateHelper parseExpressionsInTemplate:__vzDictionary(content[@"notifications"], nil) mistInstance:mistInstance];
        _identifier = content[@"identifier"];
        _styles = __vzDictionary([VZMistTemplateHelper parseExpressionsInTemplate:content[@"styles"] mistInstance:mistInstance], nil);
        _asyncDisplay = __vzBool(content[@"async-display"], NO);
        _cellHeightAnimation = __vzBool(content[@"cell-height-animation"], NO);
        _tplReuseIdentifier = content[@"reuse-identifier"];
        _onStateUpdated = __vzDictionary([VZMistTemplateHelper parseExpressionsInTemplate:content[@"on-state-updated"] mistInstance:mistInstance], nil);
    }
    return self;
}

@end
