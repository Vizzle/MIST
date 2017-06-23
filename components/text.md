# `text` 元素

用于显示文字

{% set properties = [
	{ "name": "text", "desc": "显示的文字" },
	{ "name": "html-text", "desc": "使用 HTML 表示的富文本，指定这个属性后，`text` 属性将被忽略。详细说明待补充。" },
	{ "name": "color", "desc": "文字[颜色](color.html)。默认为黑色。" },
	{ "name": "font-size", "desc": "字体大小。默认为17。" },
	{ "name": "font-name", "desc": "字体名。默认为系统字体。" },
	{ "name": "font-style", "desc": "字体样式。", "enum": ["ultra-light", "thin", "light", "normal", "medium", "bold", "heavy", "black", "italic", "bold-italic"] },
	{ "name": "alignment", "desc": "文字水平对齐方式。默认为 `left`。", "enum": ["left", "center", "right", "natural", "justify"] },
	{ "name": "line-break-mode", "desc": "文字换行方式。默认为 `truncating-tail`。", "enum": ["word", "char", "clip", "truncating-head", "truncating-middle", "truncating-tail"] },
	{ "name": "lines", "desc": "最大行数。为 0 时，不限制行数。默认为 1。" },
	{ "name": "adjusts-font-size", "desc": "是否调整字号以适应控件的宽度，默认为`false`。" },
	{ "name": "mini-scale-factor", "desc": "与`adjusts-font-size`配合使用，设置一个字号调整的最小系数，设置为0时，字号会调整至内容能完全展示。" }
] %}

{% include "../templates/properties.md" %}
