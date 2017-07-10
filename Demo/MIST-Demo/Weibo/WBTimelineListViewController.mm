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
@property (nonatomic, strong) NSURLSession* httpSession;

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
    
    
    //disable http cache
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    self.httpSession = [NSURLSession sessionWithConfiguration:configuration];
    
    //refresh button
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(load)];
    self.navigationItem.rightBarButtonItem = rightBarItem;
    
    //for mist debug use
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(load)
                                                 name:MISTDebugShouldReloadNotification
                                               object:nil];
    
    [self load];
    
}

- (void)load
{
    
    self.items = @[];
    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        void (^completion)(id, NSError*) = ^(id data, NSError *error) {
            
            if (error) {
                NSString *errorMessage = error.localizedDescription ?: @"数据请求失败";
                [self showAlert:errorMessage];
                return;
            }
            
            
            [[MistDemoTemplateManager defaultManager] downloadTemplates:@[@"WeiBo"] completion:^(NSDictionary<NSString *, NSString *> *templates) {
                //refresh UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    self.items = [self itemsWithData:data templates:templates];
                    [self.tableView reloadData];
                    
                });
            } options:nil];
        };

#define PRODUCTION 1
        
#ifdef PRODUCTION
        NSString *path = [NSString stringWithFormat:@"%@/mist.bundle/wb_api.json", [NSBundle bundleForClass:self].bundlePath];
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        completion(dict[@"statuses"], nil);
#else
        [self fetchDataWithCompletion:completion];
#endif
        
    });
}

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

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - private methods


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


- (NSURL *)dataUrl
{
    return [NSURL URLWithString:@"https://api.weibo.com/2/statuses/home_timeline.json?access_token=2.008fWcBCtXRCEEda8555f52c041UWb"];
    //return [NSURL URLWithString:@"http://127.0.0.1:10001/wb_api.json"];
}

typedef void (^MistFetchDataCompletionBlock)(id data, NSError *error);
- (void)fetchDataWithCompletion:(MistFetchDataCompletionBlock)block
{
    
    NSAssert([self dataUrl], @"no data url specified!");
    
    __block UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height * 0.5);
    [indicator startAnimating];
    [self.view addSubview:indicator];
    [self.view bringSubviewToFront:indicator];
    
    [[self.httpSession dataTaskWithURL:[self dataUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [indicator stopAnimating];
            [indicator removeFromSuperview];
            
            if (error) {
                if (block) {
                    block(nil,error);
                }
            }
            else{
                
                if (data) {
                    NSDictionary *resultJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    NSString* errorMsg = resultJSON[@"error"];
                    if (errorMsg.length > 0) {
                        block(nil,[NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:errorMsg}]);
                    }else{
                        block(resultJSON[@"statuses"], error);
                    }
                    
                } else {
                    block(nil, error);
                }
            }
        });
        
        
    }] resume];
}


- (void)showAlert:(NSString *)text
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
