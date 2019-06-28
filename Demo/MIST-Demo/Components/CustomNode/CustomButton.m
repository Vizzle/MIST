//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "CustomButton.h"


@implementation CustomButton

- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title
{
    if (self = [super initWithFrame:frame]) {
        [self setTitle:title forState:UIControlStateNormal];
        self.clipsToBounds = YES;
        self.layer.cornerRadius = MIN(frame.size.width, frame.size.height) / 2;
        self.backgroundColor = [UIColor redColor];
        self.titleLabel.font = [UIFont systemFontOfSize:17];
    }
    return self;
}

@end
