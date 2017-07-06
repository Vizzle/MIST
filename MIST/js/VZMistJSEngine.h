//
//  VZMistJSEngine.h
//  MIST
//
//  Created by lingwan on 2017/7/6.
//
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

id formatParamsToJS(id param);

@interface VZMistJSEngine : NSObject

+ (JSValue *)evaluateScript:(NSString *)script;

+ (JSContext *)context;

@end
