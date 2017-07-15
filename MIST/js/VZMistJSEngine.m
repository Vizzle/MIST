//
//  VZMistJSEngine.m
//  MIST
//
//  Created by lingwan on 2017/7/6.
//
//

#import "VZMistJSEngine.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#ifdef DEBUG
#import "VZMistScriptErrorWindow.h"
#import "VZScriptErrorMsgViewController.h"
#endif

#define VZObjectWrapper VZMistXBE
#define unwrap be36
#define unwrapPointer zy28
#define unwrapClass yuwj
#define boxAssignObj xyul
#define boxWeakObj loyj
#define boxClass hljh
#define boxObj lhfw
#define boxPointer wzds

#define assignObj aljfj
#define weakObj alfehw
#define pointer pojmn

#define superClassName fjfweo

#define _nullObj xljf
#define _nilObj okyh
#define _TMPMemoryPool lshw
#define _pointersToRelease wazg
#define _MethodSignatureCache azoy
#define _MethodSignatureCacheLock poiu

#define executeMethod pojyh
#define callBackBlockFromJSValue jlwhy
#define extractStructName lhyjw
#define _unboxOCObjectToJS wzega
#define _wrapObj poiuw
#define blockTypeIsObject wzgwg
#define blockTypeIsScalarPointer mnbjh

#define _regexStr xxxy
#define _replaceStr poizg
#define _regex hhmnh


@interface VZObjectWrapper : NSObject
@property (nonatomic) id obj;
@property (nonatomic) void *pointer;
@property (nonatomic) Class cls;
@property (nonatomic, weak) id weakObj;
@property (nonatomic, assign) id assignObj;
- (id)unwrap;
- (void *)unwrapPointer;
- (Class)unwrapClass;
@end

@implementation VZObjectWrapper

#define VZObjectWrapper_GEN(_name, _prop, _type) \
+ (instancetype)_name:(_type)obj  \
{   \
VZObjectWrapper *boxing = [[VZObjectWrapper alloc] init]; \
boxing._prop = obj;   \
return boxing;  \
}

VZObjectWrapper_GEN(boxAssignObj, assignObj, id)
VZObjectWrapper_GEN(boxWeakObj, weakObj, id)
VZObjectWrapper_GEN(boxClass, cls, Class)
VZObjectWrapper_GEN(boxObj, obj, id)
VZObjectWrapper_GEN(boxPointer, pointer, void *)

- (id)unwrap
{
    if (self.obj) return self.obj;
    if (self.weakObj) return self.weakObj;
    if (self.assignObj) return self.assignObj;
    if (self.cls) return self.cls;
    return self;
}
- (void *)unwrapPointer
{
    return self.pointer;
}
- (Class)unwrapClass
{
    return self.cls;
}
@end

static NSObject *_nullObj;
static NSObject *_nilObj;
static NSMutableDictionary *_TMPMemoryPool;
static NSMutableArray      *_pointersToRelease;
static NSMutableDictionary *_MethodSignatureCache;
static NSLock              *_MethodSignatureCacheLock;

static void (^_exceptionBlock)(NSString *log) = ^void(NSString *log) {
#ifdef DEBUG
    [VZMistScriptErrorWindow showWithErrorInfo:log];
#else
    NSCAssert(NO, log);
#endif
};

@interface VZMistJSEngine ()
@property (nonatomic, strong) NSMutableDictionary *superClassName;
@end

@implementation VZMistJSEngine

+ (instancetype)shared {
    static VZMistJSEngine *e = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        e = [[VZMistJSEngine alloc] init];
    });
    
    return e;
}

- (instancetype)init {
    if (self = [super init]) {
        self.superClassName = [[NSMutableDictionary alloc] init];

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _nilObj = [[NSObject alloc] init];
            _nullObj = [[NSObject alloc] init];
            _MethodSignatureCacheLock = [[NSLock alloc] init];
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clear) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    
    return self;
}

- (id)context {
    if (!_context) {
        _context = [self prepare];
    }
    
    return _context;
}

- (id)prepare
{
    JSContext *context = [[JSContext alloc] init];
    
    __weak VZMistJSEngine *weakSelf = self;
    context[@"callInstanceMethod"] = ^id(JSValue *obj, NSString *selectorName, JSValue *arguments, BOOL isSuper) {
        return executeMethod(weakSelf, nil, selectorName, arguments, obj, isSuper);
    };
    
    context[@"callClassMethod"] = ^id(NSString *className, NSString *selectorName, JSValue *arguments) {
        return executeMethod(weakSelf, className, selectorName, arguments, nil, NO);
    };
    
    context[@"_MIST_JSToOC"] = ^id(JSValue *obj) {
        return convertJSToOC(obj);
    };
    
    context[@"_MIST_OCtoJS"] = ^id(JSValue *obj) {
        return convertOCToJS([obj toObject]);
    };
    
    context[@"__weak"] = ^id(JSValue *jsval) {
        id obj = convertJSToOC(jsval);
        return [[JSContext currentContext][@"_convertOCtoJS"] callWithArguments:@[convertOCToJS([VZObjectWrapper boxWeakObj:obj])]];
    };
    
    context[@"__strong"] = ^id(JSValue *jsval) {
        id obj = convertJSToOC(jsval);
        return [[JSContext currentContext][@"_convertOCtoJS"] callWithArguments:@[convertOCToJS(obj)]];
    };
    
    context[@"_MIST_superClsName"] = ^(NSString *clsName) {
        Class cls = NSClassFromString(clsName);
        return NSStringFromClass([cls superclass]);
    };
    
    context[@"dispatch_after"] = ^(double time, JSValue *func) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"dispatch_async_main"] = ^(JSValue *func) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"dispatch_sync_main"] = ^(JSValue *func) {
        if ([NSThread currentThread].isMainThread) {
            [func callWithArguments:nil];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [func callWithArguments:nil];
            });
        }
    };
    
    context[@"dispatch_async_global_queue"] = ^(JSValue *func) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"flush"] = ^void(JSValue *jsVal) {
        if ([[jsVal toObject] isKindOfClass:[NSDictionary class]]) {
            void *pointer =  [(VZObjectWrapper *)([jsVal toObject][@"__obj"]) unwrapPointer];
            id obj = *((__unsafe_unretained id *)pointer);
            @synchronized(_TMPMemoryPool) {
                [_TMPMemoryPool removeObjectForKey:[NSNumber numberWithInteger:[(NSObject*)obj hash]]];
            }
        }
    };
    
    context[@"_MIST_log"] = ^() {
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            id obj = convertJSToOC(jsVal);
            NSLog(@"MISTJSEngine.log: %@", obj == _nilObj ? nil : (obj == _nullObj ? [NSNull null]: obj));
        }
    };
    
    context[@"_MIST_catch"] = ^(JSValue *msg, JSValue *stack) {
        _exceptionBlock([NSString stringWithFormat:@"js exception, \nmsg: %@, \nstack: \n %@", [msg toObject], [stack toObject]]);
    };
    
    context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
        NSLog(@"%@", exception);
        _exceptionBlock([NSString stringWithFormat:@"js exception: %@", exception]);
    };
    
    context[@"_OC_null"] = convertOCToJS(_nullObj);
    
    NSString *e = getEContent();
    [context evaluateScript:e];
    
    return context;
}

- (void)clear
{
    [_MethodSignatureCacheLock lock];
    _MethodSignatureCache = nil;
    [_MethodSignatureCacheLock unlock];
}

static NSString *_regexStr = @"(?<!\\\\)\\.\\s*(\\w+)\\s*\\(";
static id _regex;
static NSString *_replaceStr = @".__m(\"$1\")(";

- (id)run:(NSString *)script
{
    if (!script || ![JSContext class]) {
        _exceptionBlock(@"script is nil");
        return nil;
    }
    
    if (!_regex) {
        _regex = [NSRegularExpression regularExpressionWithPattern:_regexStr options:0 error:nil];
    }
    NSString *formatedScript = [NSString stringWithFormat:@";(function(){ try {\n%@\n}catch(e){_MIST_catch(e.message, e.stack)}})();", [_regex stringByReplacingMatchesInString:script options:0 range:NSMakeRange(0, script.length) withTemplate:_replaceStr]];
    @try {
        
#ifdef DEBUG
        return [self.context evaluateScript:formatedScript withSourceURL:[NSURL URLWithString:@"main.js"]];
#else
        return [self.context evaluateScript:formatedScript];
#endif
        
    }
    @catch (NSException *exception) {
        _exceptionBlock([NSString stringWithFormat:@"%@", exception]);
    }
    return nil;
}

#pragma mark -

static id executeMethod(VZMistJSEngine *engine, NSString *className, NSString *selectorName, JSValue *arguments, JSValue *instance, BOOL isSuper)
{
    JSContext *_context = engine.context;
    
    NSString *realClsName = [[instance valueForProperty:@"__realClsName"] toString];
    
    if (instance) {
        instance = convertJSToOC(instance);
        if (class_isMetaClass(object_getClass(instance))) {
            className = NSStringFromClass((Class)instance);
            instance = nil;
        } else if (!instance || instance == _nilObj || [instance isKindOfClass:[VZObjectWrapper class]]) {
            return @{@"__isNil": @(YES)};
        }
    }
    id argumentsObj = convertJSToOC(arguments);
    
    if (instance && [selectorName isEqualToString:@"toJS"]) {
        if ([instance isKindOfClass:[NSString class]] || [instance isKindOfClass:[NSDictionary class]] || [instance isKindOfClass:[NSArray class]] || [instance isKindOfClass:[NSDate class]]) {
            return _unboxOCObjectToJS(instance);
        }
    }
    
    Class cls = instance ? [instance class] : NSClassFromString(className);
    SEL selector = NSSelectorFromString(selectorName);
    
    NSString *superClassName = nil;
    if (isSuper) {
        NSString *superSelectorName = [NSString stringWithFormat:@"SUPER_%@", selectorName];
        SEL superSelector = NSSelectorFromString(superSelectorName);
        
        Class superCls;
        if (realClsName.length) {
            Class defineCls = NSClassFromString(realClsName);
            superCls = defineCls ? [defineCls superclass] : [cls superclass];
        } else {
            superCls = [cls superclass];
        }
        
        Method superMethod = class_getInstanceMethod(superCls, selector);
        IMP superIMP = method_getImplementation(superMethod);
        
        class_addMethod(cls, superSelector, superIMP, method_getTypeEncoding(superMethod));
        
        selector = superSelector;
        superClassName = NSStringFromClass(superCls);
    }
    
    NSMutableArray *_markArray;
    
    NSInvocation *invocation;
    NSMethodSignature *methodSignature;
    if (!_MethodSignatureCache) {
        _MethodSignatureCache = [[NSMutableDictionary alloc]init];
    }
    if (instance) {
        [_MethodSignatureCacheLock lock];
        if (!_MethodSignatureCache[cls]) {
            _MethodSignatureCache[(id<NSCopying>)cls] = [[NSMutableDictionary alloc]init];
        }
        methodSignature = _MethodSignatureCache[cls][selectorName];
        if (!methodSignature) {
            methodSignature = [cls instanceMethodSignatureForSelector:selector];
            _MethodSignatureCache[cls][selectorName] = methodSignature;
        }
        [_MethodSignatureCacheLock unlock];
        if (!methodSignature) {
            _exceptionBlock([NSString stringWithFormat:@"unrecognized selector %@ for instance %@", selectorName, instance]);
            return nil;
        }
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:instance];
    } else {
        methodSignature = [cls methodSignatureForSelector:selector];
        if (!methodSignature) {
            _exceptionBlock([NSString stringWithFormat:@"unrecognized selector %@ for class %@", selectorName, className]);
            return nil;
        }
        invocation= [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:cls];
    }
    [invocation setSelector:selector];
    
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        id valObj = argumentsObj[i-2];
        switch (argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
                
#define JP_CALL_ARG_CASE(_typeString, _type, _selector) \
case _typeString: {                              \
_type value = [valObj _selector];                     \
[invocation setArgument:&value atIndex:i];\
break; \
}
                
                JP_CALL_ARG_CASE('l', long, longValue)
                JP_CALL_ARG_CASE('L', unsigned long, unsignedLongValue)
                JP_CALL_ARG_CASE('q', long long, longLongValue)
                JP_CALL_ARG_CASE('c', char, charValue)
                JP_CALL_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
                JP_CALL_ARG_CASE('f', float, floatValue)
                JP_CALL_ARG_CASE('s', short, shortValue)
                JP_CALL_ARG_CASE('S', unsigned short, unsignedShortValue)
                JP_CALL_ARG_CASE('i', int, intValue)
                JP_CALL_ARG_CASE('d', double, doubleValue)
                JP_CALL_ARG_CASE('C', unsigned char, unsignedCharValue)
                JP_CALL_ARG_CASE('I', unsigned int, unsignedIntValue)
                JP_CALL_ARG_CASE('B', BOOL, boolValue)
                
            case ':': {
                SEL value = nil;
                if (valObj != _nilObj) {
                    value = NSSelectorFromString(valObj);
                }
                [invocation setArgument:&value atIndex:i];
                break;
            }
            case '{': {
                NSString *typeString = extractStructName([NSString stringWithUTF8String:argumentType]);
                JSValue *val = arguments[i-2];
#define JP_CALL_ARG_STRUCT(_type, _methodName) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type value = [val _methodName];  \
[invocation setArgument:&value atIndex:i];  \
break; \
}
                JP_CALL_ARG_STRUCT(CGSize, toSize)
                JP_CALL_ARG_STRUCT(CGPoint, toPoint)
                JP_CALL_ARG_STRUCT(NSRange, toRange)
                JP_CALL_ARG_STRUCT(CGRect, toRect)
                break;
            }
            case '#': {
                if ([valObj isKindOfClass:[VZObjectWrapper class]]) {
                    Class value = [((VZObjectWrapper *)valObj) unwrapClass];
                    [invocation setArgument:&value atIndex:i];
                    break;
                }
            }
            case '*':
            case '^': {
                if ([valObj isKindOfClass:[VZObjectWrapper class]]) {
                    void *value = [((VZObjectWrapper *)valObj) unwrapPointer];
                    
                    if (argumentType[1] == '@') {
                        if (!_TMPMemoryPool) {
                            _TMPMemoryPool = [[NSMutableDictionary alloc] init];
                        }
                        if (!_markArray) {
                            _markArray = [[NSMutableArray alloc] init];
                        }
                        memset(value, 0, sizeof(id));
                        [_markArray addObject:valObj];
                    }
                    
                    [invocation setArgument:&value atIndex:i];
                    break;
                }
            }
            default: {
                if (valObj == _nullObj) {
                    valObj = [NSNull null];
                    [invocation setArgument:&valObj atIndex:i];
                    break;
                }
                if (valObj == _nilObj ||
                    ([valObj isKindOfClass:[NSNumber class]] && strcmp([valObj objCType], "c") == 0 && ![valObj boolValue])) {
                    valObj = nil;
                    [invocation setArgument:&valObj atIndex:i];
                    break;
                }
                if ([(JSValue *)arguments[i-2] hasProperty:@"__isBlock"]) {
                    __autoreleasing id cb = callBackBlockFromJSValue(arguments[i-2]);
                    [invocation setArgument:&cb atIndex:i];
                } else {
                    [invocation setArgument:&valObj atIndex:i];
                }
            }
        }
    }
    
    if (superClassName) engine.superClassName[selectorName] = superClassName;
    [invocation invoke];
    if (superClassName) [engine.superClassName removeObjectForKey:selectorName];
    if ([_markArray count] > 0) {
        for (VZObjectWrapper *box in _markArray) {
            void *pointer = [box unwrapPointer];
            id obj = *((__unsafe_unretained id *)pointer);
            if (obj) {
                @synchronized(_TMPMemoryPool) {
                    [_TMPMemoryPool setObject:obj forKey:[NSNumber numberWithInteger:[(NSObject*)obj hash]]];
                }
            }
        }
    }
    
    char returnType[255];
    strcpy(returnType, [methodSignature methodReturnType]);
    
    id returnValue;
    if (strncmp(returnType, "v", 1) != 0) {
        if (strncmp(returnType, "@", 1) == 0) {
            void *result;
            [invocation getReturnValue:&result];
            
            //For performance, ignore the other methods prefix with alloc/new/copy/mutableCopy
            if ([selectorName isEqualToString:@"alloc"] || [selectorName isEqualToString:@"new"] ||
                [selectorName isEqualToString:@"copy"] || [selectorName isEqualToString:@"mutableCopy"]) {
                returnValue = (__bridge_transfer id)result;
            } else {
                returnValue = (__bridge id)result;
            }
            return convertOCToJS(returnValue);
            
        } else {
            switch (returnType[0] == 'r' ? returnType[1] : returnType[0]) {
                    
#define JP_CALL_RET_CASE(_typeString, _type) \
case _typeString: {                              \
_type tempResultSet; \
[invocation getReturnValue:&tempResultSet];\
returnValue = @(tempResultSet); \
break; \
}
                    
                    JP_CALL_RET_CASE('L', unsigned long)
                    JP_CALL_RET_CASE('q', long long)
                    JP_CALL_RET_CASE('Q', unsigned long long)
                    JP_CALL_RET_CASE('c', char)
                    JP_CALL_RET_CASE('B', BOOL)
                    JP_CALL_RET_CASE('S', unsigned short)
                    JP_CALL_RET_CASE('f', float)
                    JP_CALL_RET_CASE('d', double)
                    JP_CALL_RET_CASE('I', unsigned int)
                    JP_CALL_RET_CASE('l', long)
                    JP_CALL_RET_CASE('i', int)
                    JP_CALL_RET_CASE('C', unsigned char)
                    JP_CALL_RET_CASE('s', short)
                    
                case '{': {
                    NSString *typeString = extractStructName([NSString stringWithUTF8String:returnType]);
#define JP_CALL_RET_STRUCT(_type, _methodName) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type result;   \
[invocation getReturnValue:&result];    \
return [JSValue _methodName:result inContext:_context];    \
}
                    JP_CALL_RET_STRUCT(CGRect, valueWithRect)
                    JP_CALL_RET_STRUCT(NSRange, valueWithRange)
                    JP_CALL_RET_STRUCT(CGSize, valueWithSize)
                    JP_CALL_RET_STRUCT(CGPoint, valueWithPoint)
                    break;
                }
                case '*':
                case '^': {
                    void *result;
                    [invocation getReturnValue:&result];
                    returnValue = convertOCToJS([VZObjectWrapper boxPointer:result]);
                    if (strncmp(returnType, "^{CG", 4) == 0) {
                        if (!_pointersToRelease) {
                            _pointersToRelease = [[NSMutableArray alloc] init];
                        }
                        [_pointersToRelease addObject:[NSValue valueWithPointer:result]];
                        CFRetain(result);
                    }
                    
                    //lingwan todo
//                    if (_pointersToRelease) {
//                        for (NSValue *val in _pointersToRelease) {
//                            void *pointer = NULL;
//                            [val getValue:&pointer];
//                            CFRelease(pointer);
//                        }
//                        _pointersToRelease = nil;
//                    }
                    
                    break;
                }
                case '#': {
                    Class result;
                    [invocation getReturnValue:&result];
                    returnValue = convertOCToJS([VZObjectWrapper boxClass:result]);
                    break;
                }
            }
            return returnValue;
        }
    }
    return nil;
}

#pragma mark -

static id callBackBlockFromJSValue(JSValue *jsVal)
{
#define BLK_TRAITS_ARG(_idx, _paramName) \
if (_idx < argTypes.count) { \
NSString *argType = trim(argTypes[_idx]); \
if (blockTypeIsScalarPointer(argType)) { \
[list addObject:convertOCToJS([VZObjectWrapper boxPointer:_paramName])]; \
} else if (blockTypeIsObject(trim(argTypes[_idx]))) {  \
[list addObject:convertOCToJS((__bridge id)_paramName)]; \
} else {  \
[list addObject:convertOCToJS([NSNumber numberWithLongLong:(long long)_paramName])]; \
}   \
}
    
    NSArray *argTypes = [[jsVal[@"args"] toString] componentsSeparatedByString:@","];
    id cb = ^id(void *p0, void *p1, void *p2, void *p3, void *p4, void *p5) {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        BLK_TRAITS_ARG(0, p0)
        BLK_TRAITS_ARG(1, p1)
        BLK_TRAITS_ARG(2, p2)
        BLK_TRAITS_ARG(3, p3)
        BLK_TRAITS_ARG(4, p4)
        BLK_TRAITS_ARG(5, p5)
        JSValue *ret = [jsVal[@"cb"] callWithArguments:list];
        return convertJSToOC(ret);
    };
    
    return cb;
}

#pragma mark - Struct

static NSString *extractStructName(NSString *typeEncodeString)
{
    NSArray *array = [typeEncodeString componentsSeparatedByString:@"="];
    NSString *typeString = array[0];
    int firstValidIndex = 0;
    for (int i = 0; i< typeString.length; i++) {
        char c = [typeString characterAtIndex:i];
        if (c == '{' || c=='_') {
            firstValidIndex++;
        }else {
            break;
        }
    }
    return [typeString substringFromIndex:firstValidIndex];
}

#pragma mark - Utils

static NSString *trim(NSString *string)
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static BOOL blockTypeIsObject(NSString *typeString)
{
    return [typeString rangeOfString:@"*"].location != NSNotFound || [typeString isEqualToString:@"id"];
}

static BOOL blockTypeIsScalarPointer(NSString *typeString)
{
    NSUInteger location = [typeString rangeOfString:@"*"].location;
    NSString *typeWithoutAsterisk = trim([typeString stringByReplacingOccurrencesOfString:@"*" withString:@""]);
    
    return (location == typeString.length-1 &&
            !NSClassFromString(typeWithoutAsterisk));
}

#pragma mark - Object format

static NSDictionary *_wrapObj(id obj)
{
    if (!obj || obj == _nilObj) {
        return @{@"__isNil": @(YES)};
    }
    return @{@"__obj": obj, @"__clsName": NSStringFromClass([obj isKindOfClass:[VZObjectWrapper class]] ? [[((VZObjectWrapper *)obj) unwrap] class]: [obj class])};
}

static id _unboxOCObjectToJS(id obj)
{
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:_unboxOCObjectToJS(obj[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:_unboxOCObjectToJS(obj[key]) forKey:key];
        }
        return newDict;
    }
    if ([obj isKindOfClass:[NSString class]] ||[obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:NSClassFromString(@"NSBlock")] || [obj isKindOfClass:[NSDate class]]) {
        return obj;
    }
    return _wrapObj(obj);
}



# pragma mark -

static char E_CONTENT[] = {171,188,175,253,186,177,178,191,188,177,224,169,181,180,174,230,245,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,130,178,190,158,177,174,224,166,160,230,171,188,175,253,130,183,174,158,177,174,224,166,160,230,171,188,175,253,130,190,178,179,171,184,175,169,146,158,169,178,151,142,224,187,168,179,190,169,180,178,179,245,178,191,183,244,166,180,187,245,178,191,183,224,224,224,168,179,185,184,187,180,179,184,185,161,161,178,191,183,224,224,224,179,168,177,177,244,175,184,169,168,175,179,253,187,188,177,174,184,215,180,187,245,169,164,173,184,178,187,253,178,191,183,224,224,255,178,191,183,184,190,169,255,244,166,180,187,245,178,191,183,243,130,130,178,191,183,244,175,184,169,168,175,179,253,178,191,183,215,180,187,245,178,191,183,243,130,130,180,174,147,180,177,244,175,184,169,168,175,179,253,187,188,177,174,184,160,215,180,187,245,178,191,183,253,180,179,174,169,188,179,190,184,178,187,253,156,175,175,188,164,244,166,171,188,175,253,175,184,169,224,134,128,215,178,191,183,243,187,178,175,152,188,190,181,245,187,168,179,190,169,180,178,179,245,178,244,166,175,184,169,243,173,168,174,181,245,130,190,178,179,171,184,175,169,146,158,169,178,151,142,245,178,244,244,160,244,215,175,184,169,168,175,179,253,175,184,169,160,215,180,187,245,178,191,183,253,180,179,174,169,188,179,190,184,178,187,253,155,168,179,190,169,180,178,179,244,166,175,184,169,168,175,179,253,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,188,175,186,174,224,156,175,175,188,164,243,173,175,178,169,178,169,164,173,184,243,174,177,180,190,184,243,190,188,177,177,245,188,175,186,168,176,184,179,169,174,244,215,171,188,175,253,187,178,175,176,188,169,184,185,156,175,186,174,224,130,144,148,142,137,130,151,142,137,178,146,158,245,188,175,186,174,244,215,187,178,175,245,171,188,175,253,180,224,237,230,180,225,188,175,186,174,243,177,184,179,186,169,181,230,180,246,246,244,166,180,187,245,188,175,186,174,134,180,128,224,224,224,179,168,177,177,161,161,188,175,186,174,134,180,128,224,224,224,168,179,185,184,187,180,179,184,185,161,161,188,175,186,174,134,180,128,224,224,224,187,188,177,174,184,244,166,187,178,175,176,188,169,184,185,156,175,186,174,243,174,173,177,180,190,184,245,180,241,236,241,168,179,185,184,187,180,179,184,185,244,160,184,177,174,184,253,180,187,245,188,175,186,174,134,180,128,224,224,179,174,179,168,177,177,244,166,187,178,175,176,188,169,184,185,156,175,186,174,243,174,173,177,180,190,184,245,180,241,236,241,179,168,177,177,244,160,160,215,175,184,169,168,175,179,253,130,144,148,142,137,130,146,158,169,178,151,142,245,178,191,183,243,188,173,173,177,164,245,178,191,183,241,187,178,175,176,188,169,184,185,156,175,186,174,244,244,160,160,215,180,187,245,178,191,183,253,180,179,174,169,188,179,190,184,178,187,253,146,191,183,184,190,169,244,166,171,188,175,253,175,184,169,224,166,160,215,187,178,175,245,171,188,175,253,182,184,164,253,180,179,253,178,191,183,244,166,175,184,169,134,182,184,164,128,224,130,190,178,179,171,184,175,169,146,158,169,178,151,142,245,178,191,183,134,182,184,164,128,244,160,215,175,184,169,168,175,179,253,175,184,169,160,215,175,184,169,168,175,179,253,178,191,183,160,215,171,188,175,253,130,176,184,169,181,178,185,155,168,179,190,224,187,168,179,190,169,180,178,179,245,180,179,174,169,188,179,190,184,241,190,177,174,147,188,176,184,241,176,184,169,181,178,185,147,188,176,184,241,188,175,186,174,241,180,174,142,168,173,184,175,241,180,174,141,184,175,187,178,175,176,142,184,177,184,190,169,178,175,244,166,171,188,175,253,174,184,177,184,190,169,178,175,147,188,176,184,224,176,184,169,181,178,185,147,188,176,184,215,180,187,245,252,180,174,141,184,175,187,178,175,176,142,184,177,184,190,169,178,175,244,166,176,184,169,181,178,185,147,188,176,184,224,176,184,169,181,178,185,147,188,176,184,243,175,184,173,177,188,190,184,245,242,130,130,242,186,241,255,240,255,244,215,174,184,177,184,190,169,178,175,147,188,176,184,224,176,184,169,181,178,185,147,188,176,184,243,175,184,173,177,188,190,184,245,242,130,242,186,241,255,231,255,244,243,175,184,173,177,188,190,184,245,242,240,242,186,241,255,130,255,244,215,171,188,175,253,176,188,175,190,181,156,175,175,224,174,184,177,184,190,169,178,175,147,188,176,184,243,176,188,169,190,181,245,242,231,242,186,244,215,171,188,175,253,179,168,176,146,187,156,175,186,174,224,176,188,175,190,181,156,175,175,226,176,188,175,190,181,156,175,175,243,177,184,179,186,169,181,231,237,215,180,187,245,188,175,186,174,243,177,184,179,186,169,181,227,179,168,176,146,187,156,175,186,174,244,166,174,184,177,184,190,169,178,175,147,188,176,184,246,224,255,231,255,160,160,215,171,188,175,253,175,184,169,224,180,179,174,169,188,179,190,184,226,190,188,177,177,148,179,174,169,188,179,190,184,144,184,169,181,178,185,245,180,179,174,169,188,179,190,184,241,174,184,177,184,190,169,178,175,147,188,176,184,241,188,175,186,174,241,180,174,142,168,173,184,175,244,231,190,188,177,177,158,177,188,174,174,144,184,169,181,178,185,245,190,177,174,147,188,176,184,241,174,184,177,184,190,169,178,175,147,188,176,184,241,188,175,186,174,244,215,175,184,169,168,175,179,253,130,190,178,179,171,184,175,169,146,158,169,178,151,142,245,175,184,169,244,160,215,171,188,175,253,130,190,168,174,169,178,176,144,184,169,181,178,185,174,224,166,130,130,176,231,187,168,179,190,169,180,178,179,245,176,184,169,181,178,185,147,188,176,184,244,166,171,188,175,253,174,177,187,224,169,181,180,174,215,180,187,245,174,177,187,253,180,179,174,169,188,179,190,184,178,187,253,159,178,178,177,184,188,179,244,166,175,184,169,168,175,179,253,187,168,179,190,169,180,178,179,245,244,166,175,184,169,168,175,179,253,187,188,177,174,184,160,160,215,180,187,245,174,177,187,134,176,184,169,181,178,185,147,188,176,184,128,244,166,175,184,169,168,175,179,253,174,177,187,134,176,184,169,181,178,185,147,188,176,184,128,243,191,180,179,185,245,174,177,187,244,230,160,215,180,187,245,252,174,177,187,243,130,130,178,191,183,251,251,252,174,177,187,243,130,130,190,177,174,147,188,176,184,244,166,169,181,175,178,170,253,179,184,170,253,152,175,175,178,175,245,174,177,187,246,250,243,250,246,176,184,169,181,178,185,147,188,176,184,246,250,253,180,174,253,168,179,185,184,187,180,179,184,185,250,244,160,215,180,187,245,174,177,187,243,130,130,180,174,142,168,173,184,175,251,251,174,177,187,243,130,130,190,177,174,147,188,176,184,244,166,174,177,187,243,130,130,190,177,174,147,188,176,184,224,130,144,148,142,137,130,174,168,173,184,175,158,177,174,147,188,176,184,245,174,177,187,243,130,130,178,191,183,243,130,130,175,184,188,177,158,177,174,147,188,176,184,226,174,177,187,243,130,130,178,191,183,243,130,130,175,184,188,177,158,177,174,147,188,176,184,231,174,177,187,243,130,130,190,177,174,147,188,176,184,244,230,160,215,171,188,175,253,190,177,174,147,188,176,184,224,174,177,187,243,130,130,190,177,174,147,188,176,184,215,180,187,245,190,177,174,147,188,176,184,251,251,130,178,190,158,177,174,134,190,177,174,147,188,176,184,128,244,166,171,188,175,253,176,184,169,181,178,185,137,164,173,184,224,174,177,187,243,130,130,178,191,183,226,250,180,179,174,169,144,184,169,181,178,185,174,250,231,250,190,177,174,144,184,169,181,178,185,174,250,215,180,187,245,130,178,190,158,177,174,134,190,177,174,147,188,176,184,128,134,176,184,169,181,178,185,137,164,173,184,128,134,176,184,169,181,178,185,147,188,176,184,128,244,166,174,177,187,243,130,130,180,174,142,168,173,184,175,224,237,230,175,184,169,168,175,179,253,130,178,190,158,177,174,134,190,177,174,147,188,176,184,128,134,176,184,169,181,178,185,137,164,173,184,128,134,176,184,169,181,178,185,147,188,176,184,128,243,191,180,179,185,245,174,177,187,244,160,160,215,175,184,169,168,175,179,253,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,188,175,186,174,224,156,175,175,188,164,243,173,175,178,169,178,169,164,173,184,243,174,177,180,190,184,243,190,188,177,177,245,188,175,186,168,176,184,179,169,174,244,215,175,184,169,168,175,179,253,130,176,184,169,181,178,185,155,168,179,190,245,174,177,187,243,130,130,178,191,183,241,174,177,187,243,130,130,190,177,174,147,188,176,184,241,176,184,169,181,178,185,147,188,176,184,241,188,175,186,174,241,174,177,187,243,130,130,180,174,142,168,173,184,175,244,160,160,241,174,168,173,184,175,231,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,174,177,187,224,169,181,180,174,215,180,187,245,174,177,187,243,130,130,178,191,183,244,166,174,177,187,243,130,130,178,191,183,243,130,130,175,184,188,177,158,177,174,147,188,176,184,224,174,177,187,243,130,130,175,184,188,177,158,177,174,147,188,176,184,230,160,215,175,184,169,168,175,179,166,130,130,178,191,183,231,174,177,187,243,130,130,178,191,183,241,130,130,190,177,174,147,188,176,184,231,174,177,187,243,130,130,190,177,174,147,188,176,184,241,130,130,180,174,142,168,173,184,175,231,236,160,160,241,173,184,175,187,178,175,176,142,184,177,184,190,169,178,175,148,179,146,158,231,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,174,177,187,224,169,181,180,174,215,171,188,175,253,188,175,186,174,224,156,175,175,188,164,243,173,175,178,169,178,169,164,173,184,243,174,177,180,190,184,243,190,188,177,177,245,188,175,186,168,176,184,179,169,174,244,215,175,184,169,168,175,179,166,130,130,180,174,141,184,175,187,178,175,176,148,179,146,158,231,236,241,178,191,183,231,174,177,187,243,130,130,178,191,183,241,190,177,174,147,188,176,184,231,174,177,187,243,130,130,190,177,174,147,188,176,184,241,174,184,177,231,188,175,186,174,134,237,128,241,188,175,186,174,231,188,175,186,174,134,236,128,241,190,191,231,188,175,186,174,134,239,128,160,160,241,173,184,175,187,178,175,176,142,184,177,184,190,169,178,175,231,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,174,177,187,224,169,181,180,174,215,171,188,175,253,188,175,186,174,224,156,175,175,188,164,243,173,175,178,169,178,169,164,173,184,243,174,177,180,190,184,243,190,188,177,177,245,188,175,186,168,176,184,179,169,174,244,215,175,184,169,168,175,179,253,130,176,184,169,181,178,185,155,168,179,190,245,174,177,187,243,130,130,178,191,183,241,174,177,187,243,130,130,190,177,174,147,188,176,184,241,188,175,186,174,134,237,128,241,188,175,186,174,243,174,173,177,180,190,184,245,236,244,241,174,177,187,243,130,130,180,174,142,168,173,184,175,241,169,175,168,184,244,160,160,215,187,178,175,245,171,188,175,253,176,184,169,181,178,185,253,180,179,253,130,190,168,174,169,178,176,144,184,169,181,178,185,174,244,166,180,187,245,130,190,168,174,169,178,176,144,184,169,181,178,185,174,243,181,188,174,146,170,179,141,175,178,173,184,175,169,164,245,176,184,169,181,178,185,244,244,166,146,191,183,184,190,169,243,185,184,187,180,179,184,141,175,178,173,184,175,169,164,245,146,191,183,184,190,169,243,173,175,178,169,178,169,164,173,184,241,176,184,169,181,178,185,241,166,171,188,177,168,184,231,130,190,168,174,169,178,176,144,184,169,181,178,185,174,134,176,184,169,181,178,185,128,241,190,178,179,187,180,186,168,175,188,191,177,184,231,187,188,177,174,184,241,184,179,168,176,184,175,188,191,177,184,231,187,188,177,174,184,160,244,160,160,215,171,188,175,253,130,175,184,172,168,180,175,184,224,187,168,179,190,169,180,178,179,245,190,177,174,147,188,176,184,244,166,180,187,245,252,186,177,178,191,188,177,134,190,177,174,147,188,176,184,128,244,166,186,177,178,191,188,177,134,190,177,174,147,188,176,184,128,224,166,130,130,190,177,174,147,188,176,184,231,190,177,174,147,188,176,184,160,160,215,175,184,169,168,175,179,253,186,177,178,191,188,177,134,190,177,174,147,188,176,184,128,160,215,186,177,178,191,188,177,243,175,184,172,168,180,175,184,224,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,177,188,174,169,143,184,172,168,180,175,184,215,187,178,175,245,171,188,175,253,180,224,237,230,180,225,188,175,186,168,176,184,179,169,174,243,177,184,179,186,169,181,230,180,246,246,244,166,188,175,186,168,176,184,179,169,174,134,180,128,243,174,173,177,180,169,245,250,241,250,244,243,187,178,175,152,188,190,181,245,187,168,179,190,169,180,178,179,245,190,177,174,147,188,176,184,244,166,177,188,174,169,143,184,172,168,180,175,184,224,130,175,184,172,168,180,175,184,245,190,177,174,147,188,176,184,243,169,175,180,176,245,244,244,160,244,160,215,175,184,169,168,175,179,253,177,188,174,169,143,184,172,168,180,175,184,160,215,186,177,178,191,188,177,243,191,177,178,190,182,224,187,168,179,190,169,180,178,179,245,188,175,186,174,241,190,191,244,166,171,188,175,253,169,181,188,169,224,169,181,180,174,215,171,188,175,253,174,177,187,224,186,177,178,191,188,177,243,174,184,177,187,215,180,187,245,188,175,186,174,253,180,179,174,169,188,179,190,184,178,187,253,155,168,179,190,169,180,178,179,244,166,190,191,224,188,175,186,174,215,188,175,186,174,224,250,250,160,215,171,188,175,253,190,188,177,177,191,188,190,182,224,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,188,175,186,174,224,156,175,175,188,164,243,173,175,178,169,178,169,164,173,184,243,174,177,180,190,184,243,190,188,177,177,245,188,175,186,168,176,184,179,169,174,244,215,186,177,178,191,188,177,243,174,184,177,187,224,174,177,187,215,175,184,169,168,175,179,253,190,191,243,188,173,173,177,164,245,169,181,188,169,241,130,190,178,179,171,184,175,169,146,158,169,178,151,142,245,188,175,186,174,244,244,160,215,175,184,169,168,175,179,166,188,175,186,174,231,188,175,186,174,241,190,191,231,190,188,177,177,191,188,190,182,241,130,130,180,174,159,177,178,190,182,231,236,160,160,215,180,187,245,186,177,178,191,188,177,243,190,178,179,174,178,177,184,244,166,171,188,175,253,183,174,145,178,186,186,184,175,224,190,178,179,174,178,177,184,243,177,178,186,230,186,177,178,191,188,177,243,190,178,179,174,178,177,184,243,177,178,186,224,187,168,179,190,169,180,178,179,245,244,166,186,177,178,191,188,177,243,130,144,148,142,137,130,177,178,186,243,188,173,173,177,164,245,186,177,178,191,188,177,241,188,175,186,168,176,184,179,169,174,244,230,180,187,245,183,174,145,178,186,186,184,175,244,166,183,174,145,178,186,186,184,175,243,188,173,173,177,164,245,186,177,178,191,188,177,243,190,178,179,174,178,177,184,241,188,175,186,168,176,184,179,169,174,244,230,160,160,160,184,177,174,184,166,186,177,178,191,188,177,243,190,178,179,174,178,177,184,224,166,177,178,186,231,186,177,178,191,188,177,243,130,144,148,142,137,130,177,178,186,160,160,215,186,177,178,191,188,177,243,184,165,173,178,175,169,224,187,168,179,190,169,180,178,179,245,244,166,171,188,175,253,188,175,186,174,224,156,175,175,188,164,243,173,175,178,169,178,169,164,173,184,243,174,177,180,190,184,243,190,188,177,177,245,188,175,186,168,176,184,179,169,174,244,215,188,175,186,174,243,187,178,175,152,188,190,181,245,187,168,179,190,169,180,178,179,245,178,244,166,180,187,245,178,253,180,179,174,169,188,179,190,184,178,187,253,155,168,179,190,169,180,178,179,244,166,186,177,178,191,188,177,134,178,243,179,188,176,184,128,224,178,160,184,177,174,184,253,180,187,245,178,253,180,179,174,169,188,179,190,184,178,187,253,146,191,183,184,190,169,244,166,187,178,175,245,171,188,175,253,173,175,178,173,184,175,169,164,253,180,179,253,178,244,166,180,187,245,178,243,181,188,174,146,170,179,141,175,178,173,184,175,169,164,245,173,175,178,173,184,175,169,164,244,244,166,186,177,178,191,188,177,134,173,175,178,173,184,175,169,164,128,224,178,134,173,175,178,173,184,175,169,164,128,160,160,160,160,244,160,215,186,177,178,191,188,177,243,132,152,142,224,236,215,186,177,178,191,188,177,243,147,146,224,237,215,186,177,178,191,188,177,243,179,174,179,168,177,177,224,130,146,158,130,179,168,177,177,215,186,177,178,191,188,177,243,130,190,178,179,171,184,175,169,146,158,169,178,151,142,224,130,190,178,179,171,184,175,169,146,158,169,178,151,142,160,244,245,244};

static NSString* getEContent()
{
    char* buffer = malloc(sizeof(E_CONTENT) + 1);
    for (unsigned i = 0; i < sizeof(E_CONTENT); i ++)
        buffer[i] = E_CONTENT[i] ^ 0xDD;
    buffer[sizeof(E_CONTENT)] = 0;
    NSString* script = [[NSString alloc] initWithBytes:buffer length:sizeof(E_CONTENT) encoding:NSUTF8StringEncoding];
    free(buffer);
    return script;
}


@end

id convertOCToJS(id obj)
{
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDate class]]) {
        return _wrapObj([VZObjectWrapper boxObj:obj]);
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return obj;
    }
    if ([obj isKindOfClass:NSClassFromString(@"NSBlock")] || [obj isKindOfClass:[JSValue class]]) {
        return obj;
    }
    return _wrapObj(obj);
}

id convertJSToOC(JSValue *jsval)
{
    id obj = [jsval toObject];
    if (!obj || [obj isKindOfClass:[NSNull class]]) return _nilObj;
    
    if ([obj isKindOfClass:[VZObjectWrapper class]]) return [obj unwrap];
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:convertJSToOC(jsval[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        if (obj[@"__obj"]) {
            id ocObj = [obj objectForKey:@"__obj"];
            if ([ocObj isKindOfClass:[VZObjectWrapper class]]) return [ocObj unwrap];
            return ocObj;
        }
        if (obj[@"__isBlock"]) {
            return callBackBlockFromJSValue(jsval);
        }
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:convertJSToOC(jsval[key]) forKey:key];
        }
        return newDict;
    }
    return obj;
}

NSArray* formatOCParamsToJS(NSArray *arr) {
    NSCAssert(arr.count, @"VZMistJSEngine: nil params array passed in");
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:arr.count];
    for (id item in arr) {
        [ret addObject:convertOCToJS(item)];
    }
    return ret;
}
