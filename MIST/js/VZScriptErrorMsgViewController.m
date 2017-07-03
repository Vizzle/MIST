//
//  O2OScriptErrorMsgViewController.m
//  O2OMist
//
//  Created by lingwan on 16/7/28.
//  Copyright © 2016年 Alipay. All rights reserved.
//

#ifdef DEBUG

#import "VZScriptErrorMsgViewController.h"

@interface VZScriptErrorMsgViewController ()
@property (nonatomic) NSString *msg;
@end

@implementation VZScriptErrorMsgViewController

- (instancetype)initWithMsg:(NSString *)msg {
    self = [super init];
    if (self) {
        self.msg = msg;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    textView.editable = NO;
    textView.scrollEnabled = YES;
    textView.text = self.msg;
    [self.view addSubview:textView];
    
    self.title = @"JS Error";
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(handleBack)]];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBack)];
    doubleTap.numberOfTapsRequired = 2;
    [textView addGestureRecognizer:doubleTap];
}

- (void)handleBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

#endif
