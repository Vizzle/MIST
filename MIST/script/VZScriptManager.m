//
//  O2OScriptManager.m
//  O2OMist
//
//  Created by lingwan on 16/7/28.
//  Copyright © 2016年 Alipay. All rights reserved.
//

#import "VZScriptManager.h"
#import "VZScriptErrorMsgViewController.h"
//#import <JSPatch/JPEngine.h>

@interface VZScriptManager ()

#ifdef DEBUG
@property (nonatomic, strong) UIWindow *errorWindow;
@property (nonatomic, strong) NSString *errMsg;
#endif

@property (nonatomic, strong) NSMutableSet *executedScriptsName;
@property (nonatomic, copy) VZMistDecryptScript decryptMethod;

@end

@implementation VZScriptManager

+ (instancetype)manager {
    static VZScriptManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VZScriptManager alloc] init];
        manager.executedScriptsName = [NSMutableSet set];
        
#ifdef DEBUG
//        [JPEngine handleException:^(NSString *msg) {
//            manager.errMsg = msg;
//            manager.errorWindow.hidden = NO;
//
//            NSArray *slices = [msg componentsSeparatedByString:@"\n"];
//            for (NSString *slice in slices) {
//                if ([slice containsString:@"msg"]) {
//                    msg = slice;
//                    break;
//                }
//            }
//            
//            if (!manager.errorWindow) {
//                manager.errorWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
//                manager.errorWindow.windowLevel = UIWindowLevelStatusBar + 1.0f;
//                manager.errorWindow.backgroundColor = [UIColor blackColor];
//                UIButton *errBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, [UIScreen mainScreen].bounds.size.width - 10, 20)];
//                errBtn.titleLabel.font = [UIFont systemFontOfSize:10];
//                [errBtn setTitle:msg forState:UIControlStateNormal];
//                [errBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//                errBtn.tag = 100;
//                [errBtn addTarget:manager action:@selector(handleTapErrorBtn) forControlEvents:UIControlEventTouchDown];
//                [manager.errorWindow addSubview:errBtn];
//                manager.errorWindow.hidden = NO;
//            } else {
//                UIButton *errBtn = [manager.errorWindow viewWithTag:100];
//                [errBtn setTitle:msg forState:UIControlStateNormal];
//            }
//        }];
#endif
        
    });
    
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
#ifdef DEBUG
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearLocalScriptCache) name:@"MISTDebugShouldReload" object:nil];
#endif
    }
    
    return self;
}

- (void)registerDecryptMethod:(VZMistDecryptScript)method {
    if (method) {
        self.decryptMethod = method;
    }
}

#ifdef DEBUG
- (void)clearLocalScriptCache {
    [self.executedScriptsName removeAllObjects];
}
#endif

- (void)runScript:(NSString *)script {
    if (![script isKindOfClass:[NSString class]] && script.length) {
        return;
    }
    
    @synchronized (self) {
        BOOL executed = [self.executedScriptsName containsObject:[NSNumber numberWithUnsignedInteger:[script hash]]];
        if (executed) {
            return;
        } else {
            [self.executedScriptsName addObject:[NSNumber numberWithUnsignedInteger:[script hash]]];
        }
    }
    
#ifdef DEBUG
    [VZScriptManager manager].errorWindow.hidden = YES;
#endif
    
    NSString *decryptedScript = nil;

    if (self.decryptMethod) {
        decryptedScript = self.decryptMethod(script);
    } else {
        NSAssert(YES, @"VZScriptManager: 需要设置解密脚本方法: [[VZScriptManager manager] registerDecryptMethod:method]");
    }
    
    if (!decryptedScript || decryptedScript.length == 0) {
        NSAssert(YES, @"VZScriptManager: 解密出的脚本为空");
        return;
    }
    
  //  [JPEngine evaluateScript:decryptedScript];
}

#ifdef DEBUG

- (void)handleTapErrorBtn {
    self.errorWindow.hidden = YES;
    
    VZScriptErrorMsgViewController *errorMsgVC = [[VZScriptErrorMsgViewController alloc] initWithMsg:self.errMsg];
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    UINavigationController *nav = nil;
    
    if ([root isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)root;
    } else {
        nav = root.navigationController;
    }
    
    NSAssert(nav, @"VZScriptManager: 未能获取导航栏");
    
    [nav pushViewController:errorMsgVC animated:YES];
}

#endif

@end
