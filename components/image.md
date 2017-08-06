# `image` 元素

图片元素，可展示本地图片和网络图片。网络图片自动缓存。  
展示本地图片时，使用 `image` 属性，如 `"image": "O2O.bundle/arrow"`。  
展示网络图片时，使用 `image-url` 指定网络图片，`image` 指定加载中显示的图片，`error-image` 指定下载失败时显示的图片。

## 属性

{% set properties = [
	{ "name": "image", "desc": "显示的图片名，只能使用本地图片。规则同 <code>[UIImage imageNamed:]</code>。" },
	{ "name": "image-url", "desc": "网络图片地址。可以使用 <code>url地址</code> 和 <code>cloudId</code>。" },
	{ "name": "error-image", "desc": "网络图片下载失败时显示的图片，只能使用本地图片，如果没有指定则显示 <code>image</code>。<br>注意：<code>image-url</code> 为空时，将会使用 <code>image</code> 而不是 <code>error-image</code>。" },
	{ "name": "content-mode", "desc": "图片缩放模式，默认为 <code>scale-to-fill</code>。<br><code>center</code> 图片不缩放，居中显示。<br><code>scale-to-fill</code> 图片缩放至元素尺寸，不保留宽高比。<br><code>scale-aspect-fit</code> 图片按长边缩放，图片能完全显示，可能填不满元素。<br><code>scale-aspect-fill</code> 图片按短边缩放，图片能填满元素，可能显示不完全。", "enum": ["center", "scale-to-fill", "scale-aspect-fit", "scale-aspect-fill"] },
	{ "name": "download-scale", "desc": "使用 <code>cloudId</code> 下载图片时，会按照图片框尺寸下载，但如果图片框尺寸跟图片原始尺寸的宽高比不同，下载的图片会比期望尺寸小（类似<code>UIViewContentModeScaleAspectFit</code>），图片就会模糊，这种情况下可以指定一个大一点的 <code>download-scale</code>，比如 1.3。默认为 1。", "o2o": true },
	{ "name": "business", "desc": "图片下载需要传入 business key。可以在重写 <code>O2OMistListItem</code> 的 <code>- (NSString *)defaultBusiness</code> 来为所有图片设置一个相同的 key。", "o2o": true }
] %}

{% include "../templates/properties.md" %}

## 事件

{% set properties = [
	{ "name": "on-complete", "desc": "图片下载完成时触发" }
] %}

{% include "../templates/properties.md" %}
