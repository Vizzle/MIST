//
//  VZMistHTMLStringParser.h
//  MIST
//
//  Created by moxin on 2016/12/7.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VZMistHTMLStringParser : NSObject

+ (NSAttributedString *)attributedStringFromHtml:(NSString *)html;

@end
