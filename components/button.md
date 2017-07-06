# `button` 元素

按钮元素，可以设置按下时的文字颜色等

## 属性

{% set properties = [
	{ "name": "title", "desc": "显示的文字。支持<a href='#按钮状态'>状态</a>。" },
	{ "name": "image", "desc": "显示的图片，只能为本地图片，图片固定显示在文字左边。支持<a href='#按钮状态'>状态</a>。" },
	{ "name": "background-image", "desc": "按钮背景图片，只能为本地图片，也可以设置为<a href='../basics/Style.md#颜色'>颜色</a>。支持<a href='#按钮状态'>状态</a>。" },
	{ "name": "title-color", "desc": "文字<a href='../basics/Style.md#颜色'>颜色</a>。默认为黑色。支持<a href='#按钮状态'>状态</a>。" },
	{ "name": "font-size", "desc": "字体大小。默认为17。" },
	{ "name": "font-name", "desc": "字体名。默认为系统字体。" },
	{ "name": "font-style", "desc": "字体样式。", "enum": ["ultra-light", "thin", "light", "normal", "medium", "bold", "heavy", "black", "italic", "bold-italic"] },
	{ "name": "enlarg-size", "desc": "放大按钮的点击区域。如：<br>  <code>\"enlarge-size\": 5</code> 上下左右各放大 5<br> <code>\"enlarge-size\": [5, 10]</code> 左右放大 5，上下放大 10" }
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