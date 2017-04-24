//
//  MistDemoListViewController.m
//  MIST
//
//  Created by Sleen on 2017/3/20.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistDemoListViewController.h"


@interface MistDemoListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) std::vector<MistDemoItem> items;
@property (nonatomic, strong) UITableView *tableView;

@end


@implementation MistDemoListViewController

- (instancetype)initWithTitle:(NSString *)title demoItems:(std::vector<MistDemoItem>)items
{
    if (self = [super init]) {
        self.title = title;
        self.items = items;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.rowHeight = 52.0f;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.size();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"PortalCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    MistDemoItem item = self.items[indexPath.row];
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = item.subtitle;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MistDemoItem item = self.items[indexPath.row];
    UIViewController *viewController = nil;
    if (item.items.size() > 0) {
        viewController = [[MistDemoListViewController alloc] initWithTitle:item.title demoItems:item.items];
    } else if (item.block) {
        viewController = item.block();
    } else if (item.url) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:item.url]];
    }
    
    if (viewController) {
        if (!viewController.title) {
            viewController.title = item.title;
        }
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
