# 事件处理

模版中预置了一些常用事件，如 [on-tap](Property.md#on-tap), [on-display](Property.md#on-display) 等。

事件触发时可以调用若干个关联的 [`Controller`](#controller) 上的方法。使用字典描述，key 为方法名，值为方法参数（方法的第一个参数），如：`"on-tap": { "onTap:": "param" }` 相当于掉用 `Controller` 的 `[Controller onTap:@"param"]`。方法第二个参数为事件的触发者，可能是 view 或 node 等。

## 预置方法

在 `controller` 的基类上预置了如下几个常用方法：

{% set properties = [
	{ "name": "openUrl:", "desc": "打开指定的 URL" },
    { "name": "updateState:", "desc": "更新状态。值应该为一个字典，将状态中对应的值更新。详见<a href='State.md'>状态</a>" }
] %}

{% include "../templates/properties.md" %}

## 扩展

现有的方法不能满足时，可以在模版对应的 `controller` 上添加方法，使用方法名即可调用。

如果想为所有模版增加方法，或覆盖现有方法。需要继承现有 controller 和 item 并重写 item 的 tplControllerClass 方法返回新的 controller 类，然后所有的 controller 和 item 都从这里创建的继承。

## once 事件

所有事件都有对应的 -once 事件，表示只在第一次触发该事件时响应，如 `on-display-once`。

注意，once 事件是通过元素的索引（[`gone`](Property.md#gone) 为 `true` 的元素也有索引）来区分的。

## Controller

每个模块都会创建一个 Controller，用于处理一些 native 逻辑，Controller 根据模版的 [`controller`](Property.md#controller) 属性自动创建。

同一模版根据不同数据生成的不同模块都有各自的 Controller 实例。
