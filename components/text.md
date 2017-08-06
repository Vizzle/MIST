# `text` 元素

用于显示文字

## 属性

{% set properties = [
	{ "name": "text", "desc": "显示的文字" },
	{ "name": "html-text", "desc": "使用 HTML 表示的<a href='#富文本'>富文本</a>，指定这个属性后，<code>text</code> 属性将被忽略。" },
	{ "name": "color", "desc": "文字<a href='../basics/Style.md#颜色'>颜色</a>。默认为黑色。" },
	{ "name": "font-size", "desc": "字体大小。" },
	{ "name": "font-name", "desc": "字体名。默认为系统字体。" },
	{ "name": "font-style", "desc": "字体样式。", "enum": ["ultra-light", "thin", "light", "normal", "medium", "bold", "heavy", "black", "italic", "bold-italic"] },
	{ "name": "alignment", "desc": "文字水平对齐方式。默认为 <code>left</code>。", "enum": ["left", "center", "right", "natural", "justify"] },
	{ "name": "vertical-alignment", "desc": "文字竖直对齐方式。默认为 <code>center</code>。", "enum": ["top", "center", "bottom"] },
	{ "name": "line-break-mode", "desc": "文字换行方式。默认为 <code>word</code>。", "enum": ["word", "char"] },
	{ "name": "truncation-mode", "desc": "文字省略方式。默认为 <code>truncating-tail</code>。", "enum": ["truncating-head", "truncating-middle", "truncating-tail", "none"] },
	{ "name": "lines", "desc": "最大行数。为 0 时，不限制行数。默认为 1。" },
	{ "name": "line-spacing", "desc": "行间距。" },
	{ "name": "kern", "desc": "字间距。需要注意文字的最右边也会有一个字距大小的空白，一般可以通过设置 <code>margin-right</code> 来修正。如：  <pre><code>\"kern\": 5,\n\"margin-right\": -5</code></pre>" },
	{ "name": "adjusts-font-size", "desc": "是否调整字号以适应控件的宽度，默认为<code>false</code>。" },
	{ "name": "mini-scale-factor", "desc": "与<code>adjusts-font-size</code>配合使用，设置一个字号调整的最小系数，设置为0时，字号会调整至内容能完全展示。" }
] %}

{% include "../templates/properties.md" %}

## 富文本

可以设置 `html-text` 属性来用 html 描述富文本。

需要注意 `&`、`<`、`>` 符号需要转义成 `&amp;`、`&lt;`、`&gt;`，否则整个文本都不能被正常解析。在表达式中使用时，需要给变量转义，如：`"html-text": "<b>${VZMistHTMLStringParser.htmlEncodedString(text)}</b>"`。

支持的特性如下：

- 粗体

	使用`<b>`, `<strong>`标签表示粗体文字

	`<b>bold</b>` <b>bold</b>

- 斜体

	使用`<i>`, `<em>`, `<dfn>`, `<cite>`标签表示斜体文字

	`<i>italic</i>` <i>italic</i>

- 等宽字体

	使用`<tt>`标签表示等宽字体

	`normal <tt>monospace</tt>` normal <tt>monospace</tt>

- 大号字体

	使用`<big>`标签使字体变大25%

	`normal <big>big</big>` normal <big style="font-size: larger">big</big>

- 小号字体

	使用`<big>`标签使字体变小20%

	`normal <small>small</small>` normal <small style="font-size: smaller">small</small>

- 字体

	使用`<font>`标签指定字体
	
	- `face` 字体名
	- `size` 字体尺寸，系统单位
	- `color` 字体[颜色](/basics/Style.md#颜色)

	`<font face="Times" size="20" color="red">Some Text</font>` <font face="Times" size="20px" color="red">Some Text</font>

- 下划线
	
	使用`<u>`标签添加下划线

	`<u>underline</u>` <u>underline</u>

- 删除线
	
	使用`<s>`标签添加删除线

	`<s>strikethrough</s>` <s>strikethrough</s>

- 标题

	使用`<h1>`, `<h2>`, `<h3>`, `<h4>`, `<h5>`, `<h6>`标签表示标题

- 段落与换行

	使用`<p>`标签表示段落，`<br>`标签表示换行。注意，这里的`<p>`不能使用单标签。

	`<p>段落1</p><p>段落2<br>换行</p>` <p>段落1</p><p>段落2<br>换行</p>

- 图片

	使用`<img>`标签插入图片，`src` 为图片名，只能使用本地图片，标签内的内容为图片不存在时的替代文本。

	`<img src="xx"/>`
