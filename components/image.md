# `image` 元素

图片元素，可展示本地图片和网络图片。网络图片自动缓存。  
展示本地图片时，使用 `image` 属性，如 `"image": "O2O.bundle/arrow"`。  
展示网络图片时，使用 `image-url` 指定网络图片，`image` 指定加载中显示的图片，`error-image` 指定下载失败时显示的图片。

{% set properties = [
	{ "name": "image", "desc": "显示的图片名，只能使用本地图片。规则同 `[UIImage imageNamed:]`。" },
	{ "name": "image-url", "desc": "网络图片地址。可以使用 `url地址` 和 `cloudId`。" },
	{ "name": "error-image", "desc": "网络图片下载失败时显示的图片，只能使用本地图片，如果没有指定则显示 `image`。**注意**：`image-url` 为空时，将会使用 `image` 而不是 `error-image`。" },
	{ "name": "content-mode", "desc": "图片缩放模式。", "enum": ["center", "scale-to-fill", "scale-aspect-fit", "scale-aspect-fill"] },
	{ "name": "download-scale", "desc": "使用 `cloudId` 下载图片时，会按照图片框尺寸下载，但如果图片框尺寸跟图片原始尺寸的宽高比不同，下载的图片会比期望尺寸小（类似`UIViewContentModeScaleAspectFit`），图片就会模糊，这种情况下可以指定一个大一点的 `download-scale`，比如 1.3。默认为 1。", "o2o": true },
	{ "name": "on-complete", "desc": "图片下载完成时的回调[事件](../event.html)。" },
	{ "name": "business", "desc": "图片下载需要传入 business key。可以在重写 `O2OMistListItem` 的 `- (NSString *)defaultBusiness` 来为所有图片设置一个相同的 key。", "o2o": true }
] %}

{% include "../properties_template.md" %}
