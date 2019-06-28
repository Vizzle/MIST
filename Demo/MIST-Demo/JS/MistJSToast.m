//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "MistJSToast.h"
#import <UIKit/UIKit.h>

@implementation MistJSToast

+ (void)alert:(NSString *)title content:(NSString *)content {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:content delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    });
}

@end
