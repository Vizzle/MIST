//
//  MSTDemoViewController.m
//  MIST-Demo
//
//  Created by Tao Xu on 9/18/18.
//  Copyright © 2018 Vizlab. All rights reserved.
//

#import "MSTDemoTableViewController.h"
#import "VZMist.h"
#import "VZMistListItem.h"
#import "VZMistTemplate.h"
#import "MistDemoTemplateManager.h"
#import <MISTDebug/MSTDebugger.h>

@interface MSTDemoTableViewController ()<UITableViewDelegate,UITableViewDataSource>{
    
}
@property(nonatomic,strong) UITableView* tableView;
@property(nonatomic,strong) NSArray<VZMistListItem* >* items;
@property(nonatomic,strong) NSArray<NSDictionary* >* posts;

@end

@implementation MSTDemoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:self.tableView];
    
    
    //for mist debug use
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:MISTDebugShouldReloadNotification
                                               object:nil];
    
    [self load];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)load{
    
    [[MistDemoTemplateManager defaultManager] downloadTemplates:@[@"Post"] completion:^(NSDictionary<NSString *,NSString *> *templates) {
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://jsonplaceholder.typicode.com/posts/"]];
        self.posts = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil] copy];;
        self.items = [[self itemsWithData:self.posts templates:templates] copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    } options:nil];
}

- (void)reload{
    self.items = @[];
    [self.tableView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MistDemoTemplateManager defaultManager] downloadTemplates:@[@"Post"] completion:^(NSDictionary<NSString *,NSString *> *templates) {
            self.items = [self itemsWithData:self.posts templates:templates];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        } options:nil];
    });
}


- (NSArray *)itemsWithData:(id)data templates:(NSDictionary<NSString *, NSString *> *)templates
{
    if (!templates.count) {
        return nil;
    }
    NSMutableArray *items = [NSMutableArray new];
    NSError* error ;
    NSDictionary *tplDict = [NSJSONSerialization JSONObjectWithData:[templates[@"Post"] dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:0
                                                              error:&error];
    if(error){
        NSLog(@"Template format error!");
        return @[];
    }
    VZMistTemplate *tpl = [[VZMistTemplate alloc] initWithTemplateId:@"Post"
                                                             content:tplDict
                                                        mistInstance:[VZMist sharedInstance]];
    
    
    for (NSDictionary *i in data) {
        VZMistListItem *item = [[VZMistListItem alloc] initWithData:i customData:@{} template:tpl];
        [items addObject:item];
    }
    
    return items;
}

#pragma mark - TableView

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
