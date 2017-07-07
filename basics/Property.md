# 属性

## 模版属性

模版包含以下属性：

{% set properties = [
	{ "name": "layout", "desc": "模版的布局描述，类型为元素" },
	{ "name": "controller", "desc": "模版关联的 <a href='Event.md#controller'><code>Controller</code></a> 类名" },
	{ "name": "state", "desc": "模版的初始<a href='State.md'>状态</a>" },
	{ "name": "data", "desc": "值为字典，用于对数据做一些处理或适配，这里的计算结果会追加到数据" },
  { "name": "styles", "desc": "样式表，定义一些可以被重复使用的样式，在元素中通过 <a href='#class'><code>class</code></a> 属性引用" },
	{ "name": "id", "desc": "给模版指定一个 id" },
	{ "name": "async-display", "desc": "是否启用异步渲染" }
] %}

{% include "../templates/properties.md" %}

## 元素属性

所有元素都支持如下的属性（自定义元素不能使用[样式](Style.md)属性）

{% set properties = [
	{ "name": "gone", "desc": "为 <code>true</code> 时，元素不显示，且不加入布局。" },
	{ "name": "repeat", "desc": "模版衍生机制。<code>repeat</code> 为元素重复的次数或重复的数组。注意：根节点元素使用 <code>repeat</code> 无效！<br><a href='#repeat属性'>详细说明</a>" },
	{ "name": "vars", "desc": "定义变量（宏），详见<a href='DataBinding.md#定义变量（宏）'>这里</a>。" },
  { "name": "class", "desc": "引用在 <a href='#styles'><code>styles</code></a> 中定义的样式。可以引用多个样式，用空格分开，靠后的样式覆盖前面的样式。" },
	{ "name": "style", "desc": "元素的<a href='Style.md'>样式</a>和<a href='Layout.md'>布局</a>属性" }
] %}

{% include "../templates/properties.md" %}

### 事件

所有元素（自定义元素除外）都支持如下的事件，事件的使用见[事件处理](Event.md)。

{% set properties = [
	{ "name": "on-tap", "desc": "元素被点击时触发" },
	{ "name": "on-display", "desc": "元素显示时触发。在列表中滑出可见区域再滑回来会重新触发" },
	{ "name": "on-create", "desc": "元素被创建时触发，此时还没显示" }
] %}

{% include "../templates/properties.md" %}

### `repeat`属性

值为数字时，表示要重复的次数，自动增加 `_index_` 变量表示当前重复项索引

值为数组时，表示要重复的数据，自动增加 `_item_` 和 `_idnex_` 表示当前重复项的数据和索引

<!--sec data-title="示例" data-id="section0" data-collapse=false ces-->

##### 1. 单层循环

<div style="margin:0; position:relative; display:flex; border-color:#aaa; width:320px; border-width:1px; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "><div style="flex-grow:1; padding:0; text-align:center; position:relative; display:flex; border-width:0; font-size:100%; box-sizing:border-box; margin:0; line-height:1.25em; background-color:white; border-style:solid; ">a</div>
<div style="flex-grow:1; padding:0; text-align:center; position:relative; display:flex; border-width:0; font-size:100%; box-sizing:border-box; margin:0; line-height:1.25em; background-color:#ddd; border-style:solid; ">b</div>
<div style="flex-grow:1; padding:0; text-align:center; position:relative; display:flex; border-width:0; font-size:100%; box-sizing:border-box; margin:0; line-height:1.25em; background-color:white; border-style:solid; ">c</div>
<div style="flex-grow:1;padding:0;text-align: center;position:relative;display:flex;border-width:0;font-size:100%;box-sizing:border-box;margin:0;line-height:1.25em;background-color:#ddd;border-style:solid;">d</div>
<div style="flex-grow:1; padding:0; text-align:center; position:relative; display:flex; border-width:0; font-size:100%; box-sizing:border-box; margin:0; line-height:1.25em; background-color:white; border-style:solid; ">e</div>
</div>

{% set code =
{
  "width": 320,
  "border-color": "#aaa",
  "border-width": 1,
  "children": [
    {
      "repeat": ["a", "b", "c", "d", "e"],
      "flex-grow": 1,
      "type": "text",
      "text": "${_item_}",
      "background-color": "${_index_ % 2 == 0 ? 'white' : '#ddd'}"
    }
  ]
}
%}
{% include "../templates/code.md" %}

##### 2. 多层循环

<div style="padding:0; border-width:0; position:relative; display:flex; width:200px; font-size:100%; box-sizing:border-box; margin:0; flex-direction:column; line-height:1.25em; height:200px; border-style:solid; "><div style="margin:0; position:relative; display:flex; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "><div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
</div>
<div style="margin:0; position:relative; display:flex; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "><div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
</div>
<div style="margin:0; position:relative; display:flex; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "><div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
</div>
<div style="margin:0; position:relative; display:flex; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "><div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
</div>
<div style="margin:0; position:relative; display:flex; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "><div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#aaa; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
<div style="margin:0; position:relative; display:flex; background-color:#ddd; flex-grow:1; border-width:0; font-size:100%; padding:0; line-height:1.25em; box-sizing:border-box; border-style:solid; "></div>
</div>
</div>

{% set code =
{
  "width": 200,
  "height": 200,
  "direction": "vertical",
  "children": [
    {
      "repeat": 5,
      "vars": {
        "i": "${_index_}"
      },
      "flex-grow": 1,
      "children": [
        {
          "repeat": 5,
          "flex-grow": 1,
          "background-color": "${(_index_ % 2) + (i % 2) == 1 ? '#aaa' : '#ddd'}"
        }
      ]
    }
  ]
}
%}
{% include "../templates/code.md" %}

<!--endsec-->
