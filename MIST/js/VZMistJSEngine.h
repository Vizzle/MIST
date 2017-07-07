//
//  VZMistJSEngine.h
//  MIST
//
//  Created by lingwan on 2017/7/6.
//
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

id formatOCToJS(id obj);

id formatJSToOC(JSValue *jsval);

//Wrap params when call JSValue as Function directly
NSArray* formatOCParamsToJS(NSArray *arr);

@interface VZMistJSEngine : NSObject

+ (JSValue *)evaluateScript:(NSString *)script;

+ (JSContext *)context;

@end
