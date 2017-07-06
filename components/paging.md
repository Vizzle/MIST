# `paging` 元素

分页元素，使用 `children` 定义子元素，每个子元素就是一页。

**注意**  
- `paging` 元素的尺寸不会根据它的子元素自适应，所以 `paging` 元素一定要设置尺寸。
- `paging` 元素不能使用容器属性。
- 所有子元素都按照 `paging` 元素的尺寸布局，子元素的 [`margin`](../basics/Layout.md#margin) 不能为 `auto`。

## 属性

{% set properties = [
	{ "name": "direction", "desc": "滚动方向。默认为 horizontal。<br><code>horizontal</code> 水平方向滚动。<br><code>vertical</code> 竖直方向滚动。", "enum": ["horizontal", "vertical"] },
	{ "name": "scroll-enabled", "desc": "是否允许用户拖动。默认为 <code>true</code>。" },
	{ "name": "paging", "desc": "是否以分页的方式滚动。默认为 <code>true</code>。" },
	{ "name": "auto-scroll", "desc": "自动滚动的时间间隔，单位为秒，为 0 表示不自动滚动。默认为 <code>0</code>。" },
	{ "name": "infinite-loop", "desc": "是否循环滚动。默认为 <code>false</code>。" },
	{ "name": "page-control", "desc": "是否显示 Page Control。默认为 <code>false</code>。" },
	{ "name": "page-control-scale", "desc": "Page Control 缩放倍率，用于控制 Page Control 的大小。默认为 <code>1</code>。" },
	{ "name": "page-control-color", "desc": "Page Control 圆点的<a href='../basics/Style.md#颜色'>颜色</a>。默认为半透明的白色。" },
	{ "name": "page-control-selected-color", "desc": "Page Control 当前页圆点的<a href='../basics/Style.md#颜色'>颜色</a>。默认为白色。" },
	{ "name": "page-control-margin-left page-control-margin-right page-control-margin-top page-control-margin-bottom", "desc": "Page Control 距容器边缘的边距，用于控制 Page Control 的位置，跟 <a href='../basics/Layout.md#fixed'><code>fixed</code></a> 元素的 <a href='../basics/Layout.md#margin'><code>margin</code></a> 规则相同。<br>默认值为 <code>auto</code>，即默认显示在容器中间。" }
] %}

{% include "../templates/properties.md" %}
