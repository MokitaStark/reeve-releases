# Reeve 原生插件槽（Plugin Slots）与声明式 UI 规范

本文档提供 Reeve 7 大界面插槽位置、22 种原生声明式 UI 节点（`PluginUINode`）、6 种动作协议（`PluginUIAction`）、SVG 安全清洗规则及动态 Worker 插槽完整写法。

## 目录

1. [7 大标准插槽位置与 DSH 兼容别名](#1-7-大标准插槽位置与-dsh-兼容别名)
2. [`reeve.plugin.json` 中的 `slots` 声明结构](#2-reevepluginjson-中的-slots-声明结构)
3. [22 种 `PluginUINode` 节点完整速查](#3-22-种-pluginuinode-节点完整速查)
4. [6 种 `PluginUIAction` 交互动作契约](#4-6-种-pluginuiaction-交互动作契约)
5. [自定义 SVG 矢量图标与插画安全规范](#5-自定义-svg-矢量图标与插画安全规范)
6. [Worker 动态插槽状态管理与热更新范式](#6-worker-动态插槽状态管理与热更新范式)

---

## 1. 7 大标准插槽位置与 DSH 兼容别名

单个插件最多可声明 **20 个插槽**。`slot.id` 必须匹配 `^[a-z0-9][a-z0-9_-]{0,63}$`，且同一 `slot` 位置下 `id` 不可重复。

| 标准插槽名 (`slot`) | 自动兼容别名 | 桌面端渲染位置与交互特征 | 设计建议 |
| --- | --- | --- | --- |
| `conversation.composer.dock` | `composer.dock`、`conversation.input.dock` | 对话输入框正上方停靠区 | 保持单行紧凑（建议高度 `<= 64px`），适合快捷指令按钮、状态胶囊或小型 SVG 挂件 |
| `conversation.header.utilities` | `header.utilities`、`conversation.session.header.utilities` | 主区顶栏右侧工具胶囊左侧 | 显示图标与 `badgeText`；提供 `view` 时点击弹出毛玻璃浮层面板 |
| `main` | — | 左侧栏生成入口，点击后在主内容区全幅展示 | 适合可视化仪表盘、灵感工作台、多区块表单看板 |
| `sidebar.nav` | `sidebar.panellist` | 左侧导航栏扩展入口 | 若与同插件的 `main` 插槽共享相同 `id`，自动合并为打开该主视图的快捷导航项 |
| `right_panel` | `sidebar.right.pane.tab`、`sidebar.right` | 顶栏工作区胶囊图标及「更多工具」菜单项，点击展开可拖拽右侧栏 | 适合随手记便签、接口检查器、实时监控侧栏 |
| `conversation.starter` | `conversation.hero`、`starter` | 新对话空白欢迎页引导芯片下方的推荐卡片 | 适合开场模板一键填入（`insert_text`）或引导打开主工作台（`open_slot`） |
| `conversation.message.footer` | `conversation.chat.assistant-actions`、`message.footer` | 每条助手回复消息底栏的轻量动作按钮 | 触发时宿主自动在 `payload` 注入 `{ messageId, conversationId, content }` |

---

## 2. `reeve.plugin.json` 中的 `slots` 声明结构

- **`kind: "config"` 静态插槽**：无需 `index.mjs` 子进程，每个插槽必须至少声明静态 `view` 或 `action`。
- **`kind: "worker"` 动态插槽**：由 `index.mjs` 导出的 `slots[slotId]` 动态渲染（单次渲染超时 `3s`）；若清单中同时写了 `view`，当 Worker 未实现或报错时会自动优雅降级为静态 `view`。
- **`refreshIntervalMs`**：可选自动轮询毫秒间隔，仅允许 `0`（不轮询）或 `1000`～`600000`。

```json
{
  "id": "review-dock",
  "name": "代码走查停靠条",
  "version": "1.0.0",
  "description": "在输入框上方提供一键走查快捷条",
  "kind": "config",
  "icon": "icon.svg",
  "tools": [],
  "slots": [
    {
      "id": "quick-review",
      "slot": "conversation.composer.dock",
      "title": "快捷走查",
      "description": "一键填入审查提示词",
      "icon": "spark",
      "badgeText": "就绪",
      "order": 10,
      "refreshIntervalMs": 0,
      "view": {
        "type": "row",
        "gap": 8,
        "align": "center",
        "children": [
          { "type": "badge", "text": "走查", "tone": "accent" },
          {
            "type": "button",
            "label": "审查未提交变更",
            "variant": "quiet",
            "action": {
              "type": "insert_text",
              "text": "请结合当前 Git 变更检查潜在边界缺陷、并发竞争与安全风险。"
            }
          }
        ]
      }
    }
  ]
}
```

---

## 3. 22 种 `PluginUINode` 节点完整速查

后端对单棵 UI 树强制执行安全边界：**最大深度 `12` 层**、**总节点数不超过 `250` 个**，并自动脱敏已存密钥文本。

### 容器与布局节点（6 种）
- `column`：垂直弹性布局（支持 `gap`、`padding`、`align`、`justify`、`grow`、`children`）
- `row`：水平弹性布局（支持 `gap`、`padding`、`align`、`justify`、`wrap`、`grow`、`children`）
- `card`：毛玻璃圆角卡片容器（支持 `title`、`subtitle`、`tone`、`padding`、`gap`、`children`）
- `box`：通用尺寸/内边距容器（支持 `width`、`height`、`maxHeight`、`padding`、`tone`、`children`）
- `scroll`：带纵向滚动条容器（推荐配合 `maxHeight` 使用）
- `collapsible`：可折叠展开区块（支持 `title`、`subtitle`、`checked` 默认展开态、`children`）

### 内容与数据展示节点（11 种）
- `text`：纯文本（`text`、`size`：`xs`/`sm`/`md`/`lg`/`xl`、`weight`：`normal`/`medium`/`semibold`/`bold`、`tone`、`mono`、`selectable`）
- `markdown`：富文本 Markdown 块（`content` 或 `text`）
- `code`：等宽代码块（`content` 或 `text`、`language`）
- `svg`：矢量图形（`src` 包内 `.svg` 相对路径，或 `svg` 内联 `<svg>...</svg>` 字符串；支持 `width`、`height`、`tint: "current"` 跟随主题色）
- `badge`：胶囊状态标签（`text`、`tone`）
- `stat`：关键指标卡（`label`、`value`、`meta`、`tone`）
- `progress`：进度条（`label`、`value` 说明文字、`progress`：支持 `0~1` 小数或 `0~100` 百分比、`tone`）
- `list_item`：结构化列表行（`title`、`subtitle`、`meta`、`icon`、`tone`、`action`）
- `empty`：空状态占位说明（`title`、`subtitle`、`icon`）
- `divider`：细分割线
- `spacer`：弹性空白占位（`grow`、`width`、`height`）

### 交互表单与触发节点（5 种）
- `button`：按钮（`label`、`icon`、`variant`：`default`/`primary`/`quiet`/`danger`、`disabled`、`action`）
- `input`：单行文本输入（`field` 绑定状态字段名、`label`、`placeholder`、`value`、`disabled`）
- `textarea`：多行文本输入（`field`、`label`、`placeholder`、`value`、`height`、`disabled`）
- `select`：下拉选择（`field`、`label`、`value`、`options: [{ "label": "...", "value": "..." }]`、`action`）
- `toggle`：布尔开关（`field`、`label`、`checked`、`action`）

> **视觉与布局黄金准则（对齐桌面端真实容器）**：
> 1. **语义色适配**：文字与卡片请始终使用语义 `tone`（`default`、`neutral`、`muted`、`subtle`、`accent`、`success`、`warning`、`danger`），让桌面端自动适配浅色、深色与 Liquid Glass 材质，不要硬编码死色背景。
> 2. **避免双层外边距**：桌面端宿主在 `right_panel`（自带 `42px` 标题头与 `12px` 滚动区内边距）和 `main`（自带标题栏与 `12px 24px` 页面边距）外层已提供标准留白，因此插件返回的根 `column` **无需再写外层 `padding: 12`**。
> 3. **双列指标卡等宽对齐**：在水平 `row` 中并排放置多个 `stat` 节点时，**务必显式声明 `grow: 1`**，使各指标卡 1:1 等宽撑满容器。
> 4. **首屏 `render(ctx)` 零阻塞**：宿主对单次 `render_slot` 限制 `3s` 超时。初始 `render` 应仅做本地文件或环境变量布尔自检（`<= 50ms`），通过面板内的按钮触发 `dispatch` 按需执行网络请求或 CLI 诊断。

---

## 4. 6 种 `PluginUIAction` 交互动作契约

| `action.type` | 执行位置 | 关键字段与行为说明 |
| --- | --- | --- |
| `insert_text` | 桌面端本地 | 将 `text` 追加填入当前对话输入框并自动聚焦聊天视图 |
| `copy_text` | 桌面端本地 | 将 `text` 复制到系统剪贴板并弹出轻提示 |
| `open_url` | 桌面端本地 | 在系统浏览器打开 `url`（严格白名单：仅允许 `http://` 与 `https://`） |
| `open_slot` | 桌面端本地 | 按 `target`（目标 `slot.id`）跳转到本插件的 `main` 页面或展开 `right_panel` |
| `call_tool` | Go 后端 → Worker | 调用本插件声明的 `tool`（传入 `payload` 及当前实例 `state`），完成后自动刷新插槽 |
| `dispatch` | Go 后端 → Worker | 仅 `kind: "worker"` 可用；调用 `slots[slotId].action(handler, payload, ctx)`，支持读取表单状态并返回新状态与客户端副作用 |

> **真实表单取值契约（重要）**：
> - 用户在设置了 `field` 属性的 `input`、`textarea`、`select` 或 `toggle` 中输入或切换时，桌面端会将最新值实时保存在插件状态 **`ctx.state[field]`** 中；
> - 若在 `input` 节点上同时绑定了 `action: { type: 'dispatch', handler: '...' }`，用户按 **Enter 回车键** 提交时会额外传入 `payload = { field, value }`。
> - 因此在 `action(handler, payload, ctx)` 中读取表单字段的标准写法为：
>   `const val = payload?.field === 'draft' ? payload.value : (payload?.draft ?? ctx.state?.draft ?? '');`

---

## 5. 自定义 SVG 矢量图标与插画安全规范

- 包内 SVG 文件必须是插件目录内的普通 `.svg` 文件，禁止符号链接或 `..` 路径逃逸，单文件大小上限 **`256 KiB`**。
- 仅放行安全矢量标签：`svg`、`g`、`path`、`rect`、`circle`、`ellipse`、`line`、`polyline`、`polygon`、`defs`、`linearGradient`、`radialGradient`、`stop`、`clipPath`、`mask`、`pattern`、`symbol`、`use`、`text`、`tspan`、`title`、`desc`。
- 后端会强制剥离 `<script>`、`foreignObject`、所有 `on*=` 事件属性、`javascript:` / 外部网络 `url(...)` 引用，确保 100% 纯静态安全渲染。

---

## 6. Worker 动态插槽状态管理与热更新范式

在 `index.mjs` 中导出 `slots` 对象（键名为 `reeve.plugin.json` 中的 `slot.id`）：

```javascript
export const slots = {
  'quick-notes': {
    async render(ctx) {
      // ctx 包含: { project: { id, rootPath }, projectId, projectName, conversationId, conversationMode, dark, skin, state }
      const items = Array.isArray(ctx.state?.items) ? ctx.state.items : [];
      return {
        badgeText: items.length > 0 ? String(items.length) : '',
        state: { ...ctx.state, items },
        view: {
          type: 'column',
          gap: 10,
          children: [
            {
              type: 'row',
              gap: 8,
              children: [
                {
                  type: 'input',
                  field: 'draft',
                  placeholder: '记录一条待办灵感（回车或点添加）…',
                  value: String(ctx.state?.draft || ''),
                  grow: 1,
                  action: { type: 'dispatch', handler: 'add_item' },
                },
                {
                  type: 'button',
                  label: '添加',
                  variant: 'primary',
                  action: { type: 'dispatch', handler: 'add_item' },
                },
              ],
            },
            ...(items.length === 0
              ? [{ type: 'empty', title: '暂无便签', subtitle: '输入内容后点击添加即可保存' }]
              : items.map((text, idx) => ({
                  type: 'list_item',
                  title: text,
                  action: { type: 'insert_text', text },
                  meta: `#${idx + 1}`,
                }))),
          ],
        },
      };
    },

    async action(handler, payload = {}, ctx = {}) {
      const items = Array.isArray(ctx.state?.items) ? [...ctx.state.items] : [];
      if (handler === 'add_item') {
        const rawDraft = payload?.field === 'draft' ? payload.value : (payload?.draft ?? ctx.state?.draft ?? '');
        const draft = String(rawDraft).trim();
        if (!draft) {
          return { state: ctx.state, toast: '请先输入便签内容' };
        }
        const nextItems = [draft, ...items].slice(0, 50);
        // 未显式返回 view 时，Worker Shim 会自动携带更新后的 state 重新调用 render() 刷新 UI
        return {
          state: { ...ctx.state, items: nextItems, draft: '' },
          toast: '已添加灵感便签',
        };
      }
      return { state: ctx.state };
    },
  },
};
```

当 `conversation.message.footer` 的插槽设置 `"action": { "type": "dispatch", "handler": "collect_message" }` 时，点击消息底栏按钮会在 `payload` 中收到 `{ messageId, conversationId, content }`，可直接存入插件状态或返回 `{ insertText, copyText, openSlot, toast }` 联动整个工作台。
