//
//  LayoutPerformanceTests.m
//  MIST
//
//  Created by Sleen on 2017/9/5.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <VZFlexLayout/YogaBridge.h>
#import "VZFNodeInternal.h"
#import "VZFNode+Template.h"
#import "VZTExpressionContext.h"
#import <VZFlexLayout/VZFlexNode.h>

extern "C" {

#import <VZFlexLayout/Yoga.h>

extern YGNodeRef convertToYogaNode(FlexNode* flexNode, YGConfigRef config);

typedef struct {
    float viewportWidth;
    float viewportHeight;
    float scale;
} _FlexLayoutContext;

typedef struct FlexLayoutContext* FlexLayoutContextRef;

void YGNodeClearCachesRecursive(const YGNodeRef node) {
    int *nextCachedMeasurementsIndex = (int *)((char *)node + 536);
    *nextCachedMeasurementsIndex = 0;
    float *measuredDimensions = (float *)((char *)node + 924);
    measuredDimensions[0] = measuredDimensions[1] = NAN;
    float *availableDimensions = measuredDimensions + 2;
    availableDimensions[0] = availableDimensions[1] = 0;
    YGMeasureMode *measureModes = (YGMeasureMode *)(availableDimensions + 2);
    measureModes[0] = measureModes[1] = (YGMeasureMode)-1;
    float *computedDimensions = (float *)(measureModes + 2);
    computedDimensions[0] = computedDimensions[1] = -1;

    for (int i=0;i<YGNodeGetChildCount(node);i++) {
        YGNodeClearCachesRecursive(YGNodeGetChild(node, i));
    }
}

}

#define NODE_FROM_TEXT(text) \
({ \
    VZMist *mist = [VZMist sharedInstance]; \
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[text dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]; \
    VZMistTemplate *mistTemplate = [[VZMistTemplate alloc] initWithTemplateId:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] content:dict mistInstance:mist]; \
    [VZFNode nodeFromTemplate:mistTemplate data:[VZTExpressionContext new] item:nil mistInstance:mist]; \
})

#define MeasureLayout(text) \
    [self measureMetrics:[[self class] defaultPerformanceMetrics] automaticallyStartMeasuring:NO forBlock:^{ \
        VZFNode *node = NODE_FROM_TEXT(text); \
        Ivar _flex_node_IVar = class_getInstanceVariable([VZFlexNode class], "_flex_node"); \
        FlexNode *flexNode = (__bridge FlexNode *)object_getIvar(node.flexNode, _flex_node_IVar); \
        float screenWidth = [UIScreen mainScreen].bounds.size.width; \
        float screenScale = [UIScreen mainScreen].scale; \
        [self startMeasuring]; \
        Flex_layout(flexNode, screenWidth, FlexUndefined, screenScale); \
        [self stopMeasuring]; \
    }];

#define MeasureLayoutYoga(text) \
    _FlexLayoutContext context; \
    context.viewportWidth = [UIScreen mainScreen].bounds.size.width; \
    context.viewportHeight = 0; \
    context.scale = [UIScreen mainScreen].scale; \
\
    YGConfigRef config = YGConfigNew(); \
    YGConfigSetPointScaleFactor(config, context.scale); \
    YGConfigSetContext(config, &context); \
\
    [self measureMetrics:[[self class] defaultPerformanceMetrics] automaticallyStartMeasuring:NO forBlock:^{ \
        VZFNode *node = NODE_FROM_TEXT(text); \
        Ivar _flex_node_IVar = class_getInstanceVariable([VZFlexNode class], "_flex_node"); \
        FlexNode *flexNode = (__bridge FlexNode *)object_getIvar(node.flexNode, _flex_node_IVar); \
\
        YGNodeRef yogaNode = convertToYogaNode(flexNode, config); \
        [self startMeasuring]; \
        YGNodeCalculateLayout(yogaNode, context.viewportWidth, YGUndefined, YGDirectionLTR); \
        [self stopMeasuring]; \
        YGNodeFreeRecursive(yogaNode); \
    }]; \
    YGConfigFree(config);


NSString *simpleLayout1 = @R"(
{
  "layout": {
    "children": [
      {
        "repeat": 5,
        "style": {
          "margin": 5,
          "width": 50,
          "height": 50,
          "background-color": "blue"
        }
      }
    ]
  }
})";

NSString *simpleLayout2 = @R"(
{
  "layout": {
    "style": {
      "wrap": "wrap"
    },
    "children": [
      {
        "repeat": 50,
        "style": {
          "margin": 5,
          "width": 50,
          "height": 50,
          "background-color": "blue"
        }
      }
    ]
  }
})";

NSString *simpleLayout3 = @R"(
{
  "styles": {
    "title": {
      "font-style": "bold",
      "font-size": 15,
      "padding-top": 15,
      "padding-left": 10,
      "color": "#666",
      "background-color": "#ddd"
    },
    "subtitle": {
      "lines": 0,
      "font-size": 13,
      "padding-bottom": 4,
      "padding-left": 10,
      "color": "#999",
      "background-color": "#ddd"
    }
  },
  "layout": {
    "vars": {
      "themeColor": "#E24810"
    },
    "style": {
      "direction": "vertical"
    },
    "children": [
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "设置尺寸"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "indicator 根据布局得到的尺寸进行绘制"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "padding-top": 10,
              "padding-bottom": 10,
              "align-items": "center",
              "justify-content": "center",
              "spacing": 3,
              "background-color": "${themeColor}"
            },
            "children": [
              {
                "repeat": 8,
                "type": "indicator",
                "style": {
                  "width": "${10 + _index_ * 2}",
                  "height": "${10 + _index_ * 2}"
                }
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "设置颜色"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "使用 <b>color</b> 属性设置 indicator 的颜色。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "vars": {
              "colors": ["red", "blue", "#CD661D", "black", "gray"]
            },
            "style": {
              "padding-top": 10,
              "padding-bottom": 10,
              "align-items": "center",
              "justify-content": "center",
              "spacing": 3
            },
            "children": [
              {
                "repeat": "${colors.count}",
                "type": "indicator",
                "style": {
                  "color": "${colors[_index_]}"
                }
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "示例"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": ""
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "user-interaction-enabled": "${!state.loading}",
              "margin": 10,
              "padding": 10,
              "background-color": "${state.loading ? themeColor.toColor.colorWithAlphaComponent(0.7) : themeColor}",
              "clip": true,
              "corner-radius": 3,
              "align-items": "center",
              "justify-content": "center",
              "spacing": 3
            },
            "on-tap": {
              "load": ""
            },
            "children": [
              {
                "type": "text",
                "style": {
                  "text": "${state.loading ? '加载中' : '点我点我'}",
                  "color": "white",
                  "font-size": 18
                }
              },
              {
                "gone": "${!state.loading}",
                "type": "indicator",
                "style": {
                  "width": 18,
                  "height": 18
                }
              }
            ]
          }
        ]
      },
      {
        "style": {
          "height": "1px",
          "background-color": "#888"
        }
      }
    ]
  }
})";

NSString *complexLayout1 = @R"(
{
  "styles": {
    "title": {
      "font-style": "bold",
      "font-size": 15,
      "padding-top": 15,
      "padding-left": 10,
      "color": "#666",
      "background-color": "#ddd"
    },
    "subtitle": {
      "lines": 0,
      "font-size": 13,
      "padding-bottom": 4,
      "padding-left": 10,
      "color": "#999",
      "background-color": "#ddd"
    }
  },
  "layout": {
    "vars": {
      "short_text": "Some test text",
      "long_text": "Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "very_long_text": "Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
    },
    "style": {
      "direction": "vertical"
    },
    "children": [
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "alignment"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "文本水平对齐方式。默认为 <i>left</i>。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "background-color": "#e5e5e5",
              "spacing": 2
            },
            "vars": {
              "items": [
                {
                  "text": "${short_text}",
                  "alignment": "left"
                },
                {
                  "text": "${short_text}",
                  "alignment": "center"
                },
                {
                  "text": "${short_text}",
                  "alignment": "right"
                },
                {
                  "text": "${very_long_text}",
                  "alignment": "justify"
                }
              ]
            },
            "children": [
              {
                "repeat": "${items.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${items[_index_].alignment}",
                      "width": 80,
                      "flex-shrink": 0,
                      "font-size": 15,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "flex-grow": 1,
                      "text": "${items[_index_].text}",
                      "background-color": "white",
                      "lines": 0,
                      "padding": 8,
                      "alignment": "${items[_index_].alignment}"
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "vertical-alignment"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "文本竖直对齐方式。默认为 <i>center</i>。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "values": ["top", "center", "bottom"]
            },
            "children": [
              {
                "repeat": "${values.count}",
                "style": {
                  "direction": "vertical",
                  "flex-grow": 1
                },
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${values[_index_]}",
                      "height": 30,
                      "flex-shrink": 0,
                      "font-size": 15,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "text": "${short_text}",
                      "background-color": "white",
                      "lines": 0,
                      "padding": 8,
                      "height": 100,
                      "alignment": "center",
                      "vertical-alignment": "${values[_index_]}"
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "line-break-mode"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "换行方式。默认为 <i>word</i>。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "values": ["word", "char"]
            },
            "children": [
              {
                "repeat": "${values.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${values[_index_]}",
                      "width": 80,
                      "flex-shrink": 0,
                      "font-size": 15,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "text": "${long_text}",
                      "background-color": "white",
                      "lines": 0,
                      "padding": 10,
                      "line-break-mode": "${values[_index_]}"
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "truncation-mode"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "文本显示不下时的省略方式。默认为 <i>truncating-tail</i>。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "values": ["truncating-head", "truncating-middle", "truncating-tail", "clip", "none"]
            },
            "children": [
              {
                "repeat": "${values.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${values[_index_]}",
                      "width": 140,
                      "flex-shrink": 0,
                      "font-size": 15,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "text": "${long_text}",
                      "background-color": "white",
                      "padding": 8,
                      "truncation-mode": "${values[_index_]}"
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "font-style"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "字体样式，注意并不是所有字体都支持这些样式。默认为 <i>normal</i>。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "values": ["ultra-light", "thin", "light", "normal", "medium", "bold", "heavy", "black", "italic", "bold-italic"]
            },
            "children": [
              {
                "repeat": "${values.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${values[_index_]}",
                      "width": 110,
                      "flex-shrink": 0,
                      "font-size": 15,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "flex-grow": 1,
                      "text": "${short_text}",
                      "font-style": "${values[_index_]}",
                      "background-color": "white",
                      "padding": 6,
                      "alignment": "center"
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "font-name"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "字体名称。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "values": ["American Typewriter", "Papyrus", "Marker Felt", "Zapfino"]
            },
            "children": [
              {
                "repeat": "${values.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${values[_index_]}",
                      "width": 160,
                      "flex-shrink": 0,
                      "font-size": 14,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "flex-grow": 1,
                      "text": "${short_text}",
                      "font-name": "${values[_index_]}",
                      "background-color": "white",
                      "padding": 6,
                      "alignment": "center"
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "lines"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "最大行数，超出后省略。默认为 <i>1</i>。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "values": [0, 1, 2]
            },
            "children": [
              {
                "repeat": "${values.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${values[_index_]}",
                      "width": 80,
                      "flex-shrink": 0,
                      "font-size": 14,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "flex-grow": 1,
                      "text": "${long_text}",
                      "lines": "${values[_index_]}",
                      "background-color": "white",
                      "padding": 6
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "line-spacing"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "行间距。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "values": [0, 5, 10, -5]
            },
            "children": [
              {
                "repeat": "${values.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${values[_index_]}",
                      "width": 80,
                      "flex-shrink": 0,
                      "font-size": 14,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "flex-grow": 1,
                      "text": "${long_text}",
                      "lines": 0,
                      "line-spacing": "${values[_index_]}",
                      "background-color": "white",
                      "padding": 6
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "kern"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "字间距。需要注意文字的最右边也会有一个字距大小的空白，一般可以通过设置 <i>margin-right</i> 来修正。如：<p>\"kern\": 5,<br>\"margin-right\": -5</p>"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "values": [0, 1, 2, -1]
            },
            "children": [
              {
                "repeat": "${values.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${values[_index_]}",
                      "width": 80,
                      "flex-shrink": 0,
                      "font-size": 14,
                      "alignment": "center",
                      "background-color": "#f4f4f4"
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "flex-grow": 1,
                      "text": "${short_text}",
                      "lines": 0,
                      "kern": "${values[_index_]}",
                      "background-color": "white",
                      "padding": 6
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "adjusts-font-size"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "文字显示不下时自动缩小字体。可以用 <b>mini-scale-factor</b> 设置最小缩小倍数，<b>baseline-adjustment</b> 设置缩小时的对齐方式。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "texts": ["1234", "1234567", "1234567890123"]
            },
            "children": [
              {
                "repeat": "${texts.count}",
                "type": "text",
                "style": {
                  "width": "33%",
                  "flex-grow": 1,
                  "text": "${texts[_index_]}",
                  "font-size": 40,
                  "adjusts-font-size": true,
                  "mini-scale-factor": 0.4,
                  "alignment": "center",
                  "background-color": "white",
                  "padding": 6
                }
              }
            ]
          }
        ]
      },
      {
        "style": {
          "direction": "vertical"
        },
        "children": [
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "type": "text",
            "class": "title",
            "style": {
              "text": "html-text"
            }
          },
          {
            "type": "text",
            "class": "subtitle",
            "style": {
              "html-text": "使用 html 表示的富文本。"
            }
          },
          {
            "style": {
              "height": "1px",
              "background-color": "#888"
            }
          },
          {
            "style": {
              "direction": "vertical",
              "spacing": 2,
              "background-color": "#e5e5e5"
            },
            "vars": {
              "htmls": [
                "this is <font color='red'>red</font>",
                "<b>bold</b> <i>italic</i> <s>strikethrough</s> <u>underline</u>",
                "normal <big>big</big> <small>small</small>",
                "<h2>Lorem ipsum</h2>\n<br><font size='10'><i>${long_text}</i></font>",
                "&gt;_&lt;",
                "<img src='mist.bundle/icon'></img><br><font size='20' color='#E24810'><b>Mist</b></font>"
              ]
            },
            "children": [
              {
                "repeat": "${htmls.count}",
                "children": [
                  {
                    "type": "text",
                    "style": {
                      "text": "${htmls[_index_]}",
                      "width": "50%",
                      "lines": 0,
                      "flex-shrink": 0,
                      "font-size": 11,
                      "background-color": "#f4f4f4",
                      "padding": 6
                    }
                  },
                  {
                    "type": "text",
                    "style": {
                      "flex-grow": 1,
                      "html-text": "${htmls[_index_]}",
                      "lines": 0,
                      "background-color": "white",
                      "padding": 6
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "height": "1px",
          "background-color": "#888"
        }
      }
    ]
  }
})";

NSString *complexLayout2 = @R"(
{
  "state": {
    "itemsCount": 12,
    "selected": {
      "wrap": 1,
      "height": 2,
      "clip": 1,
      "flex-shrink": 1
    },
    "selectedTab": 0
  },
  "styles": {
    "button": {
      "width": 20,
      "height": 20,
      "font-style": "bold",
      "title-color": {
        "normal": "#E24810",
        "highlighted": "white",
        "disabled": "#aaa"
      },
      "background-image": {
        "normal": "white",
        "highlighted": "#E24810"
      },
      "clip": true,
      "border-width": 1,
      "border-color": "#E24810",
      "corner-radius": 3
    }
  },
  "layout": {
    "vars": {
      "themeColor": "#E24810",
      "items": [[100, 18], [50, 20], [80, 14], [130, 23], [70, 17], [60, 26], [80, 19], [50, 21], [80, 23], [70, 18], [80, 20]],
      "map": {
        "direction": ["horizontal", "vertical", "horizontal-reverse", "vertical-reverse"],
        "wrap": ["nowrap", "wrap", "wrap-reverse"],
        "align-items": ["stretch", "start", "center", "end", "baseline"],
        "justify-content": ["start", "center", "end", "space-between", "space-around"],
        "align-content": ["stretch", "start", "center", "end"],
        "lines": ["0", "1", "2", "3"],
        "items-per-line": ["0", "1", "2", "3", "4", "5"],
        "height": ["auto", "60", "120", "180", "240"],
        "clip": ["true", "false"],
        "flex-basis": ["auto", "content", "0", "20", "40", "80"],
        "flex-grow": ["0", "1"],
        "flex-shrink": ["0", "1"]
      },
      "tabs": [
        {
          "text": "容器属性",
          "attrs": ["direction", "wrap", "align-items", "justify-content", "align-content", "lines", "items-per-line", "height"]
        },
        {
          "text": "子元素属性",
          "attrs": ["clip", "flex-grow", "flex-shrink", "flex-basis"]
        }
      ]
    },
    "style": {
      "direction": "vertical"
    },
    "children": [
      {
        "style": {
          "spacing": 2,
          "line-spacing": 2,
          "height": "${map['height'][state.selected['height']]}",
          "direction": "${map['direction'][state.selected['direction']]}",
          "justify-content": "${map['justify-content'][state.selected['justify-content']]}",
          "align-content": "${map['align-content'][state.selected['align-content']]}",
          "align-items": "${map['align-items'][state.selected['align-items']]}",
          "wrap": "${map['wrap'][state.selected['wrap']]}",
          "lines": "${map['lines'][state.selected['lines']]}",
          "items-per-line": "${map['items-per-line'][state.selected['items-per-line']]}"
        },
        "children": [
          {
            "repeat": "${state.itemsCount}",
            "vars": {
              "item": "${items[_index_%items.count]}"
            },
            "type": "text",
            "style": {
              "text": "${_index_ + 1}",
              "width": "${item[0]}",
              "font-size": "${item[1]}",
              "clip": "${map['clip'][state.selected['clip']].boolValue}",
              "flex-grow": "${map['flex-grow'][state.selected['flex-grow']]}",
              "flex-shrink": "${map['flex-shrink'][state.selected['flex-shrink']]}",
              "flex-basis": "${map['flex-basis'][state.selected['flex-basis']]}",
              "background-color": "blue",
              "color": "white",
              "alignment": "center"
            }
          }
        ]
      },
      {
        "style": {
          "background-color": "#ddd",
          "padding-left": 10,
          "padding-top": 4
        },
        "children": [
          {
            "type": "text",
            "style": {
              "text": "元素个数",
              "font-size": 12,
              "color": "#666",
              "margin-right": 8
            }
          },
          {
            "type": "button",
            "class": "button",
            "style": {
              "title": "−",
              "properties": {
                "enabled": "${state.itemsCount > 0}"
              }
            },
            "on-tap": {
              "updateState:": {
                "itemsCount": "${state.itemsCount - 1}"
              }
            }
          },
          {
            "type": "text",
            "style": {
              "text": "${state.itemsCount}",
              "width": 30,
              "alignment": "center"
            }
          },
          {
            "type": "button",
            "class": "button",
            "style": {
              "title": "+"
            },
            "on-tap": {
              "updateState:": {
                "itemsCount": "${state.itemsCount + 1}"
              }
            }
          }
        ]
      },
      {
        "style": {
          "background-color": "#ddd",
          "padding-top": 12,
          "padding-bottom": 8,
          "justify-content": "center"
        },
        "children": [
          {
            "style": {
              "corner-radius": 5,
              "border-color": "${themeColor}",
              "border-width": 1,
              "spacing": 1,
              "background-color": "${themeColor}",
              "clip": true
            },
            "children": [
              {
                "vars": {
                  "selected": "${_index_ == state.selectedTab}"
                },
                "repeat": "${tabs.count}",
                "type": "button",
                "style": {
                  "height": 30,
                  "title": "${tabs[_index_].text}",
                  "title-color": "${selected ? 'white' : themeColor}",
                  "font-style": "${selected ? 'bold' : 'normal'}",
                  "padding": 10,
                  "background-color": "${selected ? themeColor : 'white'}"
                },
                "on-tap": {
                  "updateState:": {
                    "selectedTab": "${_index_}"
                  }
                }
              }
            ]
          }
        ]
      },
      {
        "style": {
          "height": "1px",
          "background-color": "${themeColor}"
        }
      },
      {
        "vars": {
          "attrs": "${tabs[state.selectedTab].attrs}"
        },
        "style": {
          "direction": "vertical",
          "spacing": 6,
          "background-color": "#eee"
        },
        "children": [
          {
            "repeat": "${attrs.count}",
            "vars": {
              "attr": "${attrs[_index_]}",
              "values": "${map[attrs[_index_]]}"
            },
            "style": {
              "align-items": "start"
            },
            "children": [
              {
                "type": "text",
                "style": {
                  "width": 100,
                  "adjusts-font-size": true,
                  "height": 30,
                  "flex-shrink": 0,
                  "text": "${attr}",
                  "padding": 6,
                  "font-style": "bold",
                  "alignment": "right"
                }
              },
              {
                "style": {
                  "wrap": "wrap",
                  "spacing": 1
                },
                "children": [
                  {
                    "repeat": "${values.count}",
                    "vars": {
                      "selected": "${_index_ == state.selected[attr]}"
                    },
                    "type": "button",
                    "style": {
                      "height": 30,
                      "title": "${values[_index_]}",
                      "title-color": "${selected ? 'white' : themeColor}",
                      "padding": 6,
                      "background-color": "${selected ? themeColor : nil}"
                    },
                    "on-tap": {
                      "updateState:": {
                        "selected": "${state.selected.set_value(attr, _index_)}"
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "style": {
          "height": "1px",
          "background-color": "${themeColor}"
        }
      }
    ]
  }
})";

NSString *complexLayout3 = @R"a(
{
  "identifier": "home_pop_eye",
  "controller": "O2OIndexPopEyeTemplateController",
  "layout": {
    "vars": [{
        "subTitle": "此时此刻，你身边最火的店",
        "titleImage": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED",
        "tabList": [
          {
            "active": false,
            "catId": "cat1",
            "extendInfo": {},
            "showTitle": "商家秀",
            "title": "此时此刻，「西溪印象城」发现不一样的Mall",
            "modelList": [
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M28",
                    "data": {
                      "imgs": [
                        "CMHMXWtrRwielGtRVKyPVAAAACMAAQED",
                        "I2HYBt2JQRKANJlMNTzHegAAACMAAQED",
                        "ldBidMHkRQ2zPyz9YEU4vAAAACMAAQED",
                        "3Jg4EZQLRp20WyEOaGbvjgAAACMAAQED"
                      ]
                    },
                    "type": "show"
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 93,
                "mark1": "https://zos.alipayobjects.com/cdp/xDORIARqiGZaJCnhiRaO.png",
                "title": "弄堂里1(西溪印象城店)弄堂里1(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "sub1": "人均100元",
                "sub2": "100m",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M22",
                    "data": {
                      "tags": [
                        "味道很吃不错",
                        "聚会好地",
                        "方便",
                        "超好吃",
                        "一起去",
                        "美味"
                      ],
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "desc": "食客推荐"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 92,
                "title": "外婆家1(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M23",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "desc": "优惠预订",
                      "cnt": "周末黄金档时段，当前可预订"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 89,
                "title": "网鱼网咖1(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M27",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "title": "进店优惠",
                      "digit": "9.5",
                      "desc": "折",
                      "name": "全场折扣券"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 87,
                "title": "麦当劳1(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M27",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "title": "进店优惠",
                      "digit": "9.5",
                      "desc": "折",
                      "name": "全场折扣券"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 84,
                "title": "屈臣氏1(西溪印象城店)",
                "titleColor": "#E51C23"
              }
            ],
            "name": "商圈"
          },
          {
            "active": false,
            "catId": "cat2",
            "extendInfo": {},
            "title": "此时此刻，美食不可负",
            "modelList": [
              {
                "cardData": [
                  {
                    "blockId": "M29",
                    "data": {
                      "img": "CMHMXWtrRwielGtRVKyPVAAAACMAAQED"
                    }
                  }
                ]
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M22",
                    "data": {
                      "tags": [
                        "味道很吃不错",
                        "聚会好地",
                        "方便",
                        "超好吃",
                        "一起去",
                        "美味"
                      ],
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "desc": "食客推荐"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 92,
                "title": "外婆家2(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M23",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "desc": "优惠预订",
                      "cnt": "周末黄金档时段，当前可预订"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 89,
                "title": "网鱼网咖2(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M27",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "title": "进店优惠",
                      "digit": "9.5",
                      "desc": "折",
                      "name": "全场折扣券"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 87,
                "title": "麦当劳2(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M27",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "title": "进店优惠",
                      "digit": "9.5",
                      "desc": "折",
                      "name": "全场折扣券"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 84,
                "title": "屈臣氏2(西溪印象城店)",
                "titleColor": "#E51C23"
              }
            ],
            "name": "美食"
          },
          {
            "active": false,
            "catId": "cat3",
            "extendInfo": {},
            "title": "",
            "modelList": [
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "sub1": "人均100元",
                    "sub2": "100m",
                    "blockId": "M25",
                    "data": {
                      "tags": [
                        "味道很吃不错",
                        "聚会好地",
                        "方便",
                        "超好吃",
                        "一起去",
                        "美味"
                      ],
                      "icon": "TvuWkJ29T9CjzLJeuEchggAAACMAAQED",
                      "desc": "商家印象"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 93,
                "title": "弄堂里2(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M22",
                    "data": {
                      "tags": [
                        "味道很吃不错",
                        "聚会好地",
                        "方便",
                        "超好吃",
                        "一起去",
                        "美味"
                      ],
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "desc": "食客推荐"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 92,
                "title": "外婆家2(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M23",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "desc": "优惠预订",
                      "cnt": "周末黄金档时段，当前可预订"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 89,
                "title": "网鱼网咖2(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M27",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "title": "进店优惠",
                      "digit": "9.5",
                      "desc": "折",
                      "name": "全场折扣券"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 87,
                "title": "麦当劳2(西溪印象城店)",
                "titleColor": "#E51C23"
              },
              {
                "bodyColor": "#EF3A3A",
                "cardData": [
                  {
                    "blockId": "M11",
                    "data": {
                      "img": "BAzWmbhyRyOukR1iGXOo_gAAACMAAQED"
                    },
                    "type": "pic"
                  },
                  {
                    "blockId": "M27",
                    "data": {
                      "icon": "B1mJ-8SiRHGpgzyQ6sIrkgAAACMAAQED",
                      "title": "进店优惠",
                      "digit": "9.5",
                      "desc": "折",
                      "name": "全场折扣券"
                    }
                  }
                ],
                "objId": "2016110400077000000003446012",
                "score": 84,
                "title": "屈臣氏2(西溪印象城店)",
                "titleColor": "#E51C23"
              }
            ],
            "name": "玩乐"
          }
        ]
      },{
      "smallScreen1": "${O2OPopEyeSize.deviceSmallScreen}",
      "defalutShowTitle": "此刻，你身边最火的店"
    }],
    "on-tap": {
      "clickPopEye": ""
    },
    "on-display-once": {
      "exposureLog:": {
        "seed": "a13.b42.c4105_1"
      }
    },
    "style": {
      "direction": "vertical",
      "background-color": "white",
      "align-items": "center"
    },
    "children": [
      {
        "style": {
          "is-accessibility-element": true,
          "accessibility-label": "人气眼",
          "margin-top": 10,
          "spacing": 5,
          "align-items": "center"
        },
        "children": [
          {
            "type": "image",
            "style": {
              "image": "O2O.bundle/home_hot_sight",
              "width": 15,
              "height": 15,
              "content-mode": "scale-aspect-fit"
            }
          },
          {
            "type": "text",
            "style": {
              "color": "#333",
              "font-style": "bold",
              "font-size": 16,
              "text": "人气眼"
            }
          }
        ]
      },
      {
        "tag": 2001,
        "type": "text",
        "style": {
          "is-accessibility-element": true,
          "margin-top": 3,
          "font-size": 13,
          "color": "#888888",
          "align-self": "stretch",
          "alignment": "center",
          "text": "${subTitle.length == 0 ? defalutShowTitle : subTitle}"
        }
      },
      {
        "vars": {
          "smallScreenSize": "${tabList.count <=1 ? 235 : 245}",
          "bigScreenSize": "${tabList.count <=1 ? 254 : 282}"
        },
        "animation-duration": 0.5,
        "on-display": {
          "display:pagingview:": {
            "page-control": "${tabList.count <=1 ? false : true}",
            "pageViewNumber": 5,
            "tabList": "${tabList}",
            "page-control-titles": "${tabList.select(tab -> tab.name)}",
            "page-show-titles": "${tabList.select(tab -> tab.title)}",
            "page-default-show-title": "${defalutShowTitle}",
            "page-show-main-title": "${subTitle}"
          }
        },
        "on-switch": {
          "didScroll:pagingView:": ""
        },
        "style": {
          "is-accessibility-element": false,
          "margin-top": 10,
          "margin-bottom": 10,
          "margin-left": 15,
          "margin-right": 15,
          "height": "${smallScreen?smallScreenSize:bigScreenSize}",
          "align-self": "stretch",
          "page-control": false,
          "page-control-color": "#cccccc",
          "page-control-selected-color": "#fb6165",
          "page-control-scale": 0.6,
          "page-control-margin-bottom": 0,
          "auto-scroll": 6,
          "infinite-loop": true
        },
        "children": [
          {
            "repeat": "${tabList.count}",
            "vars": {
              "showTitle": "${tabList[_index_].showTitle}",
              "modelList": "${tabList[_index_].modelList}",
              "shopCount": "${tabList[_index_].modelList.count}",
              "pageIndex": "${_index_}"
            },
            "style": {
              "fixed": true,
              "properties": {
              }
            },
            "children": [
              {
                "vars": {
                  "topShops": "${shopCount > 2 ? modelList.sub_array(0,2) : modelList}",
                  "bottomShops": "${shopCount > 2 ? modelList.sub_array(2,shopCount - 2) : nil}",
                  "tag": "${1000 + (pageIndex + 1) *100}"
                },
                "tag": "${tag}",
                "style": {
                  "direction": "vertical",
                  "spacing": 3,
                  "properties": {
                  }
                },
                "children": [
                  {
                    "repeat": 2,
                    "vars": {
                      "shops": "${_index_ == 0 ? topShops : bottomShops}",
                      "isTopShop": "${_index_ == 0 ? 1 : 0}",
                      "hasLightShow": "${_index_ == 0 ? (topShops.count > 0 ? (topShops[0].cardData.count > 0 ? ((topShops[0].cardData[0].type == 'show' || topShops[0].cardData[0].blockId == 'M29')  ? 1 : 0): 0) : 0):0}"
                    },
                    "style": {
                      "direction": "horizontal",
                      "spacing": 3
                    },
                    "children": [
                      {
                        "repeat": "${shops.count}",
                        "vars": {
                          "shopInfo": "${shops[_index_]}",
                          "topWidth": "${hasLightShow ? (_index_ == 0 ? (_width_ - 3 - 30) * 2/3 + 1 : (_width_ - 3 - 30)/3):(_width_-3 -30)/2 }"
                        },
                        "children": [
                          {
                            "vars": {
                              "titleColor": "${shopInfo.titleColor}",
                              "bodyColor": "${shopInfo.bodyColor}",
                              "score": "${shopInfo.score.intValue}",
                              "title": "${shopInfo.title}",
                              "mark1": "${shopInfo.mark1}",
                              "firstCardData": "${shopInfo.cardData.count > 0 ? shopInfo.cardData[0] : nil }",
                              "secondCardData": "${shopInfo.cardData.count > 1 ? shopInfo.cardData[1] : nil }",
                              "cardData": "${shopInfo.cardData.count > 1 ? shopInfo.cardData[1]:shopInfo.cardData[0]}",
                              "cardTag": "${tag + ( isTopShop ? (_index_ + 1) : ( 2 +_index_ + 1)) * 10 }"
                            },
                            "tag": "${cardTag}",
                            "style": {
                              "width": "${isTopShop ? topWidth : (_width_-6 - 30)/3}",
                              "height": "${smallScreen?105:125}",
                              "direction": "horizontal",
                              "is-accessibility-element": true,
                              "accessibility-label": "人气${score}店名${title}"
                            },
                            "children": [
                              {
                                "gone": "${ !(firstCardData && firstCardData.blockId == 'M29')}",
                                "tag": "${cardTag + 1}",
                                "style": {
                                  "fixed": true
                                },
                                "children": [
                                  {
                                    "type": "image",
                                    "style": {
                                      "image-url": "${firstCardData.data.img}",
                                      "image": "O2O.bundle/imageLoading_one_second",
                                      "clip": true,
                                      "content-mode": "scale-aspect-fill",
                                      "flex-grow": "1"
                                    }
                                  },
                                  {
                                    "style": {
                                      "fixed": true,
                                      "background-color": "black",
                                      "alpha": 0.03
                                    }
                                  },
                                  {
                                    "type": "image",
                                    "style": {
                                      "fixed": true,
                                      "content-mode": "scale-to-fill",
                                      "image": "O2O.bundle/index-hot-sight-big-mask"
                                    }
                                  }]
                              },
                              {
                                "gone": "${ !(firstCardData && firstCardData.blockId == 'M28')}",
                                "tag": "${cardTag + 3}",
                                "style": {
                                  "fixed": true
                                },
                                "children": [
                                  {
                                    "type": "O2OImageManagerView",
                                    "tag": 10001,
                                    "config": {
                                      "imgs": "${firstCardData.data.imgs}",
                                      "width": "${topWidth}",
                                      "height": "${smallScreen?105:125}"
                                    },
                                    "style": {
                                      "fixed": true
                                    }
                                  },
                                  {
                                    "type": "image",
                                    "style": {
                                      "fixed": true,
                                      "content-mode": "scale-to-fill",
                                      "image": "O2O.bundle/index-hot-sight-big-mask"
                                    }
                                  },
                                  {
                                    "gone":"${score <= 0}",
                                    "style": {
                                      "fixed": true,
                                      "margin-left": 6,
                                      "margin-top": 5,
                                      "width": 40,
                                      "height": 57,
                                      "background-color": "#c0000000",
                                      "direction": "vertical",
                                      "align-items": "center"
                                    },
                                    "children": [
                                      {
                                        "gone": "${score < 100}",
                                        "type": "image",
                                        "style": {
                                          "fixed": true,
                                          "height": 18,
                                          "image": "O2O.bundle/index-hot-sight-score-bg",
                                          "content-mode": "scale-to-fill"
                                        }
                                      },
                                      {
                                        "type": "text",
                                        "style": {
                                          "color": "white",
                                          "height": 18,
                                          "width": "100%",
                                          "font-size": 9,
                                          "flex-shrink": 0,
                                          "alignment": "center",
                                          "text": "${score < 100? '此刻人气' : '人气火爆'}"
                                        }
                                      },
                                      {
                                        "gone": "${score >= 100}",
                                        "style": {
                                          "width": "31",
                                          "height": "1px",
                                          "flex-shrink": 0,
                                          "background-color": "white"
                                        }
                                      },
                                      {
                                        "type": "text",
                                        "style": {
                                          "font-size": "${score < 100? 32 : 27}",
                                          "color": "white",
                                          "font-name": "DINCondensedC",
                                          "margin-top": 2,
                                          "alignment": "center",
                                          "text": "${score}"
                                        }
                                      }
                                    ]
                                  },
                                  {
                                    "gone": "${mark1.length == 0}",
                                    "type": "image",
                                    "style": {
                                      "fixed": true,
                                      "margin-top": 0,
                                      "margin-right": 0,
                                      "margin-left": "auto",
                                      "margin-bottom": "auto",
                                      "width": 40,
                                      "height": 40,
                                      "image-url": "${mark1}"
                                    }
                                  },
                                  {
                                    "style": {
                                      "fixed": true,
                                      "margin-top": "auto",
                                      "margin-bottom": 8,
                                      "margin-right": 6,
                                      "margin-left": 6,
                                      "direction": "horizontal"
                                    },
                                    "children": [
                                      {
                                        "type": "text",
                                        "style": {
                                          "text": "${title}",
                                          "font-size": 13,
                                          "lines": 1,
                                          "font-style": "medium",
                                          "color": "white",
                                          "margin-right": 2
                                        }
                                      },
                                      {
                                        "gone": "${showTitle.length == 0 || score <=0}",
                                        "tag": 10002,
                                        "style": {
                                          "direction": "horizontal",
                                          "align-items": "center",
                                          "spacing": 4,
                                          "flex-shrink": 0,
                                          "height": "${smallScreen?16:18}",
                                          "margin-right": 0,
                                          "margin-left": "auto",
                                          "background-color": "${UIColor.colorWithRGB_alpha(0, 0.6)}"
                                        },
                                        "children": [
                                          {
                                            "type": "node",
                                            "tag": 100021,
                                            "style": {
                                              "width": 3,
                                              "height": 3,
                                              "corner-radius": 1.5,
                                              "background-color": "#4a90e2",
                                              "margin-left": 4
                                            }
                                          },
                                          {
                                            "type": "text",
                                            "style": {
                                              "text": "${ showTitle.length >0 ? showTitle : 'LIVE'}",
                                              "color": "#ffffff",
                                              "font-size": "${smallScreen?10:11}"
                                            }
                                          },
                                          {
                                            "type": "O2OAnimateImageView",
                                            "tag": 100022,
                                            "style": {
                                              "width": "${smallScreen?11:12}",
                                              "height": "${smallScreen?11:12}",
                                              "margin-right": 4
                                            }
                                          }
                                        ]
                                      }
                                    ]
                                  }
                                ]
                              },
                              {
                                "gone": "${ !(firstCardData && firstCardData.blockId == 'M11')}",
                                "tag": "${cardTag +  1}",
                                "style": {
                                  "fixed": true
                                },
                                "children": [
                                  {
                                    "type": "image",
                                    "style": {
                                      "image-url": "${firstCardData.data.img}",
                                      "image": "${isTopShop?'O2O.bundle/imageLoading_one_second':'O2O.bundle/imageLoading_one_third'}",
                                      "clip": true,
                                      "content-mode": "scale-aspect-fill",
                                      "flex-grow": "1"
                                    }
                                  },
                                  {
                                    "style": {
                                      "fixed": true,
                                      "background-color": "black",
                                      "alpha": 0.03
                                    }
                                  },
                                  {
                                    "type": "image",
                                    "style": {
                                      "fixed": true,
                                      "content-mode": "scale-to-fill",
                                      "image": "O2O.bundle/index-hot-sight-big-mask"
                                    }
                                  },
                                  {
                                    "style": {
                                      "fixed": true,
                                      "margin-left": 6,
                                      "margin-top": 5,
                                      "width": 40,
                                      "height": 57,
                                      "background-color": "#c0000000",
                                      "direction": "vertical",
                                      "align-items": "center"
                                    },
                                    "children": [
                                      {
                                        "gone": "${score < 100}",
                                        "type": "image",
                                        "style": {
                                          "fixed": true,
                                          "height": 18,
                                          "image": "O2O.bundle/index-hot-sight-score-bg",
                                          "content-mode": "scale-to-fill"
                                        }
                                      },
                                      {
                                        "type": "text",
                                        "style": {
                                          "color": "white",
                                          "height": 18,
                                          "width": "100%",
                                          "font-size": 9,
                                          "flex-shrink": 0,
                                          "alignment": "center",
                                          "text": "${score < 100? '此刻人气' : '人气火爆'}"
                                        }
                                      },
                                      {
                                        "gone": "${score >= 100}",
                                        "style": {
                                          "width": "31",
                                          "height": "1px",
                                          "flex-shrink": 0,
                                          "background-color": "white"
                                        }
                                      },
                                      {
                                        "type": "text",
                                        "style": {
                                          "font-size": "${score < 100? 32 : 27}",
                                          "color": "white",
                                          "font-name": "DINCondensedC",
                                          "margin-top": 2,
                                          "alignment": "center",
                                          "text": "${score}"
                                        }
                                      }
                                    ]
                                  },
                                  {
                                    "gone": "${mark1.length == 0}",
                                    "type": "image",
                                    "style": {
                                      "fixed": true,
                                      "margin-top": 0,
                                      "margin-right": 0,
                                      "margin-left": "auto",
                                      "margin-bottom": "auto",
                                      "width": 40,
                                      "height": 40,
                                      "image-url": "${mark1}"
                                    }
                                  },
                                  {
                                    "style": {
                                      "fixed": true,
                                      "margin-top": "auto",
                                      "margin-bottom": 8,
                                      "margin-right": 6,
                                      "margin-left": 6,
                                      "direction": "vertical"
                                    },
                                    "children": [
                                      {
                                        "type": "text",
                                        "style": {
                                          "text": "${title}",
                                          "font-size": 13,
                                          "lines": 1,
                                          "font-style": "medium",
                                          "color": "white"
                                        }
                                      }
                                    ]
                                  }
                                ]
                              },
                              {
                                "gone": "${ !(cardData && cardData.blockId == 'M22')}",
                                "tag": "${cardTag+  2}",
                                "style": {
                                  "fixed": true,
                                  "direction": "vertical",
                                  "background-color": "${bodyColor}"
                                },
                                "children": [
                                  {
                                    "style": {
                                      "background-color": "${titleColor}",
                                      "width": "100%",
                                      "height": "${smallScreen?38:45}",
                                      "flex-shrink": 0
                                    },
                                    "children": [
                                      {
                                        "type": "text",
                                        "style": {
                                          "width": 36,
                                          "font-size": "${score < 100? 32 : 27}",
                                          "color": "white",
                                          "font-name": "DINCondensedC",
                                          "alignment": "center",
                                          "text": "${score}",
                                          "flex-shrink": 0
                                        }
                                      },
                                      {
                                        "style": {
                                          "direction": "vertical",
                                          "margin-left": "${smallScreen?0:3}",
                                          "margin-right": 3,
                                          "spacing": 1
                                        },
                                        "children": [
                                          {
                                            "type": "text",
                                            "style": {
                                              "text": "${title}",
                                              "margin-top": 6,
                                              "font-size": 13,
                                              "color": "white",
                                              "font-style": "medium",
                                              "lines": "${(isTopShop&&!hasLightShow)?1:2}"
                                            }
                                          },
                                          {
                                            "gone": "${!isTopShop||hasLightShow||(shopInfo.sub1.length==0&&shopInfo.sub2.length==0)}",
                                            "style": {
                                              "wrap": true,
                                              "height": 15,
                                              "line-spacing": 10,
                                              "clip": true,
                                              "align-content": "end"
                                            },
                                            "children": [
                                              {
                                                "gone": "${shopInfo.sub1.length==0}",
                                                "type": "text",
                                                "style": {
                                                  "text": "${shopInfo.sub1 + (shopInfo.sub2.length>0 ? ' | ':'')}",
                                                  "font-size": 12,
                                                  "color": "${UIColor.colorWithRed_green_blue_alpha(1,1,1,0.7)}"
                                                }
                                              },
                                              {
                                                "gone": "${shopInfo.sub2.length==0}",
                                                "type": "text",
                                                "style": {
                                                  "text": "${shopInfo.sub2}",
                                                  "font-size": 12,
                                                  "color": "${UIColor.colorWithRed_green_blue_alpha(1,1,1,0.7)}"
                                                }
                                              }
                                            ]
                                          }
                                        ]
                                      }
                                    ]
                                  },
                                  {
                                    "style": {
                                      "margin-left": 6,
                                      "margin-right": 6,
                                      "direction": "vertical"
                                    },
                                    "children": [
                                      {
                                        "style": {
                                          "margin-top": 6,
                                          "flex-shrink": 0,
                                          "align-items": "center"
                                        },
                                        "children": [
                                          {
                                            "type": "image",
                                            "style": {
                                              "image-url": "${cardData.data.icon}",
                                              "width": 13,
                                              "height": 13,
                                              "margin-right": 3,
                                              "flex-shrink": 0,
                                              "clip": true
                                            }
                                          },
                                          {
                                            "type": "text",
                                            "style": {
                                              "text": "${cardData.data.desc}",
                                              "color": "white",
                                              "font-size": 13,
                                              "font-style": "medium"
                                            }
                                          }
                                        ]
                                      },
                                      {
                                        "style": {
                                          "margin-top": 5,
                                          "margin-bottom": 5
                                        },
                                        "children": [
                                          {
                                            "style": {
                                              "spacing": 3,
                                              "line-spacing": 3,
                                              "align-items": "center",
                                              "align-content": "start",
                                              "wrap": true,
                                              "clip": true
                                            },
                                            "children": [
                                              {
                                                "repeat": "${cardData.data.tags.count}",
                                                "style": {
                                                  "background-color": "${titleColor}",
                                                  "padding": 4
                                                },
                                                "children": [
                                                  {
                                                    "type": "text",
                                                    "style": {
                                                      "color": "white",
                                                      "font-size": 12,
                                                      "text": "${cardData.data.tags[_index_]}"
                                                    }
                                                  }
                                                ]
                                              }
                                            ]
                                          }
                                        ]
                                      }
                                    ]
                                  }
                                ]
                              },
                              {
                                "gone": "${ !(cardData && cardData.blockId == 'M23')}",
                                "tag": "${cardTag+  2}",
                                "style": {
                                  "fixed": true,
                                  "direction": "vertical",
                                  "background-color": "${bodyColor}"
                                },
                                "children": [
                                  {
                                    "style": {
                                      "background-color": "${titleColor}",
                                      "width": "100%",
                                      "height": "${smallScreen?38:45}",
                                      "flex-shrink": 0
                                    },
                                    "children": [
                                      {
                                        "type": "text",
                                        "style": {
                                          "width": 36,
                                          "font-size": "${score < 100? 32 : 27}",
                                          "color": "white",
                                          "font-name": "DINCondensedC",
                                          "alignment": "center",
                                          "text": "${score}",
                                          "flex-shrink": 0
                                        }
                                      },
                                      {
                                        "style": {
                                          "direction": "vertical",
                                          "margin-left": "${smallScreen?0:3}",
                                          "margin-right": 3,
                                          "spacing": 1
                                        },
                                        "children": [
                                          {
                                            "type": "text",
                                            "style": {
                                              "margin-top": 6,
                                              "text": "${title}",
                                              "font-size": 13,
                                              "color": "white",
                                              "font-style": "medium",
                                              "lines": "${(isTopShop&&!hasLightShow)?1:2}"
                                            }
                                          },
                                          {
                                            "gone": "${!isTopShop||hasLightShow||(shopInfo.sub1.length==0&&shopInfo.sub2.length==0)}",
                                            "style": {
                                              "wrap": true,
                                              "height": 15,
                                              "line-spacing": 10,
                                              "clip": true,
                                              "align-content": "end"
                                            },
                                            "children": [
                                              {
                                                "gone": "${shopInfo.sub1.length==0}",
                                                "type": "text",
                                                "style": {
                                                  "text": "${shopInfo.sub1 + (shopInfo.sub2.length>0 ? ' | ':'')}",
                                                  "font-size": 12,
                                                  "color": "${UIColor.colorWithRed_green_blue_alpha(1,1,1,0.7)}"
                                                }
                                              },
                                              {
                                                "gone": "${shopInfo.sub2.length==0}",
                                                "type": "text",
                                                "style": {
                                                  "text": "${shopInfo.sub2}",
                                                  "font-size": 12,
                                                  "color": "${UIColor.colorWithRed_green_blue_alpha(1,1,1,0.7)}"
                                                }
                                              }
                                            ]
                                          }
                                        ]
                                      }
                                    ]
                                  },
                                  {
                                    "style": {
                                      "margin-left": 6,
                                      "margin-right": 6,
                                      "height": 80,
                                      "direction": "vertical"
                                    },
                                    "children": [
                                      {
                                        "style": {
                                          "margin-top": 6,
                                          "flex-shrink": 0,
                                          "align-items": "center"
                                        },
                                        "children": [
                                          {
                                            "type": "image",
                                            "style": {
                                              "image-url": "${cardData.data.icon}",
                                              "width": 13,
                                              "height": 13,
                                              "margin-right": 3,
                                              "flex-shrink": 0,
                                              "clip": true
                                            }
                                          },
                                          {
                                            "type": "text",
                                            "style": {
                                              "text": "${cardData.data.desc}",
                                              "color": "white",
                                              "font-size": 13,
                                              "font-style": "medium"
                                            }
                                          }
                                        ]
                                      },
                                      {
                                        "type": "text",
                                        "style": {
                                          "margin-top": 8,
                                          "margin-bottom": 15,
                                          "text": "${cardData.data.cnt}",
                                          "font-size": 12,
                                          "color": "white",
                                          "wrap": true,
                                          "line-spacing": 2,
                                          "lines": 2
                                        }
                                      }
                                    ]
                                  }
                                ]
                              },
                              {
                                "gone": "${ !(cardData && cardData.blockId == 'M25')}",
                                "tag": "${cardTag+  2}",
                                "style": {
                                  "fixed": true,
                                  "direction": "vertical",
                                  "background-color": "${bodyColor}"
                                },
                                "children": [
                                  {
                                    "style": {
                                      "background-color": "${titleColor}",
                                      "width": "100%",
                                      "height": "${smallScreen?38:45}",
                                      "flex-shrink": 0
                                    },
                                    "children": [
                                      {
                                        "type": "text",
                                        "style": {
                                          "width": 36,
                                          "font-size": "${score < 100? 32 : 27}",
                                          "color": "white",
                                          "font-name": "DINCondensedC",
                                          "alignment": "center",
                                          "text": "${score}",
                                          "flex-shrink": 0
                                        }
                                      },
                                      {
                                        "style": {
                                          "direction": "vertical",
                                          "margin-left": "${smallScreen?0:3}",
                                          "margin-right": 3,
                                          "spacing": 1
                                        },
                                        "children": [
                                          {
                                            "type": "text",
                                            "style": {
                                              "margin-top": 6,
                                              "text": "${title}",
                                              "font-size": 13,
                                              "color": "white",
                                              "font-style": "medium",
                                              "lines": "${(isTopShop&&!hasLightShow)?1:2}"
                                            }
                                          },
                                          {
                                            "gone": "${!isTopShop||hasLightShow||(shopInfo.sub1.length==0&&shopInfo.sub2.length==0)}",
                                            "style": {
                                              "wrap": true,
                                              "height": 15,
                                              "line-spacing": 10,
                                              "clip": true,
                                              "align-content": "end"
                                            },
                                            "children": [
                                              {
                                                "gone": "${shopInfo.sub1.length==0}",
                                                "type": "text",
                                                "style": {
                                                  "text": "${shopInfo.sub1 + (shopInfo.sub2.length>0 ? ' | ':'')}",
                                                  "font-size": 12,
                                                  "color": "${UIColor.colorWithRed_green_blue_alpha(1,1,1,0.7)}"
                                                }
                                              },
                                              {
                                                "gone": "${shopInfo.sub2.length==0}",
                                                "type": "text",
                                                "style": {
                                                  "text": "${shopInfo.sub2}",
                                                  "font-size": 12,
                                                  "color": "${UIColor.colorWithRed_green_blue_alpha(1,1,1,0.7)}"
                                                }
                                              }
                                            ]
                                          }
                                        ]
                                      }
                                    ]
                                  },
                                  {
                                    "style": {
                                      "margin-left": 6,
                                      "margin-right": 6,
                                      "direction": "vertical"
                                    },
                                    "children": [
                                      {
                                        "style": {
                                          "margin-top": 6,
                                          "flex-shrink": 0,
                                          "align-items": "center"
                                        },
                                        "children": [
                                          {
                                            "type": "image",
                                            "style": {
                                              "image-url": "${cardData.data.icon}",
                                              "width": 13,
                                              "height": 13,
                                              "margin-right": 3,
                                              "flex-shrink": 0,
                                              "clip": true
                                            }
                                          },
                                          {
                                            "type": "text",
                                            "style": {
                                              "text": "${cardData.data.desc}",
                                              "color": "white",
                                              "font-size": 13,
                                              "font-style": "medium"
                                            }
                                          }
                                        ]
                                      },
                                      {
                                        "style": {
                                          "margin-top": 6,
                                          "margin-bottom": 7
                                        },
                                        "children": [
                                          {
                                            "style": {
                                              "spacing": 3,
                                              "line-spacing": 3,
                                              "align-items": "center",
                                              "align-content": "start",
                                              "wrap": true,
                                              "clip": true
                                            },
                                            "children": [
                                              {
                                                "repeat": "${cardData.data.tags.count}",
                                                "style": {
                                                  "corner-radius": 10,
                                                  "border-width": "${O2OPopEyeSize.deviceIphone6p?0.6666:'1px'}",
                                                  "border-color": "#66ffffff",
                                                  "padding-top": 3,
                                                  "padding-bottom": 3,
                                                  "padding-left": 6,
                                                  "padding-right": 6
                                                },
                                                "children": [
                                                  {
                                                    "type": "text",
                                                    "style": {
                                                      "color": "white",
                                                      "font-size": 12,
                                                      "text": "${cardData.data.tags[_index_]}"
                                                    }
                                                  }
                                                ]
                                              }
                                            ]
                                          }
                                        ]
                                      }
                                    ]
                                  }
                                ]
                              },
                              {
                                "gone": "${ !(cardData && cardData.blockId == 'M27')}",
                                "tag": "${cardTag+  2}",
                                "style": {
                                  "fixed": true,
                                  "direction": "vertical",
                                  "background-color": "${bodyColor}"
                                },
                                "children": [
                                  {
                                    "style": {
                                      "background-color": "${titleColor}",
                                      "width": "100%",
                                      "height": "${smallScreen?38:45}"
                                    },
                                    "children": [
                                      {
                                        "type": "text",
                                        "style": {
                                          "width": 36,
                                          "font-size": "${score < 100? 32 : 27}",
                                          "color": "white",
                                          "font-name": "DINCondensedC",
                                          "alignment": "center",
                                          "text": "${score}",
                                          "flex-shrink": 0
                                        }
                                      },
                                      {
                                        "style": {
                                          "direction": "vertical",
                                          "margin-left": "${smallScreen?0:3}",
                                          "margin-right": 3,
                                          "spacing": 1
                                        },
                                        "children": [
                                          {
                                            "type": "text",
                                            "style": {
                                              "text": "${title}",
                                              "margin-top": 6,
                                              "font-size": 13,
                                              "color": "white",
                                              "font-style": "medium",
                                              "lines": "${(isTopShop&&!hasLightShow)?1:2}"
                                            }
                                          },
                                          {
                                            "gone": "${!isTopShop||hasLightShow||(shopInfo.sub1.length==0&&shopInfo.sub2.length==0)}",
                                            "style": {
                                              "wrap": true,
                                              "height": 15,
                                              "line-spacing": 10,
                                              "clip": true,
                                              "align-content": "end"
                                            },
                                            "children": [
                                              {
                                                "gone": "${shopInfo.sub1.length==0}",
                                                "type": "text",
                                                "style": {
                                                  "text": "${shopInfo.sub1 + (shopInfo.sub2.length>0 ? ' | ':'')}",
                                                  "font-size": 12,
                                                  "color": "${UIColor.colorWithRed_green_blue_alpha(1,1,1,0.7)}"
                                                }
                                              },
                                              {
                                                "gone": "${shopInfo.sub2.length==0}",
                                                "type": "text",
                                                "style": {
                                                  "text": "${shopInfo.sub2}",
                                                  "font-size": 12,
                                                  "color": "${UIColor.colorWithRed_green_blue_alpha(1,1,1,0.7)}"
                                                }
                                              }
                                            ]
                                          }
                                        ]
                                      }
                                    ]
                                  },
                                  {
                                    "style": {
                                      "margin-top": 6,
                                      "margin-left": 6,
                                      "margin-right": 6,
                                      "flex-shrink": 0,
                                      "align-items": "center"
                                    },
                                    "children": [
                                      {
                                        "gone": "${!cardData.data.icon}",
                                        "type": "image",
                                        "style": {
                                          "image-url": "${cardData.data.icon}",
                                          "width": 13,
                                          "height": 13,
                                          "margin-right": 3,
                                          "flex-shrink": 0,
                                          "clip": true
                                        }
                                      },
                                      {
                                        "type": "text",
                                        "style": {
                                          "text": "${cardData.data.title}",
                                          "color": "white",
                                          "font-size": 13,
                                          "font-style": "medium"
                                        }
                                      }
                                    ]
                                  },
                                  {
                                    "style": {
                                      "margin-top": 5,
                                      "margin-left": 6,
                                      "margin-right": 9
                                    },
                                    "children": [
                                      {
                                        "type": "text",
                                        "style": {
                                          "text": "${cardData.data.tptl}",
                                          "font-size": 14,
                                          "color": "white",
                                          "font-style": "medium",
                                          "margin-top": 8,
                                          "flex-shrink": 0
                                        }
                                      },
                                      {
                                        "type": "text",
                                        "style": {
                                          "font-size": "${smallScreen?20:23}",
                                          "color": "white",
                                          "font-style": "bold",
                                          "flex-shrink": 0,
                                          "text": "${cardData.data.digit}"
                                        }
                                      },
                                      {
                                        "type": "text",
                                        "style": {
                                          "margin-bottom": 3,
                                          "font-size": 11,
                                          "margin-top": 8,
                                          "color": "white",
                                          "text": "${cardData.data.desc}"
                                        }
                                      }
                                    ]
                                  },
                                  {
                                    "type": "text",
                                    "style": {
                                      "margin-left": 6,
                                      "text": "${cardData.data.name}",
                                      "font-size": "12",
                                      "color": "white",
                                      "margin-top": "auto",
                                      "margin-bottom": 9
                                    }
                                  }
                                ]
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
})a";

NSString *wrapLayout1 = @R"(
{
  "layout": {
    "vars": {
      "article": "Abstract\n\nThe specification describes a CSS box model optimized for user interface design. In the flex layout model, the children of a flex container can be laid out in any direction, and can “flex” their sizes, either growing to fill unused space or shrinking to avoid overflowing the parent. Both horizontal and vertical alignment of the children can be easily manipulated. Nesting of these boxes (horizontal inside vertical, or vertical inside horizontal) can be used to build layouts in two dimensions.\n\nCSS is a language for describing the rendering of structured documents (such as HTML and XML) on screen, on paper, in speech, etc.\nStatus of this document\n\nThis section describes the status of this document at the time of its publication. Other documents may supersede this document. A list of current W3C publications and the latest revision of this technical report can be found in the W3C technical reports index at http://www.w3.org/TR/.\n\nThis document was produced by the CSS Working Group (part of the Style Activity) as a Candidate Recommendation. This document is intended to become a W3C Recommendation. This document will remain a Candidate Recommendation at least until 1 September 2016 in order to ensure the opportunity for wide review.\n\nThe (archived) public mailing list www-style@w3.org (see instructions) is preferred for discussion of this specification. When sending e-mail, please put the text “css-flexbox” in the subject, preferably like this: “[css-flexbox] …summary of comment…”\n\nPublication as a Candidate Recommendation does not imply endorsement by the W3C Membership. This is a draft document and may be updated, replaced or obsoleted by other documents at any time. It is inappropriate to cite this document as other than work in progress.\n\nThis document was produced by a group operating under the 5 February 2004 W3C Patent Policy. W3C maintains a public list of any patent disclosures made in connection with the deliverables of the group; that page also includes instructions for disclosing a patent. An individual who has actual knowledge of a patent which the individual believes contains Essential Claim(s) must disclose the information in accordance with section 6 of the W3C Patent Policy.\n\nThis document is governed by the 1 September 2015 W3C Process Document.\n\nFor changes since the last draft, see the Changes section."
    },
    "style": {
      "wrap": "wrap",
      "padding": 5
    },
    "children": [
      {
        "repeat": "${article.replace('\\n', ' ').split(' ').filter(s -> s.length > 0)/*.sub_array(0, 3)*/}",
        "type": "text",
        "style": {
          "margin": 5,
          "text": "${_item_}"
        }
      }
    ]
  }
})";

NSString *wrapLayout2 = @R"(
{
  "layout": {
    "vars": {
      "article": "Abstract\n\nThe specification describes a CSS box model optimized for user interface design. In the flex layout model, the children of a flex container can be laid out in any direction, and can “flex” their sizes, either growing to fill unused space or shrinking to avoid overflowing the parent. Both horizontal and vertical alignment of the children can be easily manipulated. Nesting of these boxes (horizontal inside vertical, or vertical inside horizontal) can be used to build layouts in two dimensions.\n\nCSS is a language for describing the rendering of structured documents (such as HTML and XML) on screen, on paper, in speech, etc.\nStatus of this document\n\nThis section describes the status of this document at the time of its publication. Other documents may supersede this document. A list of current W3C publications and the latest revision of this technical report can be found in the W3C technical reports index at http://www.w3.org/TR/.\n\nThis document was produced by the CSS Working Group (part of the Style Activity) as a Candidate Recommendation. This document is intended to become a W3C Recommendation. This document will remain a Candidate Recommendation at least until 1 September 2016 in order to ensure the opportunity for wide review.\n\nThe (archived) public mailing list www-style@w3.org (see instructions) is preferred for discussion of this specification. When sending e-mail, please put the text “css-flexbox” in the subject, preferably like this: “[css-flexbox] …summary of comment…”\n\nPublication as a Candidate Recommendation does not imply endorsement by the W3C Membership. This is a draft document and may be updated, replaced or obsoleted by other documents at any time. It is inappropriate to cite this document as other than work in progress.\n\nThis document was produced by a group operating under the 5 February 2004 W3C Patent Policy. W3C maintains a public list of any patent disclosures made in connection with the deliverables of the group; that page also includes instructions for disclosing a patent. An individual who has actual knowledge of a patent which the individual believes contains Essential Claim(s) must disclose the information in accordance with section 6 of the W3C Patent Policy.\n\nThis document is governed by the 1 September 2015 W3C Process Document.\n\nFor changes since the last draft, see the Changes section."
    },
    "style": {
      "wrap": "wrap",
      "padding": 5
    },
    "children": [
      {
        "repeat": "${article.replace('\\n', ' ').split(' ').filter(s -> s.length > 0)}",
        "style": {
          "margin": 5,
          "width": "${_index_ % 11 * 9 +20}",
          "height": 20
        }
      }
    ]
  }
})";

NSString *wrapLayout3 = @R"(
{
  "layout": {
    "vars": {
      "article": "Abstract\n\nThe specification describes a CSS box model optimized for user interface design. In the flex layout model, the children of a flex container can be laid out in any direction, and can “flex” their sizes, either growing to fill unused space or shrinking to avoid overflowing the parent. Both horizontal and vertical alignment of the children can be easily manipulated. Nesting of these boxes (horizontal inside vertical, or vertical inside horizontal) can be used to build layouts in two dimensions.\n\nCSS is a language for describing the rendering of structured documents (such as HTML and XML) on screen, on paper, in speech, etc.\nStatus of this document\n\nThis section describes the status of this document at the time of its publication. Other documents may supersede this document. A list of current W3C publications and the latest revision of this technical report can be found in the W3C technical reports index at http://www.w3.org/TR/.\n\nThis document was produced by the CSS Working Group (part of the Style Activity) as a Candidate Recommendation. This document is intended to become a W3C Recommendation. This document will remain a Candidate Recommendation at least until 1 September 2016 in order to ensure the opportunity for wide review.\n\nThe (archived) public mailing list www-style@w3.org (see instructions) is preferred for discussion of this specification. When sending e-mail, please put the text “css-flexbox” in the subject, preferably like this: “[css-flexbox] …summary of comment…”\n\nPublication as a Candidate Recommendation does not imply endorsement by the W3C Membership. This is a draft document and may be updated, replaced or obsoleted by other documents at any time. It is inappropriate to cite this document as other than work in progress.\n\nThis document was produced by a group operating under the 5 February 2004 W3C Patent Policy. W3C maintains a public list of any patent disclosures made in connection with the deliverables of the group; that page also includes instructions for disclosing a patent. An individual who has actual knowledge of a patent which the individual believes contains Essential Claim(s) must disclose the information in accordance with section 6 of the W3C Patent Policy.\n\nThis document is governed by the 1 September 2015 W3C Process Document.\n\nFor changes since the last draft, see the Changes section."
    },
    "children": [
      {
        "style": {
          "wrap": "wrap",
          "padding": 5
        },
        "children": [
          {
            "repeat": "${article.replace('\\n', ' ').split(' ').filter(s -> s.length > 0)/*.sub_array(0, 3)*/}",
            "type": "text",
            "style": {
              "margin": 5,
              "text": "${_item_}"
            }
          }
        ]
      }
    ]
  }
})";

NSString *nowrapLayout1 = @R"(
{
  "layout": {
    "vars": {
      "article": "Abstract\n\nThe specification describes a CSS box model optimized for user interface design. In the flex layout model, the children of a flex container can be laid out in any direction, and can “flex” their sizes, either growing to fill unused space or shrinking to avoid overflowing the parent. Both horizontal and vertical alignment of the children can be easily manipulated. Nesting of these boxes (horizontal inside vertical, or vertical inside horizontal) can be used to build layouts in two dimensions.\n\nCSS is a language for describing the rendering of structured documents (such as HTML and XML) on screen, on paper, in speech, etc.\nStatus of this document\n\nThis section describes the status of this document at the time of its publication. Other documents may supersede this document. A list of current W3C publications and the latest revision of this technical report can be found in the W3C technical reports index at http://www.w3.org/TR/.\n\nThis document was produced by the CSS Working Group (part of the Style Activity) as a Candidate Recommendation. This document is intended to become a W3C Recommendation. This document will remain a Candidate Recommendation at least until 1 September 2016 in order to ensure the opportunity for wide review.\n\nThe (archived) public mailing list www-style@w3.org (see instructions) is preferred for discussion of this specification. When sending e-mail, please put the text “css-flexbox” in the subject, preferably like this: “[css-flexbox] …summary of comment…”\n\nPublication as a Candidate Recommendation does not imply endorsement by the W3C Membership. This is a draft document and may be updated, replaced or obsoleted by other documents at any time. It is inappropriate to cite this document as other than work in progress.\n\nThis document was produced by a group operating under the 5 February 2004 W3C Patent Policy. W3C maintains a public list of any patent disclosures made in connection with the deliverables of the group; that page also includes instructions for disclosing a patent. An individual who has actual knowledge of a patent which the individual believes contains Essential Claim(s) must disclose the information in accordance with section 6 of the W3C Patent Policy.\n\nThis document is governed by the 1 September 2015 W3C Process Document.\n\nFor changes since the last draft, see the Changes section."
    },
    "style": {
      "padding": 5,
      "direction": "vertical"
    },
    "children": [
      {
        "repeat": "${article.replace('\\n', ' ').split(' ').filter(s -> s.length > 0).slice(5)}",
        "style": {
          "justify-content": "space-between"
        },
        "children": [
          {
            "repeat": "${_item_}",
            "type": "text",
            "style": {
              "margin": 5,
              "text": "${_item_}"
            }
          }
        ]
      }
    ]
  }
})";

NSString *nowrapLayout2 = @R"(
{
  "layout": {
    "vars": {
      "article": "Abstract\n\nThe specification describes a CSS box model optimized for user interface design. In the flex layout model, the children of a flex container can be laid out in any direction, and can “flex” their sizes, either growing to fill unused space or shrinking to avoid overflowing the parent. Both horizontal and vertical alignment of the children can be easily manipulated. Nesting of these boxes (horizontal inside vertical, or vertical inside horizontal) can be used to build layouts in two dimensions.\n\nCSS is a language for describing the rendering of structured documents (such as HTML and XML) on screen, on paper, in speech, etc.\nStatus of this document\n\nThis section describes the status of this document at the time of its publication. Other documents may supersede this document. A list of current W3C publications and the latest revision of this technical report can be found in the W3C technical reports index at http://www.w3.org/TR/.\n\nThis document was produced by the CSS Working Group (part of the Style Activity) as a Candidate Recommendation. This document is intended to become a W3C Recommendation. This document will remain a Candidate Recommendation at least until 1 September 2016 in order to ensure the opportunity for wide review.\n\nThe (archived) public mailing list www-style@w3.org (see instructions) is preferred for discussion of this specification. When sending e-mail, please put the text “css-flexbox” in the subject, preferably like this: “[css-flexbox] …summary of comment…”\n\nPublication as a Candidate Recommendation does not imply endorsement by the W3C Membership. This is a draft document and may be updated, replaced or obsoleted by other documents at any time. It is inappropriate to cite this document as other than work in progress.\n\nThis document was produced by a group operating under the 5 February 2004 W3C Patent Policy. W3C maintains a public list of any patent disclosures made in connection with the deliverables of the group; that page also includes instructions for disclosing a patent. An individual who has actual knowledge of a patent which the individual believes contains Essential Claim(s) must disclose the information in accordance with section 6 of the W3C Patent Policy.\n\nThis document is governed by the 1 September 2015 W3C Process Document.\n\nFor changes since the last draft, see the Changes section."
    },
    "style": {
      "padding": 5,
      "direction": "vertical"
    },
    "children": [
      {
        "repeat": "${article.replace('\\n', ' ').split(' ').filter(s -> s.length > 0).slice(5)}",
        "style": {
          "justify-content": "space-between"
        },
        "children": [
          {
            "repeat": "${_item_}",
            "style": {
              "margin": 5,
              "width": "${_index_ * 10 + 20}",
              "height": 20
            }
          }
        ]
      }
    ]
  }
})";


@interface LayoutPerformanceTests : XCTestCase

@end

@implementation LayoutPerformanceTests

// - (void)startMeasuring {}
// - (void)stopMeasuring {}
// - (void)measureMetrics:(NSArray<NSString *> *)metrics automaticallyStartMeasuring:(BOOL)automaticallyStartMeasuring forBlock:(void (^)())block { block(); }

- (void)testSimple1 {
    MeasureLayout(simpleLayout1);
}

- (void)testSimple1_Yoga {
    MeasureLayoutYoga(simpleLayout1);
}


- (void)testSimple2 {
    MeasureLayout(simpleLayout2);
}

- (void)testSimple2_Yoga {
    MeasureLayoutYoga(simpleLayout2);
}


- (void)testSimple3 {
    MeasureLayout(simpleLayout3);
}

- (void)testSimple3_Yoga {
    MeasureLayoutYoga(simpleLayout3);
}


- (void)testComplex1 {
    MeasureLayout(complexLayout1);
}

- (void)testComplex1_Yoga {
    MeasureLayoutYoga(complexLayout1);
}


- (void)testComplex2 {
    MeasureLayout(complexLayout2);
}

- (void)testComplex2_Yoga {
    MeasureLayoutYoga(complexLayout2);
}


- (void)testComplex3 {
    MeasureLayout(complexLayout3);
}

- (void)testComplex3_Yoga {
    MeasureLayoutYoga(complexLayout3);
}


- (void)testWrap1 {
    MeasureLayout(wrapLayout1);
}

- (void)testWrap1_Yoga {
    MeasureLayoutYoga(wrapLayout1);
}


- (void)testWrap2 {
    MeasureLayout(wrapLayout2);
}

- (void)testWrap2_Yoga {
    MeasureLayoutYoga(wrapLayout2);
}


- (void)testWrap3 {
    MeasureLayout(wrapLayout3);
}

- (void)testWrap3_Yoga {
    MeasureLayoutYoga(wrapLayout3);
}


- (void)testNoWrap1 {
    MeasureLayout(nowrapLayout1);
}

- (void)testNoWrap1_Yoga {
    MeasureLayoutYoga(nowrapLayout1);
}


- (void)testNoWrap2 {
    MeasureLayout(nowrapLayout2);
}

- (void)testNoWrap2_Yoga {
    MeasureLayoutYoga(nowrapLayout2);
}


@end
