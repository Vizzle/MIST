# `node` 元素

最基本的元素类型，类似于 `iOS` 的 `UIView` 或 `Android` 的 `View`，可以设置背景色、边框等属性，常用于分割线、色块等。

不指定 [`type`](/basics/Property.md#type) 时默认为此类型。

## 示例

{% set code =
{
  "style": {
    "height": "1px",
    "background-color": "#ccc"
  }
}
%}
{% include "../templates/code.md" %}
