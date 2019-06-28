//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistTextViewDemoViewController.h"

@interface MistTextViewDemoViewController ()

@end

@implementation MistTextViewDemoViewController

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
