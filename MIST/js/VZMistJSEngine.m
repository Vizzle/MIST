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
#import <objc/message.h>
#ifdef DEBUG
#import "VZScriptErrorMsgViewController.h"
#endif

@interface JPBoxing : NSObject
@property (nonatomic) id obj;
@property (nonatomic) void *pointer;
@property (nonatomic) Class cls;
@property (nonatomic, weak) id weakObj;
@property (nonatomic, assign) id assignObj;
- (id)unbox;
- (void *)unboxPointer;
- (Class)unboxClass;
@end

@implementation JPBoxing

#define JPBOXING_GEN(_name, _prop, _type) \
+ (instancetype)_name:(_type)obj  \
{   \
JPBoxing *boxing = [[JPBoxing alloc] init]; \
boxing._prop = obj;   \
return boxing;  \
}

JPBOXING_GEN(boxObj, obj, id)
JPBOXING_GEN(boxPointer, pointer, void *)
JPBOXING_GEN(boxClass, cls, Class)
JPBOXING_GEN(boxWeakObj, weakObj, id)
JPBOXING_GEN(boxAssignObj, assignObj, id)

- (id)unbox
{
    if (self.obj) return self.obj;
    if (self.weakObj) return self.weakObj;
    if (self.assignObj) return self.assignObj;
    if (self.cls) return self.cls;
    return self;
}
- (void *)unboxPointer
{
    return self.pointer;
}
- (Class)unboxClass
{
    return self.cls;
}
@end



static JSContext *_context;
static NSString *_regexStr = @"(?<!\\\\)\\.\\s*(\\w+)\\s*\\(";
static NSString *_replaceStr = @".__c(\"$1\")(";
static NSRegularExpression* _regex;
static NSObject *_nullObj;
static NSObject *_nilObj;
static NSMutableDictionary *_currInvokeSuperClsName;
static NSMutableDictionary *_registeredStruct;
static NSMutableDictionary *_TMPMemoryPool;
static NSMutableDictionary *_JSMethodSignatureCache;
static NSLock              *_JSMethodSignatureLock;
static NSRecursiveLock     *_JSMethodForwardCallLock;
static NSMutableArray      *_pointersToRelease;

static void (^_exceptionBlock)(NSString *log) = ^void(NSString *log) {
    //    NSCAssert(NO, log);
};

@implementation VZMistJSEngine

#pragma mark - APIS

+ (void)startEngine
{
    if (![JSContext class] || _context) {
        return;
    }
    
    JSContext *context = [[JSContext alloc] init];
    
    //#ifdef DEBUG
    //    context[@"po"] = ^JSValue*(JSValue *obj) {
    //        id ocObject = formatJSToOC(obj);
    //        return [JSValue valueWithObject:[ocObject description] inContext:_context];
    //    };
    //
    //    context[@"bt"] = ^JSValue*() {
    //        return [JSValue valueWithObject:_JSLastCallStack inContext:_context];
    //    };
    //#endif
    
    context[@"_OC_callI"] = ^id(JSValue *obj, NSString *selectorName, JSValue *arguments, BOOL isSuper) {
        return callSelector(nil, selectorName, arguments, obj, isSuper);
    };
    context[@"_OC_callC"] = ^id(NSString *className, NSString *selectorName, JSValue *arguments) {
        return callSelector(className, selectorName, arguments, nil, NO);
    };
    context[@"_OC_formatJSToOC"] = ^id(JSValue *obj) {
        return formatJSToOC(obj);
    };
    
    context[@"_OC_formatOCToJS"] = ^id(JSValue *obj) {
        return formatOCToJS([obj toObject]);
    };
    
    context[@"__weak"] = ^id(JSValue *jsval) {
        id obj = formatJSToOC(jsval);
        return [[JSContext currentContext][@"_formatOCToJS"] callWithArguments:@[formatOCToJS([JPBoxing boxWeakObj:obj])]];
    };
    
    context[@"__strong"] = ^id(JSValue *jsval) {
        id obj = formatJSToOC(jsval);
        return [[JSContext currentContext][@"_formatOCToJS"] callWithArguments:@[formatOCToJS(obj)]];
    };
    
    context[@"_OC_superClsName"] = ^(NSString *clsName) {
        Class cls = NSClassFromString(clsName);
        return NSStringFromClass([cls superclass]);
    };
    
    //    context[@"autoConvertOCType"] = ^(BOOL autoConvert) {
    //        _autoConvert = autoConvert;
    //    };
    //
    //    context[@"convertOCNumberToString"] = ^(BOOL convertOCNumberToString) {
    //        _convertOCNumberToString = convertOCNumberToString;
    //    };
    
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
            void *pointer =  [(JPBoxing *)([jsVal toObject][@"__obj"]) unboxPointer];
            id obj = *((__unsafe_unretained id *)pointer);
            @synchronized(_TMPMemoryPool) {
                [_TMPMemoryPool removeObjectForKey:[NSNumber numberWithInteger:[(NSObject*)obj hash]]];
            }
        }
    };
    
    context[@"_OC_log"] = ^() {
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            id obj = formatJSToOC(jsVal);
            NSLog(@"MISTJSEngine.log: %@", obj == _nilObj ? nil : (obj == _nullObj ? [NSNull null]: obj));
        }
    };
    
    context[@"_OC_catch"] = ^(JSValue *msg, JSValue *stack) {
        _exceptionBlock([NSString stringWithFormat:@"js exception, \nmsg: %@, \nstack: \n %@", [msg toObject], [stack toObject]]);
    };
    
    context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
        NSLog(@"%@", exception);
        _exceptionBlock([NSString stringWithFormat:@"js exception: %@", exception]);
    };
    
#ifdef DEBUG
    context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorMessage = exception.description;
            
            if (!errorWindow) {
                errorWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
                errorWindow.windowLevel = UIWindowLevelStatusBar + 1.0f;
                errorWindow.backgroundColor = [UIColor colorWithRed:224/255.0 green:72/255.0 blue:32/255.0 alpha:1];
                
                UIButton *errBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, [UIScreen mainScreen].bounds.size.width - 30, 20)];
                errBtn.titleLabel.font = [UIFont systemFontOfSize:10];
                [errBtn setTitle:errorMessage forState:UIControlStateNormal];
                [errBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                errBtn.tag = 100;
                [errBtn addTarget:self action:@selector(tapJsErrorView) forControlEvents:UIControlEventTouchDown];
                [errorWindow addSubview:errBtn];
                
                UIButton *close = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 18, 0, 16, 16)];
                close.titleLabel.font = [UIFont systemFontOfSize:16];
                [close setTitle:@"×" forState:UIControlStateNormal];
                [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchDown];
                [errorWindow addSubview:close];
            } else {
                UIButton *errBtn = [errorWindow viewWithTag:100];
                [errBtn setTitle:errorMessage forState:UIControlStateNormal];
            }
            
            errorWindow.hidden = NO;
        });
    };
#endif
    
    _nullObj = [[NSObject alloc] init];
    context[@"_OC_null"] = formatOCToJS(_nullObj);
    
    _context = context;
    
    _nilObj = [[NSObject alloc] init];
    _JSMethodSignatureLock = [[NSLock alloc] init];
    _JSMethodForwardCallLock = [[NSRecursiveLock alloc] init];
    _registeredStruct = [[NSMutableDictionary alloc] init];
    _currInvokeSuperClsName = [[NSMutableDictionary alloc] init];
    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    
    NSString *jsCore = @"var global=this;(function(){var _ocCls={};var _jsCls={};var _formatOCToJS=function(obj){if(obj===undefined||obj===null)return false\nif(typeof obj==\"object\"){if(obj.__obj)return obj\nif(obj.__isNil)return false}\nif(obj instanceof Array){var ret=[]\nobj.forEach(function(o){ret.push(_formatOCToJS(o))})\nreturn ret}\nif(obj instanceof Function){return function(){var args=Array.prototype.slice.call(arguments)\nvar formatedArgs=_OC_formatJSToOC(args)\nfor(var i=0;i<args.length;i++){if(args[i]===null||args[i]===undefined||args[i]===false){formatedArgs.splice(i,1,undefined)}else if(args[i]==nsnull){formatedArgs.splice(i,1,null)}}\nreturn _OC_formatOCToJS(obj.apply(obj,formatedArgs))}}\nif(obj instanceof Object){var ret={}\nfor(var key in obj){ret[key]=_formatOCToJS(obj[key])}\nreturn ret}\nreturn obj}\nvar _methodFunc=function(instance,clsName,methodName,args,isSuper,isPerformSelector){var selectorName=methodName\nif(!isPerformSelector){methodName=methodName.replace(/__/g,\"-\")\nselectorName=methodName.replace(/_/g,\":\").replace(/-/g,\"_\")\nvar marchArr=selectorName.match(/:/g)\nvar numOfArgs=marchArr?marchArr.length:0\nif(args.length>numOfArgs){selectorName+=\":\"}}\nvar ret=instance?_OC_callI(instance,selectorName,args,isSuper):_OC_callC(clsName,selectorName,args)\nreturn _formatOCToJS(ret)}\nvar _customMethods={__c:function(methodName){var slf=this\nif(slf instanceof Boolean){return function(){return false}}\nif(slf[methodName]){return slf[methodName].bind(slf);}\nif(!slf.__obj&&!slf.__clsName){throw new Error(slf+'.'+methodName+' is undefined')}\nif(slf.__isSuper&&slf.__clsName){slf.__clsName=_OC_superClsName(slf.__obj.__realClsName?slf.__obj.__realClsName:slf.__clsName);}\nvar clsName=slf.__clsName\nif(clsName&&_ocCls[clsName]){var methodType=slf.__obj?'instMethods':'clsMethods'\nif(_ocCls[clsName][methodType][methodName]){slf.__isSuper=0;return _ocCls[clsName][methodType][methodName].bind(slf)}}\nreturn function(){var args=Array.prototype.slice.call(arguments)\nreturn _methodFunc(slf.__obj,slf.__clsName,methodName,args,slf.__isSuper)}},super:function(){var slf=this\nif(slf.__obj){slf.__obj.__realClsName=slf.__realClsName;}\nreturn{__obj:slf.__obj,__clsName:slf.__clsName,__isSuper:1}},performSelectorInOC:function(){var slf=this\nvar args=Array.prototype.slice.call(arguments)\nreturn{__isPerformInOC:1,obj:slf.__obj,clsName:slf.__clsName,sel:args[0],args:args[1],cb:args[2]}},performSelector:function(){var slf=this\nvar args=Array.prototype.slice.call(arguments)\nreturn _methodFunc(slf.__obj,slf.__clsName,args[0],args.splice(1),slf.__isSuper,true)}}\nfor(var method in _customMethods){if(_customMethods.hasOwnProperty(method)){Object.defineProperty(Object.prototype,method,{value:_customMethods[method],configurable:false,enumerable:false})}}\nvar _require=function(clsName){if(!global[clsName]){global[clsName]={__clsName:clsName}}\nreturn global[clsName]}\nglobal.require=function(){var lastRequire\nfor(var i=0;i<arguments.length;i++){arguments[i].split(',').forEach(function(clsName){lastRequire=_require(clsName.trim())})}\nreturn lastRequire}\nglobal.block=function(args,cb){var that=this\nvar slf=global.self\nif(args instanceof Function){cb=args\nargs=''}\nvar callback=function(){var args=Array.prototype.slice.call(arguments)\nglobal.self=slf\nreturn cb.apply(that,_formatOCToJS(args))}\nreturn{args:args,cb:callback,__isBlock:1}}\nif(global.console){var jsLogger=console.log;global.console.log=function(){global._OC_log.apply(global,arguments);if(jsLogger){jsLogger.apply(global.console,arguments);}}}else{global.console={log:global._OC_log}}\nglobal.export=function(){var args=Array.prototype.slice.call(arguments)\nargs.forEach(function(o){if(o instanceof Function){global[o.name]=o}else if(o instanceof Object){for(var property in o){if(o.hasOwnProperty(property)){global[property]=o[property]}}}})}\nglobal.YES=1\nglobal.NO=0\nglobal.nsnull=_OC_null\nglobal._formatOCToJS=_formatOCToJS})()";
    
    [_context evaluateScript:jsCore withSourceURL:[NSURL URLWithString:@"mist.js"]];
}


#ifdef DEBUG

static UIWindow *errorWindow = nil;
static NSString *errorMessage = nil;

+ (void)tapJsErrorView
{
    errorWindow.hidden = YES;
    
    VZScriptErrorMsgViewController *errorMsgVC = [[VZScriptErrorMsgViewController alloc] initWithMsg:errorMessage];
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    UINavigationController *nav = nil;
    
    if ([root isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)root;
    } else {
        nav = root.navigationController;
    }
    
    NSAssert(nav, @"VZMistJSContextBuilder: 未能获取导航栏");
    
    [nav pushViewController:errorMsgVC animated:YES];
}

+ (void)close {
    errorWindow.hidden = YES;
}

#endif

+ (JSValue *)evaluateScript:(NSString *)script
{
    if (!script || ![JSContext class]) {
        _exceptionBlock(@"script is nil");
        return nil;
    }
    [self startEngine];
    
    if (!_regex) {
        _regex = [NSRegularExpression regularExpressionWithPattern:_regexStr options:0 error:nil];
    }
    NSString *formatedScript = [NSString stringWithFormat:@";(function(){try{\n%@\n}catch(e){_OC_catch(e.message, e.stack)}})();", [_regex stringByReplacingMatchesInString:script options:0 range:NSMakeRange(0, script.length) withTemplate:_replaceStr]];
    @try {
        if ([_context respondsToSelector:@selector(evaluateScript:withSourceURL:)]) {
            return [_context evaluateScript:formatedScript withSourceURL:[NSURL URLWithString:@"main.js"]];
        } else {
            return [_context evaluateScript:formatedScript];
        }
    }
    @catch (NSException *exception) {
        _exceptionBlock([NSString stringWithFormat:@"%@", exception]);
    }
    return nil;
}

+ (JSContext *)context
{
    return _context;
}

+ (void)handleMemoryWarning
{
    [_JSMethodSignatureLock lock];
    _JSMethodSignatureCache = nil;
    [_JSMethodSignatureLock unlock];
}

#pragma mark -

static id callSelector(NSString *className, NSString *selectorName, JSValue *arguments, JSValue *instance, BOOL isSuper)
{
    NSString *realClsName = [[instance valueForProperty:@"__realClsName"] toString];
    
    if (instance) {
        instance = formatJSToOC(instance);
        if (class_isMetaClass(object_getClass(instance))) {
            className = NSStringFromClass((Class)instance);
            instance = nil;
        } else if (!instance || instance == _nilObj || [instance isKindOfClass:[JPBoxing class]]) {
            return @{@"__isNil": @(YES)};
        }
    }
    id argumentsObj = formatJSToOC(arguments);
    
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
        
        //lingwan
        //        NSString *JPSelectorName = [NSString stringWithFormat:@"_JP%@", selectorName];
        //        JSValue *overideFunction = _JSOverideMethods[superCls][JPSelectorName];
        //        if (overideFunction) {
        //            overrideMethod(cls, superSelectorName, overideFunction, NO, NULL);
        //        }
        
        selector = superSelector;
        superClassName = NSStringFromClass(superCls);
    }
    
    
    NSMutableArray *_markArray;
    
    NSInvocation *invocation;
    NSMethodSignature *methodSignature;
    if (!_JSMethodSignatureCache) {
        _JSMethodSignatureCache = [[NSMutableDictionary alloc]init];
    }
    if (instance) {
        [_JSMethodSignatureLock lock];
        if (!_JSMethodSignatureCache[cls]) {
            _JSMethodSignatureCache[(id<NSCopying>)cls] = [[NSMutableDictionary alloc]init];
        }
        methodSignature = _JSMethodSignatureCache[cls][selectorName];
        if (!methodSignature) {
            methodSignature = [cls instanceMethodSignatureForSelector:selector];
            
            //lingwan
            //            methodSignature = fixSignature(methodSignature);
            _JSMethodSignatureCache[cls][selectorName] = methodSignature;
        }
        [_JSMethodSignatureLock unlock];
        if (!methodSignature) {
            _exceptionBlock([NSString stringWithFormat:@"unrecognized selector %@ for instance %@", selectorName, instance]);
            return nil;
        }
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:instance];
    } else {
        methodSignature = [cls methodSignatureForSelector:selector];
        //lingwan
        //        methodSignature = fixSignature(methodSignature);
        if (!methodSignature) {
            _exceptionBlock([NSString stringWithFormat:@"unrecognized selector %@ for class %@", selectorName, className]);
            return nil;
        }
        invocation= [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:cls];
    }
    [invocation setSelector:selector];
    
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    NSInteger inputArguments = [(NSArray *)argumentsObj count];
    if (inputArguments > numberOfArguments - 2) {
        // calling variable argument method, only support parameter type `id` and return type `id`
        id sender = instance != nil ? instance : cls;
        id result = invokeVariableParameterMethod(argumentsObj, methodSignature, sender, selector);
        return formatOCToJS(result);
    }
    
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
                
                JP_CALL_ARG_CASE('c', char, charValue)
                JP_CALL_ARG_CASE('C', unsigned char, unsignedCharValue)
                JP_CALL_ARG_CASE('s', short, shortValue)
                JP_CALL_ARG_CASE('S', unsigned short, unsignedShortValue)
                JP_CALL_ARG_CASE('i', int, intValue)
                JP_CALL_ARG_CASE('I', unsigned int, unsignedIntValue)
                JP_CALL_ARG_CASE('l', long, longValue)
                JP_CALL_ARG_CASE('L', unsigned long, unsignedLongValue)
                JP_CALL_ARG_CASE('q', long long, longLongValue)
                JP_CALL_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
                JP_CALL_ARG_CASE('f', float, floatValue)
                JP_CALL_ARG_CASE('d', double, doubleValue)
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
                JP_CALL_ARG_STRUCT(CGRect, toRect)
                JP_CALL_ARG_STRUCT(CGPoint, toPoint)
                JP_CALL_ARG_STRUCT(CGSize, toSize)
                JP_CALL_ARG_STRUCT(NSRange, toRange)
                @synchronized (_context) {
                    NSDictionary *structDefine = _registeredStruct[typeString];
                    if (structDefine) {
                        size_t size = sizeOfStructTypes(structDefine[@"types"]);
                        void *ret = malloc(size);
                        getStructDataWithDict(ret, valObj, structDefine);
                        [invocation setArgument:ret atIndex:i];
                        free(ret);
                        break;
                    }
                }
                
                break;
            }
            case '*':
            case '^': {
                if ([valObj isKindOfClass:[JPBoxing class]]) {
                    void *value = [((JPBoxing *)valObj) unboxPointer];
                    
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
            case '#': {
                if ([valObj isKindOfClass:[JPBoxing class]]) {
                    Class value = [((JPBoxing *)valObj) unboxClass];
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
                    __autoreleasing id cb = genCallbackBlock(arguments[i-2]);
                    [invocation setArgument:&cb atIndex:i];
                } else {
                    [invocation setArgument:&valObj atIndex:i];
                }
            }
        }
    }
    
    if (superClassName) _currInvokeSuperClsName[selectorName] = superClassName;
    [invocation invoke];
    if (superClassName) [_currInvokeSuperClsName removeObjectForKey:selectorName];
    if ([_markArray count] > 0) {
        for (JPBoxing *box in _markArray) {
            void *pointer = [box unboxPointer];
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
    
    //lingwan
    //    // Restore the return type
    //    if (strcmp(returnType, @encode(JPDouble)) == 0) {
    //        strcpy(returnType, @encode(double));
    //    }
    //    if (strcmp(returnType, @encode(JPFloat)) == 0) {
    //        strcpy(returnType, @encode(float));
    //    }
    
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
            return formatOCToJS(returnValue);
            
        } else {
            switch (returnType[0] == 'r' ? returnType[1] : returnType[0]) {
                    
#define JP_CALL_RET_CASE(_typeString, _type) \
case _typeString: {                              \
_type tempResultSet; \
[invocation getReturnValue:&tempResultSet];\
returnValue = @(tempResultSet); \
break; \
}
                    
                    JP_CALL_RET_CASE('c', char)
                    JP_CALL_RET_CASE('C', unsigned char)
                    JP_CALL_RET_CASE('s', short)
                    JP_CALL_RET_CASE('S', unsigned short)
                    JP_CALL_RET_CASE('i', int)
                    JP_CALL_RET_CASE('I', unsigned int)
                    JP_CALL_RET_CASE('l', long)
                    JP_CALL_RET_CASE('L', unsigned long)
                    JP_CALL_RET_CASE('q', long long)
                    JP_CALL_RET_CASE('Q', unsigned long long)
                    JP_CALL_RET_CASE('f', float)
                    JP_CALL_RET_CASE('d', double)
                    JP_CALL_RET_CASE('B', BOOL)
                    
                case '{': {
                    NSString *typeString = extractStructName([NSString stringWithUTF8String:returnType]);
#define JP_CALL_RET_STRUCT(_type, _methodName) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type result;   \
[invocation getReturnValue:&result];    \
return [JSValue _methodName:result inContext:_context];    \
}
                    JP_CALL_RET_STRUCT(CGRect, valueWithRect)
                    JP_CALL_RET_STRUCT(CGPoint, valueWithPoint)
                    JP_CALL_RET_STRUCT(CGSize, valueWithSize)
                    JP_CALL_RET_STRUCT(NSRange, valueWithRange)
                    @synchronized (_context) {
                        NSDictionary *structDefine = _registeredStruct[typeString];
                        if (structDefine) {
                            size_t size = sizeOfStructTypes(structDefine[@"types"]);
                            void *ret = malloc(size);
                            [invocation getReturnValue:ret];
                            NSDictionary *dict = getDictOfStruct(ret, structDefine);
                            free(ret);
                            return dict;
                        }
                    }
                    break;
                }
                case '*':
                case '^': {
                    void *result;
                    [invocation getReturnValue:&result];
                    returnValue = formatOCToJS([JPBoxing boxPointer:result]);
                    if (strncmp(returnType, "^{CG", 4) == 0) {
                        if (!_pointersToRelease) {
                            _pointersToRelease = [[NSMutableArray alloc] init];
                        }
                        [_pointersToRelease addObject:[NSValue valueWithPointer:result]];
                        CFRetain(result);
                    }
                    break;
                }
                case '#': {
                    Class result;
                    [invocation getReturnValue:&result];
                    returnValue = formatOCToJS([JPBoxing boxClass:result]);
                    break;
                }
            }
            return returnValue;
        }
    }
    return nil;
}


static id (*new_msgSend1)(id, SEL, id,...) = (id (*)(id, SEL, id,...)) objc_msgSend;
static id (*new_msgSend2)(id, SEL, id, id,...) = (id (*)(id, SEL, id, id,...)) objc_msgSend;
static id (*new_msgSend3)(id, SEL, id, id, id,...) = (id (*)(id, SEL, id, id, id,...)) objc_msgSend;
static id (*new_msgSend4)(id, SEL, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id,...)) objc_msgSend;
static id (*new_msgSend5)(id, SEL, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id,...)) objc_msgSend;
static id (*new_msgSend6)(id, SEL, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id,...)) objc_msgSend;
static id (*new_msgSend7)(id, SEL, id, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id,id,...)) objc_msgSend;
static id (*new_msgSend8)(id, SEL, id, id, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id, id, id,...)) objc_msgSend;
static id (*new_msgSend9)(id, SEL, id, id, id, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id, id, id, id, ...)) objc_msgSend;
static id (*new_msgSend10)(id, SEL, id, id, id, id, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id, id, id, id, id,...)) objc_msgSend;

static id invokeVariableParameterMethod(NSMutableArray *origArgumentsList, NSMethodSignature *methodSignature, id sender, SEL selector) {
    
    NSInteger inputArguments = [(NSArray *)origArgumentsList count];
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    
    NSMutableArray *argumentsList = [[NSMutableArray alloc] init];
    for (NSUInteger j = 0; j < inputArguments; j++) {
        NSInteger index = MIN(j + 2, numberOfArguments - 1);
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:index];
        id valObj = origArgumentsList[j];
        char argumentTypeChar = argumentType[0] == 'r' ? argumentType[1] : argumentType[0];
        if (argumentTypeChar == '@') {
            [argumentsList addObject:valObj];
        } else {
            return nil;
        }
    }
    
    id results = nil;
    numberOfArguments = numberOfArguments - 2;
    
    //If you want to debug the macro code below, replace it to the expanded code:
    //https://gist.github.com/bang590/ca3720ae1da594252a2e
#define JP_G_ARG(_idx) getArgument(argumentsList[_idx])
#define JP_CALL_MSGSEND_ARG1(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0));
#define JP_CALL_MSGSEND_ARG2(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1));
#define JP_CALL_MSGSEND_ARG3(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2));
#define JP_CALL_MSGSEND_ARG4(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3));
#define JP_CALL_MSGSEND_ARG5(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4));
#define JP_CALL_MSGSEND_ARG6(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5));
#define JP_CALL_MSGSEND_ARG7(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6));
#define JP_CALL_MSGSEND_ARG8(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6), JP_G_ARG(7));
#define JP_CALL_MSGSEND_ARG9(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6), JP_G_ARG(7), JP_G_ARG(8));
#define JP_CALL_MSGSEND_ARG10(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6), JP_G_ARG(7), JP_G_ARG(8), JP_G_ARG(9));
#define JP_CALL_MSGSEND_ARG11(_num) results = new_msgSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6), JP_G_ARG(7), JP_G_ARG(8), JP_G_ARG(9), JP_G_ARG(10));
    
#define JP_IF_REAL_ARG_COUNT(_num) if([argumentsList count] == _num)
    
#define JP_DEAL_MSGSEND(_realArgCount, _defineArgCount) \
if(numberOfArguments == _defineArgCount) { \
JP_CALL_MSGSEND_ARG##_realArgCount(_defineArgCount) \
}
    
    JP_IF_REAL_ARG_COUNT(1) { JP_CALL_MSGSEND_ARG1(1) }
    JP_IF_REAL_ARG_COUNT(2) { JP_DEAL_MSGSEND(2, 1) JP_DEAL_MSGSEND(2, 2) }
    JP_IF_REAL_ARG_COUNT(3) { JP_DEAL_MSGSEND(3, 1) JP_DEAL_MSGSEND(3, 2) JP_DEAL_MSGSEND(3, 3) }
    JP_IF_REAL_ARG_COUNT(4) { JP_DEAL_MSGSEND(4, 1) JP_DEAL_MSGSEND(4, 2) JP_DEAL_MSGSEND(4, 3) JP_DEAL_MSGSEND(4, 4) }
    JP_IF_REAL_ARG_COUNT(5) { JP_DEAL_MSGSEND(5, 1) JP_DEAL_MSGSEND(5, 2) JP_DEAL_MSGSEND(5, 3) JP_DEAL_MSGSEND(5, 4) JP_DEAL_MSGSEND(5, 5) }
    JP_IF_REAL_ARG_COUNT(6) { JP_DEAL_MSGSEND(6, 1) JP_DEAL_MSGSEND(6, 2) JP_DEAL_MSGSEND(6, 3) JP_DEAL_MSGSEND(6, 4) JP_DEAL_MSGSEND(6, 5) JP_DEAL_MSGSEND(6, 6) }
    JP_IF_REAL_ARG_COUNT(7) { JP_DEAL_MSGSEND(7, 1) JP_DEAL_MSGSEND(7, 2) JP_DEAL_MSGSEND(7, 3) JP_DEAL_MSGSEND(7, 4) JP_DEAL_MSGSEND(7, 5) JP_DEAL_MSGSEND(7, 6) JP_DEAL_MSGSEND(7, 7) }
    JP_IF_REAL_ARG_COUNT(8) { JP_DEAL_MSGSEND(8, 1) JP_DEAL_MSGSEND(8, 2) JP_DEAL_MSGSEND(8, 3) JP_DEAL_MSGSEND(8, 4) JP_DEAL_MSGSEND(8, 5) JP_DEAL_MSGSEND(8, 6) JP_DEAL_MSGSEND(8, 7) JP_DEAL_MSGSEND(8, 8) }
    JP_IF_REAL_ARG_COUNT(9) { JP_DEAL_MSGSEND(9, 1) JP_DEAL_MSGSEND(9, 2) JP_DEAL_MSGSEND(9, 3) JP_DEAL_MSGSEND(9, 4) JP_DEAL_MSGSEND(9, 5) JP_DEAL_MSGSEND(9, 6) JP_DEAL_MSGSEND(9, 7) JP_DEAL_MSGSEND(9, 8) JP_DEAL_MSGSEND(9, 9) }
    JP_IF_REAL_ARG_COUNT(10) { JP_DEAL_MSGSEND(10, 1) JP_DEAL_MSGSEND(10, 2) JP_DEAL_MSGSEND(10, 3) JP_DEAL_MSGSEND(10, 4) JP_DEAL_MSGSEND(10, 5) JP_DEAL_MSGSEND(10, 6) JP_DEAL_MSGSEND(10, 7) JP_DEAL_MSGSEND(10, 8) JP_DEAL_MSGSEND(10, 9) JP_DEAL_MSGSEND(10, 10) }
    
    return results;
}

static id getArgument(id valObj){
    if (valObj == _nilObj ||
        ([valObj isKindOfClass:[NSNumber class]] && strcmp([valObj objCType], "c") == 0 && ![valObj boolValue])) {
        return nil;
    }
    return valObj;
}

#pragma mark -

static id genCallbackBlock(JSValue *jsVal)
{
#define BLK_TRAITS_ARG(_idx, _paramName) \
if (_idx < argTypes.count) { \
NSString *argType = trim(argTypes[_idx]); \
if (blockTypeIsScalarPointer(argType)) { \
[list addObject:formatOCToJS([JPBoxing boxPointer:_paramName])]; \
} else if (blockTypeIsObject(trim(argTypes[_idx]))) {  \
[list addObject:formatOCToJS((__bridge id)_paramName)]; \
} else {  \
[list addObject:formatOCToJS([NSNumber numberWithLongLong:(long long)_paramName])]; \
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
        return formatJSToOC(ret);
    };
    
    return cb;
}

#pragma mark - Struct

static int sizeOfStructTypes(NSString *structTypes)
{
    const char *types = [structTypes cStringUsingEncoding:NSUTF8StringEncoding];
    int index = 0;
    int size = 0;
    while (types[index]) {
        switch (types[index]) {
#define JP_STRUCT_SIZE_CASE(_typeChar, _type)   \
case _typeChar: \
size += sizeof(_type);  \
break;
                
                JP_STRUCT_SIZE_CASE('c', char)
                JP_STRUCT_SIZE_CASE('C', unsigned char)
                JP_STRUCT_SIZE_CASE('s', short)
                JP_STRUCT_SIZE_CASE('S', unsigned short)
                JP_STRUCT_SIZE_CASE('i', int)
                JP_STRUCT_SIZE_CASE('I', unsigned int)
                JP_STRUCT_SIZE_CASE('l', long)
                JP_STRUCT_SIZE_CASE('L', unsigned long)
                JP_STRUCT_SIZE_CASE('q', long long)
                JP_STRUCT_SIZE_CASE('Q', unsigned long long)
                JP_STRUCT_SIZE_CASE('f', float)
                JP_STRUCT_SIZE_CASE('F', CGFloat)
                JP_STRUCT_SIZE_CASE('N', NSInteger)
                JP_STRUCT_SIZE_CASE('U', NSUInteger)
                JP_STRUCT_SIZE_CASE('d', double)
                JP_STRUCT_SIZE_CASE('B', BOOL)
                JP_STRUCT_SIZE_CASE('*', void *)
                JP_STRUCT_SIZE_CASE('^', void *)
                
            default:
                break;
        }
        index ++;
    }
    return size;
}

static void getStructDataWithDict(void *structData, NSDictionary *dict, NSDictionary *structDefine)
{
    NSArray *itemKeys = structDefine[@"keys"];
    const char *structTypes = [structDefine[@"types"] cStringUsingEncoding:NSUTF8StringEncoding];
    int position = 0;
    for (int i = 0; i < itemKeys.count; i ++) {
        switch(structTypes[i]) {
#define JP_STRUCT_DATA_CASE(_typeStr, _type, _transMethod) \
case _typeStr: { \
int size = sizeof(_type);    \
_type val = [dict[itemKeys[i]] _transMethod];   \
memcpy(structData + position, &val, size);  \
position += size;    \
break;  \
}
                
                JP_STRUCT_DATA_CASE('c', char, charValue)
                JP_STRUCT_DATA_CASE('C', unsigned char, unsignedCharValue)
                JP_STRUCT_DATA_CASE('s', short, shortValue)
                JP_STRUCT_DATA_CASE('S', unsigned short, unsignedShortValue)
                JP_STRUCT_DATA_CASE('i', int, intValue)
                JP_STRUCT_DATA_CASE('I', unsigned int, unsignedIntValue)
                JP_STRUCT_DATA_CASE('l', long, longValue)
                JP_STRUCT_DATA_CASE('L', unsigned long, unsignedLongValue)
                JP_STRUCT_DATA_CASE('q', long long, longLongValue)
                JP_STRUCT_DATA_CASE('Q', unsigned long long, unsignedLongLongValue)
                JP_STRUCT_DATA_CASE('f', float, floatValue)
                JP_STRUCT_DATA_CASE('d', double, doubleValue)
                JP_STRUCT_DATA_CASE('B', BOOL, boolValue)
                JP_STRUCT_DATA_CASE('N', NSInteger, integerValue)
                JP_STRUCT_DATA_CASE('U', NSUInteger, unsignedIntegerValue)
                
            case 'F': {
                int size = sizeof(CGFloat);
                CGFloat val;
#if CGFLOAT_IS_DOUBLE
                val = [dict[itemKeys[i]] doubleValue];
#else
                val = [dict[itemKeys[i]] floatValue];
#endif
                memcpy(structData + position, &val, size);
                position += size;
                break;
            }
                
            case '*':
            case '^': {
                int size = sizeof(void *);
                void *val = [(JPBoxing *)dict[itemKeys[i]] unboxPointer];
                memcpy(structData + position, &val, size);
                break;
            }
                
        }
    }
}

static NSDictionary *getDictOfStruct(void *structData, NSDictionary *structDefine)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSArray *itemKeys = structDefine[@"keys"];
    const char *structTypes = [structDefine[@"types"] cStringUsingEncoding:NSUTF8StringEncoding];
    int position = 0;
    
    for (int i = 0; i < itemKeys.count; i ++) {
        switch(structTypes[i]) {
#define JP_STRUCT_DICT_CASE(_typeName, _type)   \
case _typeName: { \
size_t size = sizeof(_type); \
_type *val = malloc(size);   \
memcpy(val, structData + position, size);   \
[dict setObject:@(*val) forKey:itemKeys[i]];    \
free(val);  \
position += size;   \
break;  \
}
                JP_STRUCT_DICT_CASE('c', char)
                JP_STRUCT_DICT_CASE('C', unsigned char)
                JP_STRUCT_DICT_CASE('s', short)
                JP_STRUCT_DICT_CASE('S', unsigned short)
                JP_STRUCT_DICT_CASE('i', int)
                JP_STRUCT_DICT_CASE('I', unsigned int)
                JP_STRUCT_DICT_CASE('l', long)
                JP_STRUCT_DICT_CASE('L', unsigned long)
                JP_STRUCT_DICT_CASE('q', long long)
                JP_STRUCT_DICT_CASE('Q', unsigned long long)
                JP_STRUCT_DICT_CASE('f', float)
                JP_STRUCT_DICT_CASE('F', CGFloat)
                JP_STRUCT_DICT_CASE('N', NSInteger)
                JP_STRUCT_DICT_CASE('U', NSUInteger)
                JP_STRUCT_DICT_CASE('d', double)
                JP_STRUCT_DICT_CASE('B', BOOL)
                
            case '*':
            case '^': {
                size_t size = sizeof(void *);
                void *val = malloc(size);
                memcpy(val, structData + position, size);
                [dict setObject:[JPBoxing boxPointer:val] forKey:itemKeys[i]];
                position += size;
                break;
            }
                
        }
    }
    return dict;
}

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

//static NSString *convertJPSelectorString(NSString *selectorString)
//{
//    NSString *tmpJSMethodName = [selectorString stringByReplacingOccurrencesOfString:@"__" withString:@"-"];
//    NSString *selectorName = [tmpJSMethodName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
//    return [selectorName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
//}

#pragma mark - Object format

static NSDictionary *_wrapObj(id obj)
{
    if (!obj || obj == _nilObj) {
        return @{@"__isNil": @(YES)};
    }
    return @{@"__obj": obj, @"__clsName": NSStringFromClass([obj isKindOfClass:[JPBoxing class]] ? [[((JPBoxing *)obj) unbox] class]: [obj class])};
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

id formatOCToJS(id obj)
{
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDate class]]) {
        //        return _autoConvert ? obj: _wrapObj([JPBoxing boxObj:obj]);
        return _wrapObj([JPBoxing boxObj:obj]);
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return obj;
        //        return _convertOCNumberToString ? [(NSNumber*)obj stringValue] : obj;
    }
    if ([obj isKindOfClass:NSClassFromString(@"NSBlock")] || [obj isKindOfClass:[JSValue class]]) {
        return obj;
    }
    return _wrapObj(obj);
}

id formatJSToOC(JSValue *jsval)
{
    id obj = [jsval toObject];
    if (!obj || [obj isKindOfClass:[NSNull class]]) return _nilObj;
    
    if ([obj isKindOfClass:[JPBoxing class]]) return [obj unbox];
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:formatJSToOC(jsval[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        if (obj[@"__obj"]) {
            id ocObj = [obj objectForKey:@"__obj"];
            if ([ocObj isKindOfClass:[JPBoxing class]]) return [ocObj unbox];
            return ocObj;
        }
        if (obj[@"__isBlock"]) {
            return genCallbackBlock(jsval);
        }
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:formatJSToOC(jsval[key]) forKey:key];
        }
        return newDict;
    }
    return obj;
}

NSArray* formatOCParamsToJS(NSArray *arr) {
    NSCAssert(arr.count, @"VZMistJSEngine: nil params array passed in");
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:arr.count];
    for (id item in arr) {
        [ret addObject:formatOCToJS(item)];
    }
    return ret;
}
