# 样式

{% set properties = [
	{ "name": "background-color", "desc": "背景<a href='#颜色'>颜色</a>，默认为透明。" },
	{ "name": "border-width", "desc": "边框宽度，默认为 0。可以用 `\"1px\"`表示 1 像素的边框" },
	{ "name": "border-color", "desc": "边框<a href='#颜色'>颜色</a>，默认为黑色。" },
	{ "name": "corner-radius", "desc": "圆角半径，默认为 0。<br>可以使用 `corner-radius-top-left`、`corner-radius-top-right`、`corner-radius-bottom-left`、`corner-radius-bottom-right` 分别指定每个角的圆角半径。" },
	{ "name": "user-interaction-enabled", "desc": "设置生成的 view 的userInteractionEnabled。默认不设置。" },
	{ "name": "clip", "desc": "设置生成的 view 的 clipsToBounds。" },
    { "name": "properties", "desc": "通过反射给 view 设置属性，如：<br><pre><code>\"properties\": {\n  \"layer.shadowOpacity\": 1\n}</code></pre>" }
] %}

{% include "../templates/properties.md" %}

## 颜色

颜色使用 `"#rgb"`、`"#rrggbb"`、`"#argb"`、`"#aarrggbb"` 表示，如：`"#fff"` 表示白色。

颜色还可以使用以下名称定义：

- `"black"`
- `"darkgray"`
- `"lightgray"`
- `"white"`
- `"gray"`
- `"red"`
- `"green"`
- `"blue"`
- `"cyan"`
- `"yellow"`
- `"magenta"`
- `"orange"`
- `"purple"`
- `"brown"`
- `"transparent"`

## 阴影

Mist 目前没有提供阴影的支持，但是可以使用 [properties](#properties) 来实现

## 样式引用

可以在 [`styles`](Property.md#styles) 属性中定义样式，并在元素的 [`class`](Property.md#class) 属性引用

元素上定义的样式优先级高于 `class` 中引用的样式
