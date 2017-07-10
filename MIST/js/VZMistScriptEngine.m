//
//  VZMistScriptEngine.m
//  MIST
//
//  Created by lingwan on 2017/7/6.
//
//

#import "VZMistScriptEngine.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#ifdef DEBUG
#import "VZMistScriptErrorWindow.h"
#import "VZScriptErrorMsgViewController.h"
#endif

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

@interface VZMistScriptEngine ()
@property (nonatomic, strong) NSMutableDictionary *currentSuperClassName;
@end

@implementation VZMistScriptEngine

+ (instancetype)sharedEngine {
    static VZMistScriptEngine *engine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        engine = [[VZMistScriptEngine alloc] init];
    });
    
    return engine;
}

- (instancetype)init {
    if (self = [super init]) {
        _currentSuperClassName = [[NSMutableDictionary alloc] init];

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _nilObj = [[NSObject alloc] init];
            _nullObj = [[NSObject alloc] init];
            _MethodSignatureCacheLock = [[NSLock alloc] init];
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    
    return self;
}

- (JSContext *)context {
    if (!_context) {
        _context = [self prepareJSContext];
    }
    
    return _context;
}

- (JSContext *)prepareJSContext
{
    JSContext *context = [[JSContext alloc] init];
    
    __weak VZMistScriptEngine *weakSelf = self;
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
    
    context[@"releaseTmpObj"] = ^void(JSValue *jsVal) {
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
    
    NSString *engine = @"var global=this;(function(){var _ocCls={};var _jsCls={};var _convertOCtoJS=function(obj){if(obj===undefined||obj===null)return false\nif(typeof obj==\"object\"){if(obj.__obj)return obj\nif(obj.__isNil)return false}\nif(obj instanceof Array){var ret=[]\nobj.forEach(function(o){ret.push(_convertOCtoJS(o))})\nreturn ret}\nif(obj instanceof Function){return function(){var args=Array.prototype.slice.call(arguments)\nvar formatedArgs=_MIST_JSToOC(args)\nfor(var i=0;i<args.length;i++){if(args[i]===null||args[i]===undefined||args[i]===false){formatedArgs.splice(i,1,undefined)}else if(args[i]==nsnull){formatedArgs.splice(i,1,null)}}\nreturn _MIST_OCtoJS(obj.apply(obj,formatedArgs))}}\nif(obj instanceof Object){var ret={}\nfor(var key in obj){ret[key]=_convertOCtoJS(obj[key])}\nreturn ret}\nreturn obj}\nvar _methodFunc=function(instance,clsName,methodName,args,isSuper,isPerformSelector){var selectorName=methodName\nif(!isPerformSelector){methodName=methodName.replace(/__/g,\"-\")\nselectorName=methodName.replace(/_/g,\":\").replace(/-/g,\"_\")\nvar marchArr=selectorName.match(/:/g)\nvar numOfArgs=marchArr?marchArr.length:0\nif(args.length>numOfArgs){selectorName+=\":\"}}\nvar ret=instance?callInstanceMethod(instance,selectorName,args,isSuper):callClassMethod(clsName,selectorName,args)\nreturn _convertOCtoJS(ret)}\nvar _customMethods={__m:function(methodName){var slf=this\nif(slf instanceof Boolean){return function(){return false}}\nif(slf[methodName]){return slf[methodName].bind(slf);}\nif(!slf.__obj&&!slf.__clsName){throw new Error(slf+'.'+methodName+' is undefined')}\nif(slf.__isSuper&&slf.__clsName){slf.__clsName=_MIST_superClsName(slf.__obj.__realClsName?slf.__obj.__realClsName:slf.__clsName);}\nvar clsName=slf.__clsName\nif(clsName&&_ocCls[clsName]){var methodType=slf.__obj?'instMethods':'clsMethods'\nif(_ocCls[clsName][methodType][methodName]){slf.__isSuper=0;return _ocCls[clsName][methodType][methodName].bind(slf)}}\nreturn function(){var args=Array.prototype.slice.call(arguments)\nreturn _methodFunc(slf.__obj,slf.__clsName,methodName,args,slf.__isSuper)}},super:function(){var slf=this\nif(slf.__obj){slf.__obj.__realClsName=slf.__realClsName;}\nreturn{__obj:slf.__obj,__clsName:slf.__clsName,__isSuper:1}},performSelectorInOC:function(){var slf=this\nvar args=Array.prototype.slice.call(arguments)\nreturn{__isPerformInOC:1,obj:slf.__obj,clsName:slf.__clsName,sel:args[0],args:args[1],cb:args[2]}},performSelector:function(){var slf=this\nvar args=Array.prototype.slice.call(arguments)\nreturn _methodFunc(slf.__obj,slf.__clsName,args[0],args.splice(1),slf.__isSuper,true)}}\nfor(var method in _customMethods){if(_customMethods.hasOwnProperty(method)){Object.defineProperty(Object.prototype,method,{value:_customMethods[method],configurable:false,enumerable:false})}}\nvar _require=function(clsName){if(!global[clsName]){global[clsName]={__clsName:clsName}}\nreturn global[clsName]}\nglobal.require=function(){var lastRequire\nfor(var i=0;i<arguments.length;i++){arguments[i].split(',').forEach(function(clsName){lastRequire=_require(clsName.trim())})}\nreturn lastRequire}\nglobal.block=function(args,cb){var that=this\nvar slf=global.self\nif(args instanceof Function){cb=args\nargs=''}\nvar callback=function(){var args=Array.prototype.slice.call(arguments)\nglobal.self=slf\nreturn cb.apply(that,_convertOCtoJS(args))}\nreturn{args:args,cb:callback,__isBlock:1}}\nif(global.console){var jsLogger=console.log;global.console.log=function(){global._MIST_log.apply(global,arguments);if(jsLogger){jsLogger.apply(global.console,arguments);}}}else{global.console={log:global._MIST_log}}\nglobal.export=function(){var args=Array.prototype.slice.call(arguments)\nargs.forEach(function(o){if(o instanceof Function){global[o.name]=o}else if(o instanceof Object){for(var property in o){if(o.hasOwnProperty(property)){global[property]=o[property]}}}})}\nglobal.YES=1\nglobal.NO=0\nglobal.nsnull=_OC_null\nglobal._convertOCtoJS=_convertOCtoJS})()";
    [context evaluateScript:engine];
    
    return context;
}

- (void)handleMemoryWarning
{
    [_MethodSignatureCacheLock lock];
    _MethodSignatureCache = nil;
    [_MethodSignatureCacheLock unlock];
}

static NSString *_regexStr = @"(?<!\\\\)\\.\\s*(\\w+)\\s*\\(";
static NSRegularExpression* _regex;
static NSString *_replaceStr = @".__m(\"$1\")(";

- (JSValue *)execute:(NSString *)script
{
    if (!script || ![JSContext class]) {
        _exceptionBlock(@"script is nil");
        return nil;
    }
    
    if (!_regex) {
        _regex = [NSRegularExpression regularExpressionWithPattern:_regexStr options:0 error:nil];
    }
    NSString *formatedScript = [NSString stringWithFormat:@";(function(){try{\n%@\n}catch(e){_MIST_catch(e.message, e.stack)}})();", [_regex stringByReplacingMatchesInString:script options:0 range:NSMakeRange(0, script.length) withTemplate:_replaceStr]];
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

static id executeMethod(VZMistScriptEngine *engine, NSString *className, NSString *selectorName, JSValue *arguments, JSValue *instance, BOOL isSuper)
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
            Class defineClass = NSClassFromString(realClsName);
            superCls = defineClass ? [defineClass superclass] : [cls superclass];
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
    
    if (superClassName) engine.currentSuperClassName[selectorName] = superClassName;
    [invocation invoke];
    if (superClassName) [engine.currentSuperClassName removeObjectForKey:selectorName];
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
