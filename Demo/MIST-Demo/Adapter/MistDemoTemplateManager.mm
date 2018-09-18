//
//  MistDemoTemplateManager.m
//  MIST
//
//  Created by moxin on 2017/2/15.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistDemoTemplateManager.h"
#import "VZMistTemplateDownload.h"
#import "VZMistTemplate.h"
#import "VZMist.h"


@implementation MistDemoTemplateManager

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    static MistDemoTemplateManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [MistDemoTemplateManager new];
    });

    return instance;
}


- (void)downloadTemplates:(NSArray *)tplIds completion:(void (^)(NSDictionary<NSString *, NSString *> *templates))completion options:(NSDictionary *)opt
{
    __block NSMutableDictionary<NSString *, NSString *> *results = [NSMutableDictionary dictionary];
    __block NSInteger count = 0;
    for (NSString *tplId in tplIds) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *tplPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"mist.bundle/%@", tplId] ofType:@"mist"];
            NSString *result = [[NSString alloc] initWithContentsOfFile:tplPath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                ++count;
                [results setObject:result forKey:tplId];
                if (count == tplIds.count) {
                    if (completion) {
                        completion(results);
                    }
                }
            });

        });
    }
}

@end
