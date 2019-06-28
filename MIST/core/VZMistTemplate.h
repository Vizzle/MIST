//
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VZMist;


@interface VZMistTemplate : NSObject


/**
 模板Id
 */
@property (nonatomic, strong, readonly) NSString *tplId;
/**
 模板的内部标识，一般用于native代码识别模板的标识，从而能够跟模板Id隔离。
 */
@property (nonatomic, strong, readonly) NSString *identifier;
/**
 模板原始内容
 */
@property (nonatomic, strong, readonly) NSDictionary *tplRawContent;
/**
 模板解析后的结果
 */
@property (nonatomic, strong, readonly) NSDictionary *tplParsedResult;
/**
 initial state
 理解state参考Reacthttps://facebook.github.io/react-native/docs/state.html
 */
@property (nonatomic, strong, readonly) NSDictionary *initialState;
/**
 对数据进行一些处理或适配
 */
@property (nonatomic, strong, readonly) NSDictionary *data;
/**
 定义一些 action，可以在 native 或别的 action 中通过 runAction: 调用
 */
@property (nonatomic, strong, readonly) NSDictionary *actions;
/**
 模版中接收的通知
 */
@property (nonatomic, strong, readonly) NSDictionary *notifications;
/**
 模板对应的controller类
 */
@property (nonatomic, strong, readonly) Class tplControllerClass;
/**
 模板复用的表示
 */
@property (nonatomic, strong, readonly) NSString *tplReuseIdentifier;
/**
 样式表
 */
@property (nonatomic, strong, readonly) NSDictionary *styles;
/**
 模板显示是否需要异步渲染
 */
@property (nonatomic, assign, readonly) BOOL asyncDisplay;
/**
 高度变化时是否需要动画
 */
@property (nonatomic, assign) BOOL cellHeightAnimation;
/**
 模板中脚本内容
 */
@property (nonatomic, strong, readonly) NSString *script;
/**
 模板中脚本内容
 */
@property (nonatomic, strong, readonly) NSDictionary *onStateUpdated;

/**
 创建此模版的 Mist 引擎实例
 */
@property (nonatomic, weak, readonly) VZMist *mistInstance;
/**
 子模版定义
 */
@property (nonatomic, strong, readonly) NSDictionary *templatesMap;

/**
 创建Template实体

 @param tplId 模板Id
 @param content 模板原始数据
 @return 模板对象
 */
- (instancetype)initWithTemplateId:(NSString *)tplId content:(NSDictionary *)content mistInstance:(VZMist *)mistInstance;

@end
