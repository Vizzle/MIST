//
//  VZMistJSEngine.h
//  MIST
//
//  Created by lingwan on 2017/7/6.
//
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

#define VZMistJSEngine VZMistVVY
#define convertOCToJS vzmistFIFO
#define convertJSToOC vzmistLIFO
#define formatOCParamsToJS vzmistXXZ

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

@interface VZMistJSEngine : NSObject

@property (nonatomic, strong) id context;

+ (instancetype)shared;

- (id)run:(id)text;

@end
