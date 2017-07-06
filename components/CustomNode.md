# 自定义组件

模版中可以方便的嵌入现有的 native view，通过 `-[VZMist registerTag:withProcessor:]` 注册，示例如下：

```objc
[[VZMist sharedInstance] registerTag:@"custom-button" withProcessor:^VZFNode *(VZ::NodeSpecs specs, NSDictionary *tpl, id<VZMistItem> item, VZTExpressionContext *data) {

    NSString *title = [tpl valueForKeyPath:@"style.title"];
    VZMistTemplateEvent *event = [VZMistTemplateEvent eventWithName:@"on-tap" dict:tpl expressionContext:data item:item];

    return [VZFCustomNode newWithViewFactory:^(CGRect frame) {
        // frame 为布局后的尺寸

        CustomButton *button = [[CustomButton alloc] initWithFrame:frame title:title];
        [button addTarget:event action:@selector(invokeWithSender:) forControlEvents:UIControlEventTouchUpInside];
        return button;
    } NodeSpecs:specs
        Measure:^(CGSize constrainedSize) {
            // measure 函数，不传 measure 函数的话 custom node 在使用时需指定大小

            VZFTextNodeRenderer *renderer = [VZFTextNodeRenderer new];
            renderer.text = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17]}];
            renderer.maxSize = CGSizeMake(constrainedSize.width - 20, constrainedSize.height - 10);
            CGSize size = [renderer textSize];
            return CGSizeMake(size.width + 20, size.height + 10);
        }];
}];
```

{% set code =
{
    "type": "custom-button",
    "on-tap": {
        "alert:": "Hello !"
    },
    "style": {
        "title": "Custom Button",
        "margin-top": 10,
        "margin-bottom": 10,
        "align-self": "center"
    }
}
%}
{% include "../templates/code.md" %}

注册的代码可以写在任何位置，只要保证在读模版前注册即可。注册已有的元素名会覆盖原来的实现，如可以注册 `image` 标签，来实现一些特殊的逻辑。

注意，自定义组件中，只能使用布局属性，不能使用样式、`tag`、事件等属性，如果需要，可以给它加一个容器，然后把属性设置到容器上。
