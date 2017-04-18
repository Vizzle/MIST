//
//  VZMistPage.m
//  O2OMist
//
//  Created by lingwan on 2017/2/9.
//  Copyright © 2017年 Alipay. All rights reserved.
//

#import "VZMistPage.h"
#import "VZScriptManager.h"

@interface VZMistPage ()
@property (nonatomic, strong) UIViewController *childVC;
@end

@implementation VZMistPage

- (instancetype)initWithPageName:(NSString *)pageName options:(NSDictionary*)options;
{
    if (self = [super init]) {
        self.options = options;
        self.pageName = pageName;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationController.navigationBar.translucent = NO;
    
    [self loadChildVCFromConfig];
    
#ifdef DEBUG
    //for mist debug use
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadChildVCFromConfig)
                                                 name:@"MISTDebugShouldReload"
                                               object:nil];
#endif
}

# pragma mark - Private methods

- (void)loadChildVCFromConfig {
#ifdef DEBUG
    if (_childVC) {
        [_childVC.view removeFromSuperview];
        [_childVC removeFromParentViewController];
    }
#endif
    
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(loadPageConfig:completion:)]) {
        NSAssert(YES, @"VZMistPage: VZMistPage代理非法");
    }
    
    __weak typeof(self) weakSelf = self;
    
    [self.delegate loadPageConfig:self.pageName completion:^(NSDictionary *result, NSError *error) {
        if (!result.allKeys.count || error) {
            NSLog(@"VZMistPage: %@ 配置文件出错，error=%@", weakSelf.pageName, error);
            [weakSelf showError:[NSError errorWithDomain:@"VZMistPage" code:-1 userInfo:@{@"reason": @"配置文件出错"}]];
        }
        
        NSString *script = result[@"script"];
        NSString *controller = result[@"dynamicController"];
        BOOL validScript = [script isKindOfClass:[NSString class]] && script.length > 0 &&
        [controller isKindOfClass:[NSString class]] && controller.length > 0;
        
        if (!validScript) {
            NSLog(@"VZMistPage: %@ 脚本内容不合法", weakSelf.pageName);
            [weakSelf showError:[NSError errorWithDomain:@"VZMistPage" code:-1 userInfo:@{@"reason": @"脚本内容不合法"}]];
        }
        
        [[VZScriptManager manager] runScript:script];
        
        UIViewController *vc = (UIViewController *)[NSClassFromString(controller) alloc];
        if ([vc respondsToSelector:NSSelectorFromString(@"initWithScheme:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            vc = [vc performSelector:NSSelectorFromString(@"initWithScheme:") withObject:weakSelf.options];
#pragma clang diagnostic pop
        } else {
            vc = [vc init];
        }
        
        if (!vc) {
            NSLog(@"VZMistPage: %@ vc为空", self.pageName);
            [weakSelf showError:[NSError errorWithDomain:@"VZMistPage" code:-1 userInfo:@{@"reason": @"生成vc为空"}]];
        }
        
        _childVC = vc;
        
        [weakSelf addChildViewController:_childVC];
        [weakSelf.view addSubview:_childVC.view];
    }];
}

- (void)showError:(NSError *)error {
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(showError:inViewController:)]) {
        NSAssert(YES, @"VZMistPage: VZMistPage代理非法");
    }
    
    [self.delegate showError:error inViewController:self];
}

@end
