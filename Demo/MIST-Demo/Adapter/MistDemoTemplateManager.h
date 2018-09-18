//
//  MistDemoTemplateManager.h
//  MIST
//
//  Created by moxin on 2017/2/15.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VZMistTemplateDownload.h"

@interface MistDemoTemplateManager : NSObject <VZMistTplDownload>

+ (instancetype)defaultManager;

@end
