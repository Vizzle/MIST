//
//  Copyright © 2016年 Vizlab. All rights reserved.
//
#import "VZMistTemplateAnimation.h"
#import "VZDataStructure.h"

@interface VZMistAnimationDelegate : NSObject <CAAnimationDelegate>
@property (nonatomic, strong) NSDictionary *startEvent;
@property (nonatomic, strong) NSDictionary *endEvent;
@property (nonatomic, strong) VZTExpressionContext *context;
@property (nonatomic, weak) UIView *view;
@property (nonatomic, weak) id<VZMistItem> item;
@property (nonatomic, assign) BOOL forceVisible;
@end
@implementation VZMistAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag && _endEvent) {
        [[VZMistTemplateAction actionWithDictionary:_endEvent expressionContext:_context item:_item] runWithSender:_view];
    }
}

- (void)animationDidStart:(CAAnimation *)anim {
    if (_forceVisible) {
        _view.hidden = NO;
    }
    if (_startEvent) {
        [[VZMistTemplateAction actionWithDictionary:_startEvent expressionContext:_context item:_item] runWithSender:_view];
    }
}

@end


@implementation VZMistTemplateAnimation

- (void)runWithView:(UIView *)view {
    _animation.beginTime = _delay > 0 ? _delay + CACurrentMediaTime() : 0;

    VZMistAnimationDelegate *delegate = [[VZMistAnimationDelegate alloc] init];
    delegate.startEvent = _startEvent;
    delegate.endEvent = _endEvent;
    delegate.view = view;
    delegate.item = _item;
    delegate.context = _context;
    _animation.delegate = delegate;

    UIView *animView;
    if (_viewTag != 0) {
        animView = [[self getRootView:view] viewWithTag:_viewTag];
    }
    else {
        animView = view;
    }

    if (animView) {
        [animView.layer addAnimation:_animation forKey:_key];
    }
}

- (UIView *)getRootView:(UIView *)view {
    UIView *root = view;
        // 目前假定模版生成的view一定是在UITableViewCell里
    while (root.superview && ![root.superview isKindOfClass:[UITableViewCell class]]) root = root.superview;
    return root;
}


+ (CAAnimation *)parseCAAnimation:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    CAAnimation *anim;

    if (dict[@"key-path"]) {
        NSString *keyPath = __vzString(dict[@"key-path"], nil);
        NSAssert(keyPath.length > 0, @"invalid key-path '%@'", keyPath);

        if (dict[@"key-frames"]) {
            NSAssert([dict[@"key-frames"] isKindOfClass:[NSDictionary class]], @"key-frames must be an dictionary");
            NSDictionary *keyFrames = __vzDictionary(dict[@"key-frames"], @{});

            NSMutableArray *keyTimes = [NSMutableArray arrayWithCapacity:keyFrames.count];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:keyFrames.count];
            for (NSString *time in [keyFrames.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
                [keyTimes addObject:@([time doubleValue])];
                [values addObject:keyFrames[time]];
            }

            CAKeyframeAnimation *keyframeAnim = [CAKeyframeAnimation animationWithKeyPath:keyPath];
            keyframeAnim.keyTimes = keyTimes;
            keyframeAnim.values = values;
            keyframeAnim.calculationMode = __vzString(dict[@"calculation-mode"], @"linear");

            if (dict[@"timing-functions"]) {
                NSMutableArray *timingFunctions = [NSMutableArray array];
                for (NSString *f in __vzArray(dict[@"timing-functions"], @[])) {
                    if (__IsStringValid(f)) {
                        CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction functionWithName:f];
                        if (timingFunction) {
                            [timingFunctions addObject:timingFunction];
                        }
                    }
                }
                keyframeAnim.timingFunctions = timingFunctions;
            }

            anim = keyframeAnim;
        }
        else {
            CABasicAnimation *basicAnim;

            if (dict[@"mass"] || dict[@"stiffness"] || dict[@"damping"] || dict[@"initial-velocity"]) {
                CASpringAnimation *springAnim = [CASpringAnimation animationWithKeyPath:keyPath];
                springAnim.mass = __vzDouble(dict[@"mass"], 1);
                springAnim.stiffness = __vzDouble(dict[@"stiffness"], 100);
                springAnim.damping = __vzDouble(dict[@"damping"], 10);
                springAnim.initialVelocity = __vzDouble(dict[@"initial-velocity"], 0);
                basicAnim = springAnim;
            }
            else {
                basicAnim = [CABasicAnimation animationWithKeyPath:keyPath];
            }
            basicAnim.fromValue = dict[@"from"];
            basicAnim.toValue = dict[@"to"];
            basicAnim.byValue = dict[@"by"];
            anim = basicAnim;
        }
    }
    else if (dict[@"animations"]) {
        NSArray *animations = dict[@"animations"];
        NSAssert([animations isKindOfClass:[NSArray class]], @"animations must be an array");
        NSMutableArray *anims = [NSMutableArray array];
        for (id child in animations) {
            CAAnimation *anim = [self parseCAAnimation:child];
            if (anim) {
                [anims addObject:anim];
            }
        }
        CAAnimationGroup *animGroup = [CAAnimationGroup animation];
        animGroup.animations = anims;
        anim = animGroup;
    }

    anim.duration = __vzDouble(dict[@"duration"], 0);
    anim.autoreverses = __vzBool(dict[@"auto-reverses"], NO);
    anim.repeatCount = __vzDouble(dict[@"repeat"], 0);
    anim.fillMode = __vzString(dict[@"fill-mode"], kCAFillModeRemoved);
    anim.removedOnCompletion = __vzBool(dict[@"removed-on-completion"], YES);
    anim.speed = __vzDouble(dict[@"speed"], 1);
    anim.timeOffset = __vzDouble(dict[@"time-offset"], 0);
    anim.timingFunction = [CAMediaTimingFunction functionWithName:__vzString(dict[@"timing-function"], @"linear")];

    return anim;
}

+ (instancetype)animationWithDict:(NSDictionary *)dict item:(id<VZMistItem>)item {
    VZMistTemplateAnimation *animation = [[VZMistTemplateAnimation alloc] init];
    animation.animation = [self parseCAAnimation:dict];
    animation.delay = __vzDouble(dict[@"delay"], 0);
    animation.viewTag = __vzInt(dict[@"tag"], 0);
    animation.key = __vzString(dict[@"key"], dict[@"key-path"]);
    animation.item = item;
    animation.context = item.expressionContext.copy;
    animation.startEvent = __vzDictionary(dict[@"start"], nil);
    animation.endEvent = __vzDictionary(dict[@"end"], nil);
    return animation;
}

@end
