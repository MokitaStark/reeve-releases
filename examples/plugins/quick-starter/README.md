# `quick-starter` — Reeve 插件开发入门示例

本目录配合 [Reeve 插件与主题开发完整指南](../../../docs/plugin-development.md) 提供一个可直接复制改写的标准 Worker 插件模板。

## 包含文件

- `reeve.plugin.json`：清单文件，声明插件 ID、版本、权限、只读与写入工具及其 JSON Schema、内置技能。
- `index.mjs`：零外部依赖 ESM 入口，兼容 Bun 与 Node.js，示范 `activate`、`deactivate`、项目工作区路径防穿越与工具返回值结构。
- `quick-starter.test.mjs`：标准单元测试，运行 `bun test ./examples/plugins/quick-starter` 即可验证。

## 安装方式

1. 在 Reeve Web 端 **扩展 → 插件 → 安装本地插件**，或在桌面端 **设置 → 插件 → 安装插件**，选择本目录。
2. 启用插件后，即可在工具调试面板或智能体对话中使用 `plugin_quick_starter__inspect_workspace` 与 `plugin_quick_starter__write_note`。
