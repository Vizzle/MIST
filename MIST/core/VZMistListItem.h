//
//  VZMistItem.h
//  MIST
//
//  Created by moxin on 2016/12/6.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VZFNodeListItem.h"
#import "VZMistItem.h"


@class VZMistListItem;
@protocol VZMistListItem <VZMistItem>

- (UITableView *)tableView;

//- (VZMistListItem *)itemAtIndexPath:(NSIndexPath *)indexPath;


@end


@class VZMistTemplateController;
@class VZMistTemplate;


@interface VZMistListItem : VZFNodeListItem <VZMistListItem>


/**
 继承自父类。item 展示所需要的宽度，使用的是屏幕宽度。
 */
//@property (nonatomic, assign, readonly) float itemWidth;

/**
 继承自父类。item 展示所需的高度，也就是对应的 cell 的高度。
 */
//@property (nonatomic, assign, readonly) float itemHeight;

/**
 继承自父类。展示到的 view，也就是 cell 的 contentView
 */
//@property (nonatomic, weak, readonly) UIView *attachedView;

/**
 tableView 的 indexPath
 */
@property (nonatomic, strong, readonly) NSIndexPath *indexPath;
/**
 template controller 对象
 */
@property (nonatomic, strong, readonly) VZMistTemplateController *tplController;
/**
 模板中UI组件的的state,理解state参考Reacthttps://facebook.github.io/react-native/docs/state.html
 @discussion：
 state的初始值(initial state)会优先从模板的"state"标签获取，如果没有则会从controller的initialState获取
 */
@property (nonatomic, strong, readonly) id state;
/**
 关联的数据
 */
@property (nonatomic, strong, readonly) NSDictionary *data;
/**
 关联的模板对象
 */
@property (nonatomic, strong, readonly) VZMistTemplate *tpl;

/**
 渲染，生成视图布局
 */
- (void)render;

/**
 通过数据和模板构造Item对象

 @param data 数据
 @param customData 放置模板所需要的自定义数据，也就是非来自服务器端下发的。比如传入indexPath，屏幕宽度等
 @param tpl 模板对象
 @return item 构建好的item
 */
- (instancetype)initWithData:(NSDictionary *)data
                  customData:(NSDictionary *)customData
                    template:(VZMistTemplate *)tpl NS_DESIGNATED_INITIALIZER;

/**
 更新关联的数据
 @discussion: 更新数据仍会保留state
 @param data 数据
 */
- (void)setData:(NSDictionary *)data keepState:(BOOL)b;
/**
 更新state参考Reacthttps://facebook.github.io/react-native/docs/state.html
 @param block state更新函数
 */
- (void)updateState:(id (^)(id oldState))block;

/**
 table view 下使用这个方法传入 indexPath，用于 item 更新界面的时候做一下检测保护。

 @param view cell 的 contentView
 @param indexPath cell 的 indexPath
 */
- (void)attachToView:(UIView *)view atIndexPath:(NSIndexPath *)indexPath;

@end
