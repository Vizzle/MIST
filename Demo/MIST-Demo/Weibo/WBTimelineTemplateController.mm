//
//  WBTimelineTemplateController.m
//  MIST
//
//  Created by moxin on 2017/3/14.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "WBTimelineTemplateController.h"
#import "VZMistListItem.h"
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>

@implementation WBTimelineTemplateController

+ (NSCalendar* )sharedCalendar{
    static dispatch_once_t onceToken;
    static NSCalendar* calendar = nil;
    dispatch_once(&onceToken, ^{
        
        if ([calendar respondsToSelector:@selector(calendarWithIdentifier:)]) {
            calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        }else{
            calendar = [NSCalendar currentCalendar];
        }
    });
    return calendar;
}

+ (NSString* )createdAt:(NSString* )time{
    
    NSCalendar* calendar = [self sharedCalendar];
    NSDateFormatter *fmt = [[NSDateFormatter alloc]init];
    // 设置日期格式
    fmt.dateFormat = @"EEE MMM d HH:mm:ss Z yyyy";
    fmt.locale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
    NSDate* createdAtDate = [fmt dateFromString:time];
    
    NSInteger selfYear = [calendar component:NSCalendarUnitYear fromDate:createdAtDate];
    NSInteger nowYear = [calendar component:NSCalendarUnitYear fromDate:[NSDate date]];
    
    // isThisYear是在NSDate中写的一个方法，具体实现放在下面一个代码块
    if (selfYear == nowYear) { // 今年
        if ([calendar isDateInToday:createdAtDate]) { // 今天
            // 手机当前时间
            NSDate *nowDate = [NSDate date];
            // 获得日期之间的间隔
            NSCalendarUnit unit = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
            NSDateComponents *components = [calendar components:unit fromDate:createdAtDate toDate:nowDate options:0];
            
            if (components.hour >= 1) {
                fmt.dateFormat = @"今天 HH:mm";
                return [fmt stringFromDate:createdAtDate];
            }else if(components.minute >= 1){
                return [NSString stringWithFormat:@"%zd分钟前",components.minute];
            }else{
                return @"刚刚";
            }
            
        }else if([calendar isDateInYesterday:createdAtDate]){  // 昨天
            fmt.dateFormat = @"昨天 HH:mm";
            return [fmt stringFromDate:createdAtDate];
        }else {  // 其他
            fmt.dateFormat = @"MM-dd HH:mm";
            return [fmt stringFromDate:createdAtDate];
        }
    }else {  // 非今年
        return time;
    }
    
    return time;
    
}


- (void)displayImages:(NSDictionary* )data sender:(UIView* )sender{

    NSNumber* initialPageIndex = data[@"index"];
    NSArray* imageURLs = data[@"images"];
    
    NSMutableArray* photos = [NSMutableArray new];
    for(NSDictionary* d in imageURLs){
        
        NSString* pic = d[@"thumbnail_pic"];
        NSURL* url = [NSURL URLWithString:pic];
        IDMPhoto* photo = [IDMPhoto photoWithURL:url];
        [photos addObject:photo];
    }
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:sender];
    [browser setInitialPageIndex:initialPageIndex.intValue];
    UIViewController* vc = self.item.viewController;
    
    if (vc) {
        [vc presentViewController:browser animated:YES completion:nil];
    }
    
}

- (void)onMore:(__unused id )obj{

    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"ActionSheet"
                                          message:@""
                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.item.viewController dismissViewControllerAnimated:NO completion:nil];
    }];  // UIAlertActionStyleCancel
    UIAlertAction *collectAction = [UIAlertAction actionWithTitle:@"收藏" style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *reportAction = [UIAlertAction actionWithTitle:@"举报" style:UIAlertActionStyleDefault handler:nil];

    [alertController addAction:collectAction];
    [alertController addAction:reportAction];
    [alertController addAction:cancelAction];
    [self.item.viewController presentViewController:alertController animated:YES completion:nil];
}


- (void)onLike:(__unused id)obj sender:(UIView* )sender{

    UIImageView* imgView = [sender viewWithTag:1];
    
    if (imgView) {
    
        NSDictionary* state = self.item.state;
        BOOL status = [state[@"like"][@"status"] boolValue];
        __block int count = [state[@"like"][@"count"] intValue];
        
        
        [UIView animateKeyframesWithDuration:0.6 delay:0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
            
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.2 animations:^{
                imgView.transform = CGAffineTransformMakeScale(1.8, 1.8);
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.2 relativeDuration:0.2 animations:^{
                imgView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.2 animations:^{
                imgView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];

            
        } completion:^(BOOL finished) {
            
            [self updateState:@{@"like":@{@"status":[NSNumber numberWithBool:!status],@"count":status?[NSNumber numberWithInt:count-1]:[NSNumber numberWithInt:count+1]}}];
            
        }];
    }
}

@end
