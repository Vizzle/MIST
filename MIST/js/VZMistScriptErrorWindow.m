//
//  VZMistScriptErrorWindow.m
//  MIST
//
//  Created by lingwan on 2017/7/10.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#ifdef DEBUG

#import "VZMistScriptErrorWindow.h"
#import "VZScriptErrorMsgViewController.h"

@implementation VZMistScriptErrorWindow

static UIWindow *errorWindow = nil;
static NSString *errorMessage = nil;

+ (void)showWithErrorInfo:(NSString *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        errorMessage = info;

        NSString *tip = info;
        NSArray *slices = [info componentsSeparatedByString:@"\n"];
        for (NSString *s in slices) {
            if ([s containsString:@"msg"]) {
                tip = [s substringFromIndex:4];
                break;
            }
        }
        
        if (!errorWindow) {
            errorWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
            errorWindow.windowLevel = UIWindowLevelStatusBar + 1.0f;
            errorWindow.backgroundColor = [UIColor colorWithRed:224/255.0 green:72/255.0 blue:32/255.0 alpha:1];
            
            UIButton *errBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, [UIScreen mainScreen].bounds.size.width - 30, 20)];
            errBtn.titleLabel.font = [UIFont systemFontOfSize:10];
            [errBtn setTitle:tip forState:UIControlStateNormal];
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
            [errBtn setTitle:tip forState:UIControlStateNormal];
        }
        
        errorWindow.hidden = NO;
    });
}

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
    
    NSAssert(nav, @"VZMistJSContextBuilder: Cannot find a UINavigationController");
    
    [nav pushViewController:errorMsgVC animated:YES];
}

+ (void)close {
    errorWindow.hidden = YES;
}

@end

#endif
