//
//  MistListDemoViewController.m
//  MIST
//
//  Created by Sleen on 2017/2/23.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "WBTimelineListViewController.h"
#import "MistDemoTemplateManager.h"
#import "VZMistTemplateDownload.h"
#import "VZMist.h"
#import "VZMistListItem.h"
#import "VZMistTemplate.h"
#import <MISTDebug/MSTDebugger.h>

@interface WBTimelineListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *items;
@end


@implementation WBTimelineListViewController

- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    self.title = @"Timeline";
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    //refresh button
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    self.navigationItem.rightBarButtonItem = rightBarItem;
    
    //for mist debug use
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:MISTDebugShouldReloadNotification
                                               object:nil];
    
    [self load];
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - private methods

- (void)load
{
    [[MistDemoTemplateManager defaultManager] downloadTemplates:@[@"WeiBo"] completion:^(NSDictionary<NSString *,NSString *> *templates) {
        NSString *path = [NSString stringWithFormat:@"%@/mist.bundle/WeiBo.json", [NSBundle bundleForClass:self].bundlePath];
        NSData *rawData = [NSData dataWithContentsOfFile:path];
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:rawData options:NSJSONReadingAllowFragments error:nil];
        self.items = [self itemsWithData:data[@"statuses"] templates:templates];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    } options:nil];
}

- (void)reload{
    self.items = @[];
    [self.tableView reloadData];
    [self load];
}


- (NSArray *)itemsWithData:(id)data templates:(NSDictionary<NSString *, NSString *> *)templates
{
    if (!templates.count) {
        return nil;
    }
    NSMutableArray *items = [NSMutableArray new];
    NSDictionary *tplDict = [NSJSONSerialization JSONObjectWithData:[templates[@"WeiBo"] dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:0
                                                              error:nil];
    if (!tplDict) {
        return @[];
    }
    VZMistTemplate *tpl = [[VZMistTemplate alloc] initWithTemplateId:@"WeiBo"
                                                                  content:tplDict
                                                             mistInstance:[VZMist sharedInstance]];
    
    
    for (NSDictionary *i in data) {
        VZMistListItem *item = [[VZMistListItem alloc] initWithData:i customData:@{} template:tpl];
        [items addObject:item];
    }
    
    return items;
}

- (void)showAlert:(NSString *)text
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VZMistListItem *item = self.items[indexPath.row];
    return item.itemHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"mist_demo_list_cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    VZMistListItem *item = self.items[indexPath.row];
    [item attachToView:cell.contentView atIndexPath:indexPath];
    
    return cell;
}


@end
