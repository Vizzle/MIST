//
//  Copyright © 2016年 Vizlab. All rights reserved.
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
