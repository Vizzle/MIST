//
//  MistTextFieldDemoViewController.m
//  MIST
//
//  Created by wuwen on 2017/3/3.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistTextFieldDemoViewController.h"

@interface MistTextFieldDemoViewController ()

@end

@implementation MistTextFieldDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIEdgeInsets contentInset = self.tableView.contentInset;
    self.tableView.contentInset = UIEdgeInsetsMake(contentInset.top,
                                                   contentInset.left,
                                                   260,
                                                   contentInset.right);
}

@end
