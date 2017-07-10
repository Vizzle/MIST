//
//  VZMistScriptEngine.h
//  MIST
//
//  Created by lingwan on 2017/7/6.
//
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

id convertOCToJS(id obj);

id convertJSToOC(JSValue *jsval);

//Wrap params when call JSValue as Function directly
NSArray* formatOCParamsToJS(NSArray *arr);

@interface VZMistScriptEngine : NSObject

+ (JSValue *)execute:(NSString *)script;

+ (JSContext *)currentEngine;

@end
