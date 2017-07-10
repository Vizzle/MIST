//
//  VZMistScriptErrorWindow.h
//  MIST
//
//  Created by lingwan on 2017/7/10.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#ifdef DEBUG

#import <Foundation/Foundation.h>

@interface VZMistScriptErrorWindow : NSObject

+ (void)showWithErrorInfo:(NSString *)info;

@end

#endif
