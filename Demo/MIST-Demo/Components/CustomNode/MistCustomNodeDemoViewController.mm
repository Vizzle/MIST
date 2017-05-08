//
//  MistCustomNodeDemoViewController.m
//  MIST
//
//  Created by Sleen on 2017/3/6.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistCustomNodeDemoViewController.h"
#import "VZMist.h"
#import "VZFCustomNode.h"
#import "CustomButton.h"
#import "VZFTextNodeRenderer.h"
#import "VZMistTemplateEvent.h"


@interface MistCustomNodeDemoViewController ()

@end


@implementation MistCustomNodeDemoViewController

- (void)viewDidLoad
{
    // 注册 custom node
    [[VZMist sharedInstance] registerTag:@"custom-button" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, NSDictionary *data) {

        NSString *title = [tpl valueForKeyPath:@"style.title"];
        VZMistTemplateEvent *event = [[VZMistTemplateEvent alloc] initWithItem:item action:tpl[@"on-tap"] onceAction:tpl[@"on-tap-once"] expressionContext:nil];

        return [VZFCustomNode newWithViewFactory:^(CGRect frame) {
            // frame 为布局后的尺寸

            CustomButton *button = [[CustomButton alloc] initWithFrame:frame title:title];
            [button addTarget:event action:@selector(invokeWithSender:) forControlEvents:UIControlEventTouchUpInside];
            return button;
        } NodeSpecs:specs
            Measure:^(CGSize constrainedSize) {
                // measure 函数，不传 measure 函数的话 custom node 在使用时需指定大小

                VZFTextNodeRenderer *renderer = [VZFTextNodeRenderer new];
                renderer.text = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17]}];
                renderer.maxSize = CGSizeMake(constrainedSize.width - 20, constrainedSize.height - 10);
                CGSize size = [renderer textSize];
                return CGSizeMake(size.width + 20, size.height + 10);
            }];
    }];

    [super viewDidLoad];
}

@end
