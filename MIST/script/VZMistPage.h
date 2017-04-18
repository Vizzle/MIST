//
//  O2OMistPage.h
//  O2OMist
//
//  Created by lingwan on 2017/2/9.
//  Copyright © 2017年 Alipay. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^VZMistPageCompletion)(NSDictionary *result, NSError *error);

@protocol VZMistPageDelegate <NSObject>

- (void)loadPageConfig:(NSString *)pageName completion:(VZMistPageCompletion)completion;
- (void)showError:(NSError *)error inViewController:(UIViewController *)vc;

@end

@interface VZMistPage : UIViewController

@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) NSString *pageName;

@property (nonatomic, weak) id<VZMistPageDelegate> delegate;

/**
 初始化一个单页面容器

 @param pageName 页面名，与页面配置文件同名
 @param options 业务参数
 @return 单页面ViewController
 */
- (instancetype)initWithPageName:(NSString *)pageName options:(NSDictionary*)options;

@end
