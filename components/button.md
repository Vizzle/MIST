# `button` 元素

按钮元素，可以设置按下时的文字颜色等

{% set properties = [
	{ "name": "title", "desc": "显示的文字。支持[状态](#button_state)。" },
	{ "name": "image", "desc": "显示的图片，只能为本地图片，图片固定显示在文字左边。支持[状态](#button_state)。" },
	{ "name": "background-image", "desc": "按钮背景图片，只能为本地图片，也可以设置为[颜色](color.html)。支持[状态](#button_state)。" },
	{ "name": "title-color", "desc": "文字[颜色](color.html)。默认为黑色。支持[状态](#button_state)。" },
	{ "name": "font-size", "desc": "字体大小。默认为17。" },
	{ "name": "font-name", "desc": "字体名。默认为系统字体。" },
	{ "name": "font-style", "desc": "字体样式。", "enum": ["ultra-light", "thin", "light", "normal", "medium", "bold", "heavy", "black", "italic", "bold-italic"] },
	{ "name": "enlarg-size", "desc": "放大按钮的点击区域。如：<p>  <i>\"enlarge-size\": 5</i>，上下左右各放大 5；  <i>\"enlarge-size\": [5, 10]</i>，左右放大 5，上下放大 10。" }
] %}

{% include "../templates/properties.md" %}

<a name="button_state"></a>
## 按钮状态

支持的状态：`normal`、`highlighted`、`disabled`、`selected`。  
按钮可以为不同状态设置不同的 `title`、`title-color`、`image`、`background-image`。  

示例：

```json
{
  "type": "button",
  "background-image": "white",
  "title": {
    "normal": "button",
    "highlighted": "clicked"
  }
}
```