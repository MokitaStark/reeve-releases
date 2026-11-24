# theme-starter · Reeve 外观与渐变主题插件示例

`theme-starter` 演示了如何编写纯声明式的 Reeve 外观主题插件（`kind: "theme"`），无需任何脚本代码即可扩展浅色/深色双模式毛玻璃表面、渐变背景（`gradientFrom` / `gradientTo`）与柔和氛围光晕（`ambientGlow`）。

## 目录结构

- `reeve.plugin.json`：包含主题元信息及 `themes` 浅色/深色双色板定义（支持 `#RRGGBB` 与带透明度的 `#RRGGBBAA` 颜色令牌）。
- `theme-starter.test.mjs`：校验清单字段合法性与色值正则的单元测试。

## 校验与安装

```bash
# 本地运行字段与色值合规测试
bun test ./examples/plugins/theme-starter
```

在 Reeve 桌面端中打开 **「设置 → 外观 → 主题插件 → 导入主题插件」**，选择本目录或 `reeve.plugin.json` 即可立即生效。
