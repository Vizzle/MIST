# 数据绑定

模版中可以使用[表达式](#表达式)进行数据绑定。

模版中除 key 以外所有地方都可以写表达式，表达式写在 `${}` 里。由于 json 结构的要求表达式只能写在字符串中，但表达式的计算结果不一定是字符串类型，如 `"a": "${2 > 1}"` 的结果为 `"a": true`。

一个字符串中也可以包含多个表达式，如 "文字${表达式1}文字${表达式2}文字"，这种情况下表达式结果会作为字符串替换到原始字符串中。

表达式中可以访问当前作用域中的变量。

## 表达式

### 数据类型
- <a id="string">**`string`**</a> 使用单引号或双引号限定，如：`"it's mine"`、`'"'`，转义规则跟 [json](http://json.org/) 一样（多一个`\'`）
- **`number`** 如：`123`、`1.23E-10`，规则跟 [json](http://json.org/) 一样
- **`boolean`** 值只能为 `true` 和 `false`
- <a id="null">**`null`**</a> 值只能为 `null` 或 `nil`
- <a id="array">**`array`**</a> 如：`[123, 'string', true]`
- <a id="dictionary">**`dictionary`**</a> 如：`{'key': 'value', 'key2': 123}`，**由于在模版中使用 `${}` 绑定表达式，因此表达式中不能直接写 `dictionary`。**
  
### 运算符
- 算术运算符
  * 支持 `+`, `-`, `*`, `/`, `%`
  * 支持一元运算符 `-`
  * 当`+`运算符的操作数中含有 [`string`](#string) 时，进行字符串拼接
- 比较运算符
  * 支持 `>`, `<`, `>=`, `<=`, `==`, `!=`
  * `>`, `<`, `>=`, `<=` 进行数值比较
  * `==`, `!=` 如果两个操作数都不为 [`null`](#null)，调用 `-[NSObject isEqual:]` 进行比较，否则进行数值比较
- 逻辑运算符
  * 支持 `&&`, `||`, `!`
- 条件表达式
  * 条件表达式 `?:`，如：`a > b ? a : b`
  * 支持省略形式，如：`a ?: b`
- 下标运算符
  * 运算符 `[]`，用于索引 [`array`](#array) 或 [`dictionary`](#dictionary) 的元素，如：`array[3]`, `dict['key']`

### 方法调用
- 方法调用规则类似 JSPatch，使用下划线`_`替换掉selector中的`:`，末尾的`:`可省略，下面展示了 Objective-C 调用对应的表示方法：
  * `str.length` → `str.length`
  * `[array addObject:@1]` → `array.addObject(1)`
  * `[str replace:@"a" with:@"b"]` → `str.replace_with('a', 'b')`
  * `[obj a_b:123]` → `obj.a__b(123)`
  * `[SomeClass classMethod]` → `SomeClass.classMethod`
  * `[VZTGlobalFunctions max:1 :2]` → `VZTGlobalFunctions.max(1, 2)`
- 注意，`.` 运算符不带参数时会优先尝试 [`dictionary`](#dictionary) 取值，可以在末尾加 `()` 显式指定调用函数，如：`array.count()`
- 可以用 Category 为一些基本类型增加扩展方法，增加的扩展方法为避免与其它 framework 冲突，最好加一个 `vzt_` 前缀，如：

  ```objc
  @implementation NSString (VZTExtension)
  - (NSString *)vzt_toUpper {
    return [self uppercaseString];
  }
  @end
  ```
  使用时可以省略 `vzt_` 前缀，如 `'abc'.toUpper`
- 预置了一些全局函数，如 `min`, `round`, `random` 等，详见 `VZTGlobalFunctions` 类。可以通过 category 为其扩展更多函数。
  * `max(a, b)`
  * `random()`
- 不支持调用参数类型包含结构体的方法

### 命名规则

变量或函数名称只能包含 大小写字母`A-Za-z`、数字`0-9`、下划线`_`，且不能以数字开始

### 注释

支持以 `//` 开始的行注释，和 `/*` 开始的块注释

### lambda 表达式

支持简单的 lambda 表达式，写法为 `参数 -> 返回值`，如：

```
list.filter(item -> item.length > 0)
```

## 变量

### 定义变量（宏）

在模版元素中可以用 [`vars`](Property.md#vars) 属性定义一些变量，这些变量只能在该作用域使用，重复的变量名会隐藏上层作用域的同名变量（即就近原则）。  
由于 json 中的 字典是无序的，所以在同一个 `vars` 中定义的变量不能使用在该层定义的其它变量，这种情况可以像下面这样定义成一个数组：

```json
"vars": [
    {
        "a": 1
    },
    {
        "b": "${a + 1}"
    }
]
```

### 预置变量

{% set properties = [
	{ "name": "_width_", "desc": "屏幕宽度" },
	{ "name": "_height_", "desc": "屏幕高度" }
] %}

{% include "../templates/properties.md" %}
