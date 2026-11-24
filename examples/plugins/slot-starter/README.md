# slot-starter · Reeve 全插槽示例插件

`slot-starter` 演示了如何基于 Reeve 原生插件槽（Plugin Slots）一次性扩展 **7 个界面位置**，并通过「创造模式（Create Mode）」实时安装验证。

## 目录结构

- `reeve.plugin.json`：声明插件元信息、`slot_starter_status` 只读工具以及 7 个原生插槽。
- `icon.svg`：纯矢量扩展图标（经安全清洗渲染，禁止 `<script>` 及内联事件属性）。
- `index.mjs`：导出 `tools`、`slots`（同时提供 `renderSlot` / `onSlotAction`），演示：
  - 内联 SVG 装饰与动态进度图形；
  - 交互表单状态保存（新增与勾选列表项、随手便签）；
  - 客户端动作响应（`insert_text` 回填输入框、`open_slot` 跨插槽跳转、`dispatch` 服务端状态变更与消息底部摘要收藏）。
- `slot-starter.test.mjs`：`bun test` 单元测试。

## 挂载的 7 个标准插槽

| 插槽 ID | 标准位置 (`slot`) | 界面呈现 |
| --- | --- | --- |
| `composer-quickbar` | `conversation.composer.dock` | 对话输入框正上方的快捷条（含矢量徽标与提示词一键填入） |
| `status-capsule` | `conversation.header.utilities` | 主区顶栏右侧计数胶囊，点击弹出毛玻璃微面板 |
| `workspace` | `main` | 左侧栏自动入口打开的主区全幅灵感工作台 |
| `workspace` | `sidebar.nav` | 左侧栏与 `main` 配对的快捷跳转入口 |
| `quick-notes` | `right_panel` | 右侧可拖拽液态玻璃分栏（随手便签与回填输入框） |
| `starter-tips` | `conversation.starter` | 新对话空白欢迎页底部的创作向导卡片 |
| `message-pin` | `conversation.message.footer` | 每条助手回复底栏的「收藏灵感」按钮 |

## 安装与测试

```bash
# 1. 本地运行 Bun 单测
bun test ./examples/plugins/slot-starter
```

在 Reeve 中可通过以下两种方式安装体验：
1. **桌面端设置安装**：打开「设置 → 插件 → 安装本地插件」，选择本目录并启用。
2. **创造模式对话安装**：切换到 **创造模式（`create`）**，发送「请帮我安装或基于 `examples/plugins/slot-starter` 定制一个新插件」。
