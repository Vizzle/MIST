//
//  AppDelegate.m
//  MIST
//
//  Created by moxin on 2016/12/5.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "AppDelegate.h"
#import "VZMist.h"
#import "MistDemoIndexViewController.h"
#import "WBTimelineListViewController.h"
#import "MistSimpleTemplateViewController.h"
#import "MistTextViewDemoViewController.h"
#import "MistTextFieldDemoViewController.h"
#import "MistCustomNodeDemoViewController.h"
#import "MistJSHttpRequestHelper.h"
#import "MistJSToast.h"

#ifdef DEBUG
#import <MISTDebug/MSTDebugger.h>
#endif

#import <MIST/VZMistJSEngine.h>

@interface AppDelegate ()

@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UINavigationController *navController;

@end


@implementation AppDelegate

- (std::vector<MistDemoItem>)demos
{
#define MIST_SINGLE_NODE_ITEM(NAME, SUBTITLE)                                            \
{                                                                                    \
.title = NAME,                                                                   \
.subtitle = SUBTITLE,                                                            \
.block = ^{                                                                      \
return [[MistSimpleTemplateViewController alloc] initWithTitle:NAME templates:@[NAME]]; \
}                                                                                \
}
    
    return {
        {
            .title = @"示例",
            .items = {
                {
                    .title = @"边距",
                    .block = ^{
                        return [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"margin"]];
                    }
                },
                {
                    .title = @"基本属性",
                    .block = ^{
                        return [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"Properties"]];
                    }
                },
                {
                    .title = @"Grid",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"Grid"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                },
                {
                    .title = @"基线对齐",
                    .block = ^{
                        return [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"Baseline"]];
                    }
                },
                {
                    .title = @"事件处理",
                    .block = ^{
                        return [[MistSimpleTemplateViewController alloc] initWithTitle:@"评价" templates:@[@"EventParam"]];
                    }
                },
                {
                    .title = @"计算器",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"Calculator"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                },
                {
                    .title = @"天气",
                    .block = ^{
                        return [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"Weather"]];
                    }
                },
            }
        },
        {
            .title = @"Weibo",
            .subtitle = @"一个仿写的微博 Timeline",
            .block = ^{
                return [[WBTimelineListViewController alloc] init];
            }
        },
        {
            .title = @"Components",
            .subtitle = @"演示 text, image, scroll 等各种组件的用法",
            .items = {
                MIST_SINGLE_NODE_ITEM(@"Text", @""),
                MIST_SINGLE_NODE_ITEM(@"Image", @""),
                MIST_SINGLE_NODE_ITEM(@"Button", @""),
                MIST_SINGLE_NODE_ITEM(@"Scroll", @""),
                MIST_SINGLE_NODE_ITEM(@"Paging", @""),
                MIST_SINGLE_NODE_ITEM(@"Map", @""),
                MIST_SINGLE_NODE_ITEM(@"Switch", @""),
                MIST_SINGLE_NODE_ITEM(@"SegmentedControl", @""),
                MIST_SINGLE_NODE_ITEM(@"WebView", @""),
                MIST_SINGLE_NODE_ITEM(@"Indicator", @""),
                MIST_SINGLE_NODE_ITEM(@"Line", @""),
                MIST_SINGLE_NODE_ITEM(@"Picker", @""),
                {
                    .title = @"TextField",
                    .block = ^{
                        return [[MistTextViewDemoViewController alloc] initWithTitle:nil templates:@[@"TextField"]];
                    }
                },
                {
                    .title = @"TextView",
                    .block = ^{
                        return [[MistTextViewDemoViewController alloc] initWithTitle:nil templates:@[@"TextView"]];
                    }
                },
                {
                    .title = @"Custom Node",
                    .block = ^{
                        return [[MistCustomNodeDemoViewController alloc] initWithTitle:nil templates:@[@"CustomNode"]];
                    }
                },
            }
        },
        {
            .title = @"表达式",
            .subtitle = @"模板中使用表达式绑定数据",
            .items = {
                {
                    .title = @"数据类型",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"ExpressionType"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                },
                {
                    .title = @"运算符",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"ExpressionOperator"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                },
                {
                    .title = @"方法调用",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"ExpressionCall"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                },
                {
                    .title = @"全局函数",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"ExpressionGlobal"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                },
                {
                    .title = @"集合操作",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"ExpressionCollection"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                }
            }
        },
        {
            .title = @"Action",
            .subtitle = @"事件响应",
            .items = {
                {
                    .title = @"alert",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"Alert"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                },
                {
                    .title = @"http-request",
                    .block = ^{
                        MistSimpleTemplateViewController *vc = [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"HttpRequest"]];
                        vc.tableView.bounces = NO;
                        return vc;
                    }
                },
            }
        },
        {
            .title = @"JS Support",
            .subtitle = @"在模板中使用 JS",
            .block = ^{
                return [[MistSimpleTemplateViewController alloc] initWithTitle:nil templates:@[@"JSDemo"]];
            }
        },
        {
            .title = @"Playground",
            .subtitle = @"在这里尝试模版的编写",
            .block = ^{
                return [[MistSimpleTemplateViewController alloc] initWithTitle:nil data:@"Playground.json"];
            }
        },
    };
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    [[MSTDebugger defaultDebugger] startWithDownloader:NSClassFromString(@"MistDemoTemplateManager")];
#endif
    
    // 完成初始化
    [VZMist sharedInstance];
    
    //注册 js 全局对象
    [[VZMist sharedInstance] registerJSGlobalVariable:@"http" object:[MistJSHttpRequestHelper sharedInstance]];
    [[VZMist sharedInstance] registerJSGlobalVariable:@"toast" object:[MistJSToast class]];
    
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _viewController = [[MistDemoIndexViewController alloc] initWithTitle:@"MIST" demoItems:self.demos];
    _navController = [[UINavigationController alloc] initWithRootViewController:_viewController];
    _window.rootViewController = _navController;
    [_window makeKeyAndVisible];
    
    [VZMistJSEngine evaluateScript:@"var a = 1"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
