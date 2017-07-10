//
//  VZMistScriptEngine.h
//  MIST
//
//  Created by lingwan on 2017/7/6.
//
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

#ifdef __cplusplus
extern "C"{
#endif
    
id convertOCToJS(id obj);

id convertJSToOC(JSValue *jsval);
    
#ifdef __cplusplus
}
#endif

//Wrap params when call JSValue as Function directly
NSArray* formatOCParamsToJS(NSArray *arr);

@interface VZMistScriptEngine : NSObject

@property (nonatomic, strong) JSContext *context;

+ (instancetype)sharedEngine;

- (JSValue *)execute:(NSString *)script;

@end
