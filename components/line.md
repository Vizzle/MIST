# `line` 元素

线条元素，主要用于展示虚线，其粗细、长度由布局属性控制。

## 属性

{% set properties = [
	{ "name": "color", "desc": "线条的<a href='../basics/Style.md#颜色'>颜色</a>，默认为黑色。" },
    { "name": "dash-length", "desc": "虚线的线段长度，不设置时为实线。" },
    { "name": "space-length", "desc": "虚线的空白长度，不设置时为实线。" }
] %}

{% include "../templates/properties.md" %}
