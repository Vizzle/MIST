//
//  MistDemoConfigDownloader.h
//  MIST
//
//  Created by lingwan on 2017/3/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VZMistPage.h"

@interface MistDemoConfigDownloader : NSObject <VZMistPageDelegate>

+ (instancetype)defaultDelegate;

@end
