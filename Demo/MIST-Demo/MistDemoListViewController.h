//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <vector>

struct MistDemoItem {
    NSString *title;
    NSString *subtitle;
    UIViewController * (^block)();
    std::vector<MistDemoItem> items;
    NSString *url;
};


@interface MistDemoListViewController : UIViewController

- (instancetype)initWithTitle:(NSString *)title demoItems:(std::vector<MistDemoItem>)items;

@end
