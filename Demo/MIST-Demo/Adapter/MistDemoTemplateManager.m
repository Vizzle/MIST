//
//  MistDemoTemplateManager.m
//  MIST
//
//  Created by moxin on 2017/2/15.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MistDemoTemplateManager.h"


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


- (void)downloadTemplates:(NSArray *)tplIds completion:(void (^)(NSDictionary<NSString *, VZMistTemplate *> *))completion options:(NSDictionary *)opt
{
    __block NSDictionary<NSString *, VZMistTemplate *> *results = [NSMutableDictionary dictionary];
    __block NSInteger count = 0;
    for (NSString *tplId in tplIds) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *tplPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"mist.bundle/%@", tplId] ofType:@"mist"];
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:tplPath]
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                ++count;
                VZMistTemplate *template = [[VZMistTemplate alloc] initWithTemplateId:tplId content:result];
                [results setValue:template forKey:tplId];
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
