//
//  VZMistItem.h
//  MIST
//
//  Created by moxin on 2017/2/17.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class VZMistTemplate;
@class VZMistTemplateController;

@protocol VZMistItem <NSObject>

@required

@property(nonatomic,weak,readonly) UIViewController* viewController;
/**
 关联的 controller 对象
 */
@property (nonatomic, strong, readonly) VZMistTemplateController *tplController;

/**
 关联的模板对象
 */
@property (nonatomic, strong, readonly) VZMistTemplate *tpl;
/**
 关联的数据
 */
@property (nonatomic, strong, readonly) NSDictionary *data;
/**
 模板中UI组件的的state,理解state参考Reacthttps://facebook.github.io/react-native/docs/state.html
 */
@property (nonatomic, strong, readonly) id state;
/**
 执行js、调用js方法的JSContext
 */
@property (nonatomic, strong, readonly) JSContext *jsContext;

/**
 默认的 controller 类。根据不同的item可以返回不同的 controller，可以实现不同业务方接入的时候，同样的功能（比如埋点）有不同的实现。
 
 @return 默认的 controller 类
 */
- (Class)templateControllerClass;

/**
 改变 state。

 @param block ：【in】=>old state /【out】=>new state
 */
- (void)updateState:(id (^)(id))block;

@end

@protocol VZMistAsyncDisplayItem <NSObject>

@required
@property (nonatomic, assign) BOOL asyncDisplay;

@end
