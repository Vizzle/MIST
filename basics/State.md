# State

在 Mist 中，不可直接修改视图，而是通过更新状态使视图重新计算。

比如，如果要实现展开/收起的功能，每次点击时只需改变状态，即可自动重新生成视图。

<video width="374px" autoplay loop>
  <source src="state_1.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

{% set code = {
  "layout": {
    "style": {
      "padding": 10,
      "direction": "vertical"
    },
    "children": [
      {
        "children": [
          {
            "type": "text",
            "style": {
              "text": "Lorem ipsum",
              "font-size": 20
            }
          },
          {
            "type": "text",
            "style": {
              "text": "${state.expanded ? '收起' : '展开'}",
              "color": "blue",
              "margin-left": "auto"
            },
            "on-tap": {
              "updateState:": {
                "expanded": "${!state.expanded}"
              }
            }
          }
        ]
      },
      {
        "gone": "${!state.expanded}",
        "type": "text",
        "style": {
          "text": "Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
          "font-size": 16,
          "color": "gray",
          "margin-top": 6,
          "lines": 0
        }
      }
    ]
  }
} %}
{% include "../templates/code.md" %}