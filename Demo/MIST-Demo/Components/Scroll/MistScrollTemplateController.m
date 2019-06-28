//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistScrollTemplateController.h"
#import <UIKit/UIKit.h>


@implementation MistScrollTemplateController

- (void)scrollsToTop
{
    UIScrollView *scrollView = (UIScrollView *)[self viewWithTag:1];
    [scrollView setContentOffset:CGPointZero animated:YES];
}

@end
