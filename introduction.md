## MIST是什么

MIST是口碑客户端研发的一套高性能的动态模板引擎，它使用JSON格式描述页面(模板)结构，同时支持CSS样式表达和动态脚本(JS等)嵌入。由于模板文件可随服务端下发，因此客户端可具备动态更新页面的能力；和`React Native`或`Weex`不同，MIST面向客户端开发人员，从设计上保证Native原生的性能和体验；此外，MIST还提供了一种全新的UI开发方式，可极大提高iOS端的页面开发效率


## MIST特点

- **FlexBox布局算法**：MIST内部实现了CSS3 FlexBox的标准布局算法，作为模板布局的核心能力；对比现有的FlexBox算法(RN, Weex), MIST支持的属性更完整，灵活性更高
；算法采用C语言实现，无运行时的性能损耗

- **高效的Parser**：MIST内部实现了一套功能完备的语法解释器，支持基本的数学运算、逻辑运算、比较运算、条件表达式等；此外，MIST还支持OC类方法的调用作为对Native通信能力的补充

- **UI异步绘制**：MIST对UI底层渲染做了深度优化，对模板内的UI元素支持整体的异步光栅化绘制，可以极大的提升FPS，使页面具有更流畅的滑动体验

- **React**：MIST将React.js的思想移植到了客户端，使用Objective-C++实现了一套Native版本的React。因此MIST底层也具备和React相似的运作机制，包括Virtual Dom结构，类似React的state处理，使用Immutable数据和One-Way data flow。MIST模板在此之上进行了一层抽象，使开发者不需要理解上述概念，也不需要关心具体的实现细节，降低上手门槛

- **支持脚本扩展**：为了弥补模板和Native通信能力的不足，模板支持脚本能力的扩展，例如JSPatch，Wax等开源解决方案


## MIST应用情况

MIST从2016年6月开始应用在支付宝口碑业务中，顺利支撑了客户端日常项目迭代，通过了千万UV的考验，目前已经趋于稳定；在双12大促中，口碑主会场采用MIST构建，快速支撑需求发布和突发应急；截止到目前，累计动态发布35+次，推送模板数量55+，成功率稳定在99%


## MIST开发模式

<embed src="https://os.alipayobjects.com/rmsportal/xZYDLLqUaAdxoJATpljU.mp4" width="100%" height="600" align="middle" allowScriptAccess="never" allowFullScreen="true"></embed>


## 关于MIST的后端

作为端到端动态化解决方案，MIST后端也做了很多工作，包括模板管理，页面可视化配置等等，由于该文档面向客户端部分，后端部分的内容不在这里展开


## 更多参考：

- [了解Flexlayout](https://www.atatech.org/articles/50486?msgid=1105141)
- [了解异步渲染](https://www.atatech.org/articles/51091?msgid=1321446)
- [MIST在双12大促中的应用](https://www.atatech.org/articles/70258)


