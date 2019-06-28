//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <VZFlexLayout/VZFlexLayout.h>


@interface VZFCustomNode : VZFNode


+ (instancetype)newWithView:(const VZ::ViewClass &)viewClass NodeSpecs:(const VZ::NodeSpecs &)specs NS_UNAVAILABLE;

+ (nonnull instancetype)newWithViewFactory:(nonnull ViewFactory)factory NodeSpecs:(const NodeSpecs &)specs Measure:(nullable CGSize (^)(CGSize constrainedSize))measure;

@end
