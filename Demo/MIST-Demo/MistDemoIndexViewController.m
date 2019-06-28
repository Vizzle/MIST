//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistDemoIndexViewController.h"
#import "MistSimpleTemplateViewController.h"


@interface MistDemoIndexViewController ()

@end


@implementation MistDemoIndexViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTitleView];

    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"Try Out!" style:UIBarButtonItemStyleDone target:self action:@selector(tryOut)];
    self.navigationItem.rightBarButtonItem = right;
}

- (void)setupTitleView
{
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-Bold" size:20.0];
    label.text = self.title;
    [label sizeToFit];
    self.navigationItem.titleView = label;
}

- (void)tryOut
{
    MistSimpleTemplateViewController *guide = [[MistSimpleTemplateViewController alloc] initWithTitle:@"Try Out!" templates:@[@"TryOut!"]];
    [self.navigationController pushViewController:guide animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

@end
