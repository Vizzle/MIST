# `scroll` 元素

滚动容器元素，使用 `children` 定义子元素。

注意：`scroll` 元素的尺寸不会根据它的子元素自适应。

## 属性

{% set properties = [
	{ "name": "scroll-direction", "desc": "滚动方向。默认为 horizontal。<br>与 <a href='../basics/Layout.md#direction'><code>direction</code></a> 不同，<code>direction</code> 表示子元素实际布局方向，<code>scroll-direction</code>表示该方向上不限制子元素的尺寸<br><code>none</code> 水平方向和竖直方向都不允许滚动。<br><code>horizontal</code> 水平方向滚动。<br><code>vertical</code> 竖直方向滚动。<br><code>both</code> 水平方向和竖直方向都可以滚动。", "enum": ["none", "horizontal", "vertical", "both"] },
	{ "name": "scroll-enabled", "desc": "是否允许用户拖动。" }
] %}

{% include "../templates/properties.md" %}
