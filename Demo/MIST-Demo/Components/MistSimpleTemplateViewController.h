//
//  MistSimpleTemplateViewController.h
//  MIST
//
//  Created by Sleen on 2017/2/28.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MistSimpleTemplateViewController : UIViewController

@property (nonatomic, strong, readonly) UITableView *tableView;

- (instancetype)initWithTitle:(NSString *)title templates:(NSArray<NSString *> *)names;
- (instancetype)initWithTitle:(NSString *)title data:(NSString *)data;

@end
