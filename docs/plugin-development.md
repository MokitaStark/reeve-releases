# Reeve 插件与主题开发完整指南

本指南面向希望为 **Reeve** 扩展自定义工具、原生工作台界面插槽（Plugin Slots）、项目技能（Skills）、团队内部连接器或液态玻璃外观主题的开发者，覆盖从「一句话对话生成插件」到「手写协议、安全自检与私有市场分发」的全流程。

---

## 一、最快起步：安装官方插件开发 AI 技能（Skills）

无论您使用 **Reeve 内置智能体**，还是使用 **Claude Code、Codex、Gemini CLI、Cursor、Antigravity** 等外部 AI 编码工具，都可以一键安装本仓库提供的官方插件编写 Skills，让 AI 自动遵循 Reeve 的清单规范、JSON-Line IPC 协议、7 大原生界面插槽契约与安全红线为您生成零缺陷插件：

```bash
# 一键安装全部 Reeve 官方插件与主题开发技能
npx skills add MokitaStark/reeve-releases

# 或按需单独安装某个技能
npx skills add MokitaStark/reeve-releases --skill reeve-plugin-dev
npx skills add MokitaStark/reeve-releases --skill reeve-theme-dev
```

- **在 Reeve 桌面端中一键导入**：打开 `设置 → 技能（Skills） → 命令安装`，直接输入 `MokitaStark/reeve-releases` 点击安装，系统会自动下载并导入技能库。
- **技能目录索引**：
  - [`skills/reeve-plugin-dev`](../skills/reeve-plugin-dev/SKILL.md)：覆盖 `worker` 动态工具插件、`config` 静态插件、7 大原生声明式插件槽（[UI 节点规范](../skills/reeve-plugin-dev/references/plugin-slots-ui.md)）与私有插件市场发布（[安全与市场规范](../skills/reeve-plugin-dev/references/marketplace-and-security.md)）。
  - [`skills/reeve-theme-dev`](../skills/reeve-theme-dev/SKILL.md)：覆盖 `kind: "theme"` 浅色/深色双模式毛玻璃表面、渐变背景与氛围光晕色板设计。
- **官方入门脚手架模板**：
  - [`examples/plugins/quick-starter`](../examples/plugins/quick-starter/README.md)：最小 Worker 工具与内置 Skill 示例。
  - [`examples/plugins/slot-starter`](../examples/plugins/slot-starter/README.md)：一次性挂载全部 7 大原生界面插槽、矢量 SVG 与交互表单的完整示例。
  - [`examples/plugins/theme-starter`](../examples/plugins/theme-starter/README.md)：双模式渐变与液态玻璃外观主题示例。

---

## 二、通过「创造模式（Create Mode）」对话式写插件

Reeve 原生内置了 **创造模式（`mode: "create"`）**，无需手工建目录或敲命令，直接在对话里用自然语言说出想法即可完成「代码生成 → 安装启用 → 逐槽渲染自检 → 界面实时挂载」：

1. **开启创造模式的三种入口**：
   - 点击对话输入框左下角模式选择器 → 切换为 **「创造模式」**；
   - 在输入框键入 `/` 选择 **`/create`** 指令；
   - 打开 **「设置 → 插件」**，点击右上角或空状态的 **「通过创造模式编写插件」**。
2. **自动化自检闭环**：
   创造模式会自动激活扩展开发工具组（`list_plugins`、`inspect_plugin_slots`、`install_plugin`、`manage_plugin`）。智能体写完代码后调用 `install_plugin`，后端会对所有声明的界面插槽自动执行 `slotVerification` 渲染自检，并通过实时事件让桌面端秒级刷新对应槽位。

---

## 三、Reeve 插件体系架构与三种形态

```text
┌──────────────────────┐   JSON-Line (stdin / stdout)   ┌─────────────────────────────┐
│  Reeve 原生后台宿主   │ ─────────────────────────────▶ │  隔离 Worker 子进程          │
│  (插件与安全沙箱引擎) │ ◀───────────────────────────── │  (.mjs/.ts/.js/.py/二进制)  │
└──────────────────────┘                                └─────────────────────────────┘
           │
           ├─▶ 动态注册 Agent 工具：plugin_<slug(id)>__<tool_name>
           ├─▶ 规划只读门禁（plan 模式）：仅放行 readOnly: true 的工具
           ├─▶ 原生插件槽渲染：将 PluginUINode 树映射为桌面 Liquid Glass 组件
           ├─▶ 自动挂载内置 Skills，并对输出执行敏感凭据脱敏
           └─▶ 环境变量安全白名单过滤与入参 JSON Schema 递归强校验
```

Reeve 支持三类 `reeve.plugin.json` 清单形态：

| 形态 | `kind` | 核心用途 | 子进程开销 |
| --- | --- | --- | --- |
| **动态工具与交互插槽插件** | `"worker"` | 封装外部 API / 数据库 / 本地 CLI 供智能体调用，或编写带状态交互的动态界面插槽 | 按需托管独立 Worker 子进程 |
| **纯配置与静态插槽插件** | `"config"` | 分发团队专属提示词快捷条、静态 SVG 装饰挂件、外链导航卡片或内置 `skills` | 零子进程开销（`tools: []`） |
| **外观配色主题插件** | `"theme"` | 定义浅色与深色双模式调色板、窗口线性渐变与氛围柔光光晕 | 纯静态 JSON 快照，不执行代码 |

---

## 四、5 分钟手写第一个 Worker 工具插件

### 1. 编写 `reeve.plugin.json`

```json
{
  "id": "quick-starter",
  "name": "插件开发入门示例",
  "version": "1.0.0",
  "description": "提供工作区只读概览与开发笔记沉淀工具",
  "kind": "worker",
  "entry": "index.mjs",
  "permissions": ["fs:project-read", "fs:project-write"],
  "tools": [
    {
      "name": "inspect_workspace",
      "description": "只读检查当前项目子目录文件概览。",
      "readOnly": true,
      "inputSchema": {
        "type": "object",
        "properties": {
          "subDir": { "type": "string", "description": "相对项目根目录的子路径，默认 ." }
        },
        "additionalProperties": false
      }
    },
    {
      "name": "write_note",
      "description": "向项目 .reeve/notes/ 目录写入一条 Markdown 笔记。",
      "readOnly": false,
      "inputSchema": {
        "type": "object",
        "properties": {
          "title": { "type": "string", "description": "笔记标题" },
          "content": { "type": "string", "description": "笔记正文" }
        },
        "required": ["title", "content"],
        "additionalProperties": false
      }
    }
  ],
  "skills": [
    {
      "name": "starter-plugin-usage",
      "description": "指导智能体先读后写安全使用 quick-starter。",
      "content": "# 使用约定\n\n1. 先调用 `inspect_workspace` 了解目录结构。\n2. 确认无误后再调用 `write_note` 沉淀记录。"
    }
  ]
}
```

### 2. 编写零依赖入口 `index.mjs`

```javascript
import { mkdir, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

export function resolveInsideWorkspace(rootPath, subPath = '.') {
  const base = path.resolve(rootPath || '.');
  const resolved = path.resolve(base, subPath || '.');
  const rel = path.relative(base, resolved);
  if (rel.startsWith('..') || path.isAbsolute(rel)) {
    throw new Error('禁止访问项目工作区之外的路径');
  }
  return { base, resolved, relative: rel || '.' };
}

export const tools = {
  async inspect_workspace(args = {}, context = {}) {
    const target = resolveInsideWorkspace(context.project?.rootPath, args.subDir || '.');
    const entries = await readdir(target.resolved, { withFileTypes: true });
    return {
      directory: target.relative,
      items: entries
        .filter((e) => e.name !== '.git' && e.name !== 'node_modules')
        .slice(0, 100)
        .map((e) => ({ name: e.name, type: e.isDirectory() ? 'dir' : 'file' })),
    };
  },

  async write_note(args = {}, context = {}) {
    const notesDir = resolveInsideWorkspace(context.project?.rootPath, '.reeve/notes').resolved;
    await mkdir(notesDir, { recursive: true });
    const safeName = String(args.title || 'note').replace(/[<>:"/\\|?*\x00-\x1f]/g, '-').slice(0, 80);
    const filePath = path.join(notesDir, `${safeName}.md`);
    await writeFile(filePath, `# ${args.title}\n\n${args.content}\n`, 'utf8');
    return { ok: true, path: `.reeve/notes/${safeName}.md` };
  },
};
```

> **关键防坑提醒**：
> Worker 与宿主通过 `stdin / stdout` 单行 JSON 通信，**插件代码中严禁调用 `console.log(...)` 或直接写入 `process.stdout`**，否则会破坏通信帧！同时安装器会自动忽略 `node_modules`，请优先使用 Node/Bun 标准内置模块，确保在 Bun 与 Node.js 环境下均可开箱运行。

---

## 五、原生声明式插件槽（Plugin Slots — 7 大挂载位）

无需引入笨重的 WebView 或 HTML iframe，插件只需在 `reeve.plugin.json` 的 `slots` 数组中声明挂载位置并返回声明式 JSON 节点树（`PluginUINode`），Reeve 桌面端即会使用原生 Liquid Glass 组件实时渲染：

| 标准插槽 (`slot`) | 兼容别名 | 桌面端呈现位置 |
| --- | --- | --- |
| `conversation.composer.dock` | `composer.dock`、`conversation.input.dock` | 对话输入框正上方的紧凑停靠条（快捷提示、计时器、SVG 小挂件） |
| `conversation.header.utilities` | `header.utilities`、`conversation.session.header.utilities` | 主区顶栏右侧计数/状态胶囊，点击可展开毛玻璃气泡卡片 |
| `main` | — | 左侧导航栏自动生成入口，点击在主内容区全幅渲染工作台页面 |
| `sidebar.nav` | `sidebar.panellist` | 左侧导航栏扩展入口（同 `id` 自动与 `main` 视图配对跳转） |
| `right_panel` | `sidebar.right.pane.tab`、`sidebar.right` | 顶栏工具胶囊图标及菜单项，点击展开右侧可拖拽分栏面板 |
| `conversation.starter` | `conversation.hero`、`starter` | 新对话空白欢迎页底部的推荐向导卡片 |
| `conversation.message.footer` | `conversation.chat.assistant-actions`、`message.footer` | 每条助手回复底栏附加动作按钮（自动携带消息 ID 与正文） |

- **22 种原生 UI 节点**：支持 `column`、`row`、`card`、`box`、`scroll`、`collapsible`、`text`、`markdown`、`code`、`svg`（经过严格安全白名单清洗的包内 `.svg` 或内联矢量图）、`badge`、`stat`、`progress`、`list_item`、`empty`、`divider`、`spacer`、`button`、`input`、`textarea`、`select`、`toggle`。
- **6 种确定性交互动作**：支持 `insert_text`（回填对话输入框）、`copy_text`、`open_url`（仅限 HTTPS/HTTP）、`open_slot`（跨槽位跳转）、`call_tool`（调用插件工具）与 `dispatch`（触发 `slots[slotId].action(handler, payload, ctx)` 更新持久化状态并热刷新界面）。
- 完整组件字典与动态代码示例请参阅 [`skills/reeve-plugin-dev/references/plugin-slots-ui.md`](../skills/reeve-plugin-dev/references/plugin-slots-ui.md) 及完整演示包 [`examples/plugins/slot-starter`](../examples/plugins/slot-starter/README.md)。

---

## 六、编写外观与渐变主题插件（`kind: "theme"`）

只需一个 `reeve.plugin.json` 文件即可为 Reeve 定制专属浅色/深色渐变毛玻璃皮肤（详见 [`skills/reeve-theme-dev/SKILL.md`](../skills/reeve-theme-dev/SKILL.md) 与 [`examples/plugins/theme-starter`](../examples/plugins/theme-starter/README.md)）：

- 顶层 `kind` 固定为 `"theme"`，`themes` 数组包含 1～20 套主题，每套主题的 `light` 与 `dark` 均须提供 `background` 和 `text`。
- 支持 `gradientFrom`、`gradientTo` 线性渐变与 `ambientGlow`、`ambientGlowSecondary` 8 位 Hex Alpha 柔光光晕，以及 `surface` 半透明毛玻璃表面色。
- 完成后在 **「设置 → 外观 → 主题插件 → 导入主题插件」** 选择文件或目录即可生效。

---

## 七、本地测试、安全红线与私有市场发布

1. **安全开发红线**：
   - 严禁将 API Key / Token 明文写入工作区配置文件，返回结果须主动遮蔽敏感凭据字段；
   - 外部带鉴权 HTTP 请求务必设置 `redirect: 'error'`，并禁止通过工具参数动态覆写鉴权目标域名；
   - 标记 `readOnly: true` 的工具严禁产生任何写副作用。
2. **本地单元测试**：
   ```bash
   bun test ./examples/plugins/quick-starter ./examples/plugins/slot-starter ./examples/plugins/theme-starter
   ```
3. **搭建团队插件市场（`registry.json`）**：
   将 `registry.json` 与 `.tar.gz` 插件包（附 `sha256` 校验摘要，单包上限 20 MB）托管在共享目录、内网或 GitHub Releases，团队成员即可在 **「设置 → 插件 → 插件市场 → 市场源管理 → 添加市场源」** 中填入路径或 HTTPS 地址，实现一键浏览、SHA-256 验签安装与热更新。详细字段规范见 [`marketplace-and-security.md`](../skills/reeve-plugin-dev/references/marketplace-and-security.md)。
