# genui-style-starter · Reeve 生成式 UI 风格插件示例

`genui-style-starter` 演示了如何通过纯声明式 JSON（`kind: "genui-style"`）定制 Reeve 对话流中生成式 UI（`render_ui`）交互卡片的圆角、密度、阴影、图表曲线及浅色/深色双模式配色体系，导入后在桌面端与移动端同步生效。

## 目录结构

- `reeve.plugin.json`：定义 `styles[].tokens` 几何美学令牌及 `light` / `dark` 表面与图表色板。
- `genui-style-starter.test.mjs`：校验清单字段范围、枚举值与十六进制颜色合法性的单元测试。

## 校验与安装

```bash
bun test ./examples/plugins/genui-style-starter
```

在 Reeve 桌面端打开 **「设置 → 生成式 UI → 生成式 UI 风格插件 → 导入风格包」**，选择本目录或 `reeve.plugin.json` 即可实时预览并启用。
