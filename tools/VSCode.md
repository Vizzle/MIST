# VSCode 插件

> Visual Studio Code (简称 VS Code / VSC) 是一款免费开源的现代化轻量级代码编辑器，支持几乎所有主流的开发语言的语法高亮、智能代码补全、自定义热键、括号匹配、代码片段、代码对比 Diff、GIT 等特性，支持插件扩展，并针对网页开发和云端应用开发做了优化。软件跨平台支持 Win、Mac 以及 Linux，功能强大，运行流畅。[下载地址](https://code.visualstudio.com/)

Mist 的 Visual Studio Code 插件提供属性提示、Node树预览等功能，提高开发效率。

## 安装

直接在 VSCode 的扩展商店搜索 `MIST` 即可安装

## 更新

VSCode 默认会自动更新插件

## 使用

大部分功能需要编辑器语言设置为 `MIST` 才能使用，如果是 `.mist` 文件，会自动设置为 `MIST` 语言。

## 代码高亮

对模版中表达式进行语法高亮

## 代码提示

编写 Mist 模版时会根据上下文提示当前可用属性，鼠标移到属性名或枚举值上可以显示属性描述。

<video width="770px" controls style="border-radius:4px" autoplay loop>
  <source src="https://gw.alipayobjects.com/os/rmsportal/scfbArcHAZkpWhRSwIff.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

## 模版布局结构

在编辑 Mist 模版文件时，左侧的资源管理器里的 `MIST OUTLINE` 会显示模版的布局结构和 node 的一些关键信息，方便定位。点击节点可选中并跳转到对应的代码位置。

<img src="outline.jpg" width="372px"/>

## 注释

可以在模版中使用 `//` 和 `/* */` 添加注释，注释能被正常高亮、[格式化](#格式化)，并且在 `MIST OUTLINE` 中也会显示元素的注释。推荐在模版中多用注释，方便修改时快速定位元素。

## 格式化

在编辑器中右键选择 `Format Document` 可以格式化当前文档，也可使用快捷键 `⇧` `⌥` `F` 或自定义其它快捷键。

选中文本时右键选择 `Format Selection` 可格式化选中部分。

## 快速跳转

点击编辑器右上角的 <img src="show_data_icon.png" width="16px"/> `Show Data File` 按钮可以从模版文件跳转到对应的数据文件（.json），并滚动到引用该模版的位置。如果找到多个文件或位置使用该模版，会弹出选择框。

目前按照正则式匹配，并只在模版所在目录下查找 `.json` 文件，不一定能正确找到。

## 调试

点击编辑器右上角的 <img src="start_icon.png" width="14px"/> `Start Mist Debug Server` 按钮开启调试服务器，功能与 [mist-toolkit](MistToolkit.md) 的 `mist -s` 类似。开启后图标会变成停止图标，点击可以关闭服务器。

目前有个小问题是，使用过这个功能后模版文件夹下会自动添加一个 `.vscode` 文件夹，里面保存了 `Mist` 插件的配置文件，可以把这个文件夹添加到 `.gitignore` 里。
