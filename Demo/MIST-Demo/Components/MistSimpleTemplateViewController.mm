//
//  MistSimpleTemplateViewController.m
//  MIST
//
//  Created by Sleen on 2017/2/28.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistSimpleTemplateViewController.h"
#import "MistDemoTemplateManager.h"
#import "VZMistTemplateDownload.h"
#import "VZMistListItem.h"
#import "VZMistTemplate.h"
#import "VZMistTemplateHelper.h"
#import <MIST/VZMist.h>
#import <MISTDebug/MSTDebugger.h>


@interface MistSimpleTemplateBlock : NSObject

@property (nonatomic, strong) NSString *templateName;
@property (nonatomic, strong) id data;

@end

@implementation MistSimpleTemplateBlock

- (instancetype)initWithTemplateName:(NSString *)templateName data:(id)data {
    if (self = [super init]) {
        _templateName = templateName;
        _data = data;
    }
    return self;
}

@end


@interface MistSimpleTemplateViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<MistSimpleTemplateBlock *> *blocks;
@property (nonatomic, strong) NSArray<VZMistListItem *> *items;

@end


@implementation MistSimpleTemplateViewController

- (instancetype)initWithTitle:(NSString *)title templates:(NSArray<NSString *> *)names
{
    if (self = [super init]) {
        NSMutableArray *blocks = [NSMutableArray new];
        for (NSString *name in names) {
            [blocks addObject:[[MistSimpleTemplateBlock alloc] initWithTemplateName:name data:nil]];
        }
        _blocks = blocks;
        self.title = title;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title data:(NSString *)data
{
    if (self = [super init]) {
        NSString *dataPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"mist.bundle/%@", data] ofType:nil];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath]
                                                               options:NSJSONReadingAllowFragments
                                                                 error:nil];
        NSAssert([result[@"blocks"] isKindOfClass:[NSArray class]], @"数据文件必须包含blocks数组");
        NSMutableArray *blocks = [NSMutableArray new];
        for (NSDictionary *block in result[@"blocks"]) {
            NSString *tplName = block[@"template"];
            NSAssert(tplName.length > 0, @"模版名不能为空");
            MistSimpleTemplateBlock *b = [[MistSimpleTemplateBlock alloc] initWithTemplateName:tplName data:block[@"data"]];
            [blocks addObject:b];
        }
        _blocks = blocks;
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.frame = self.view.bounds;
    [self.view addSubview:self.tableView];

    //for mist debug use
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(load)
                                                 name:MISTDebugShouldReloadNotification
                                               object:nil];
    [self load];
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [VZMistTemplateHelper colorFromString:@"#ddd"];
        _tableView.allowsSelection = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
    }
    return _tableView;
}

- (void)load
{
    NSArray *templateNames = [self.blocks valueForKey:@"templateName"];
    templateNames = [[NSSet setWithArray:templateNames] allObjects];
    [[MistDemoTemplateManager defaultManager] downloadTemplates:templateNames completion:^(NSDictionary<NSString *, NSString *> *templates) {
        NSMutableArray *items = [NSMutableArray new];
        for (MistSimpleTemplateBlock *block in self.blocks) {
            NSString *tplContent = templates[block.templateName];
            if (!tplContent) {
                continue;
            }
            NSDictionary *tplDict = [NSJSONSerialization JSONObjectWithData:[tplContent dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                  error:nil];
            if (!tplDict) {
                continue;
            }
            VZMistTemplate *tpl = [[VZMistTemplate alloc] initWithTemplateId:block.templateName
                                                                     content:tplDict
                                                                mistInstance:[VZMist sharedInstance]];
            VZMistListItem *item = [[VZMistListItem alloc] initWithData:block.data?:@{} customData:@{} template:tpl];
            [items addObject:item];
        }
        self.items = items;
        [self.tableView reloadData];
    } options:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VZMistListItem *item = self.items[indexPath.row];
    NSString *identifier = item.tpl.tplId;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [item attachToView:cell.contentView atIndexPath:indexPath];

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VZMistListItem *item = self.items[indexPath.row];
    return item.itemHeight;
}

@end
