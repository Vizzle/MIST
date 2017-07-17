# Sublime 插件

Mist 的 Sublime 插件提供属性提示、快速跳转等功能，提高开发效率。

**已不再更新，推荐使用 [VSCode 插件](VSCode.md)**

## 安装

1. 首先确保你使用的 Sublime Text 版本不低于 3092，如果不是请在[这里](http://www.sublimetext.com/3)安装最新版。
2. 可以直接使用 [PackageControl](https://packagecontrol.io) 搜索 `MIST` 安装，或者从 [github](https://github.com/Sleen/SublimePluginForMIST) 上下载，详见[这里](https://github.com/Sleen/SublimePluginForMIST#installation)。

## 更新

- `PackageControl` 使用 `Package Control: Upgrade Package` 命令更新所有插件。
- 如果是手动安装的，则从 github 拉取最新代码即可。

## 使用

编写 MIST 模版时，如果是 `.mist` 文件，应该会自动设置为 MIST 语法。如果没有，按 `command` + `shift` + `P` 打开命令面板，键入 `MIST`，选择 `Set Syntax: MIST` 项设置为 MIST 语法。

## 代码高亮
插件的代码高亮相比于 Sublime Text 原生的 Json 代码高亮做了一些改进，主要有以下几点：

1. 字典的 key 与其它字符串颜色区分开
2. 字符串中的数字高亮，如 "10", "50%", "1px"
3. 对字符串中的表达式进行高亮
4. 对 Json 语法错误高亮

<!--下面是两者的对比

<img src="highlight.png" width="768px"></img>-->

## 代码提示

<video width="574px" autoplay loop>
  <source src="https://os.alipayobjects.com/rmsportal/WtAYTfNtdsMBABPqjyaZ.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

_演示中是比较老的模版格式_

## Quick Menu

在模版文件中按 `command` + `shift` + `M` 可以打开菜单，根据当前文件类型可能出现以下菜单项：

* `Jump To Data File` 从模版文件跳转到对应的数据文件（.json），并滚动到引用该模版的位置。如果找到多个文件或位置使用该模版，会弹出选择框。
* `Jump To Template File` 跳转到对应的模版文件（.mist）。如果当前是 JS 文件，则跳转到相同文件名的模版文件；如果当前是数据文件，则跳转到光标处所对应的模版文件。
* `Jump To JS File` 从模版文件跳转到对应的 JS 文件（.js）
* `List All Blocks` 列出当前数据文件中包含的所有 block。
