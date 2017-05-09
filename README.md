## MIST 文档

本项目是MIST的文档，使用[gitbook](https://www.gitbook.com/book/chenlb/gitbook-quick-start/details)构建，托管在[Github Pages](https://github.com/Vizzle/MIST-Document)上。

### 安装Gitbook

- 该文档使用Gitbook构建，使用NPM安装gitbook，安装Gitbook参考[Setup and Installation of GitBook](https://github.com/GitbookIO/gitbook/blob/master/docs/setup.md)

### 编写文档

- clone该项目，切到`doc`分支
- 执行命令：`gitbook install`
- 编写文档
- 预览命令：`gitbook serve`


### 部署

- 提交后执行部署脚本，将文档部署到Github Pages上：

```
npm run docs:publish

```

### License

MIT

### Q&A

- 问题通过Issue反馈
- 欢迎pull request