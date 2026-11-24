---
name: reeve-plugin-dev
description: 开发、调试、校验并发布 Reeve 桌面工作台插件（reeve.plugin.json）。当用户想要为 Reeve 编写新插件、扩展自定义 Agent 工具（worker 插件）、挂载原生界面插槽（Plugin Slots，如输入框停靠条、顶栏胶囊、主面板、右侧栏、消息底栏按钮、桌面小挂件、SVG 装饰）、使用创造模式（/create）定制工作台界面，或搭建团队私有插件市场（registry.json）时，务必使用此技能。
---

# Reeve 插件与原生插槽开发指南

本技能用于编写符合 Reeve Go 宿主校验契约的插件包（`kind: "worker"` 动态工具/插槽插件与 `kind: "config"` 静态配置/插槽插件）。若用户仅需制作配色与毛玻璃渐变外观主题（`kind: "theme"`），请优先参考同仓库的 `reeve-theme-dev` 技能。

## 1. 先选定插件类型

根据目标能力选择最轻量的 `kind`：

| 插件类型 | `kind` | 适用场景 | 是否启动子进程 |
| --- | --- | --- | --- |
| **纯配置 / 静态插槽插件** | `"config"` | 内置项目 `skills`、提示词快捷按钮、外链卡片、静态 SVG 挂件 | 否（`tools` 必须为空数组 `[]`，不设 `entry`） |
| **动态工具 / 交互插槽插件** | `"worker"` | 提供 Agent 可调用工具（API/DB/CLI 封装），或需要动态渲染状态、响应表单交互的插件槽 | 是（通过 `stdin/stdout` 单行 JSON 与 Go 宿主通信） |
| **外观配色主题插件** | `"theme"` | 定制工作台浅色/深色毛玻璃色板、渐变背景与氛围光晕 | 否（独立主题清单，见 `reeve-theme-dev`） |
| **生成式 UI 风格插件** | `"genui-style"` | 定制对话内 `render_ui` 交互卡片、图表色板、圆角与排版密度（跨桌面/移动端生效） | 否（见 `reeve-theme-dev/references/genui-style-plugins.md`） |

> **如果在 Reeve 应用内的「创造模式（`/create`）」下执行**：
> 1. 先调用 `list_plugins` 与 `inspect_plugin_slots` 获取当前已装插件与最新 7 大插槽契约；
> 2. 在工作区（推荐 `.reeve/plugins/<plugin-id>/`）生成插件文件；
> 3. 调用 `install_plugin`（传入相对路径，跨项目生效可传 `scope: "global"`），检查返回的 `slotVerification` 确保所有声明插槽均 `ok: true`。

---

## 2. 标准目录结构与核心铁律

```text
<plugin-id>/
├── reeve.plugin.json      # 必填：插件清单（<= 1 MiB，整个包 <= 20 MB）
├── icon.svg               # 可选：纯矢量图标（<= 256 KiB，禁 <script> 与 on*= 事件）
├── index.mjs              # worker 必填：ESM 入口，兼容 Bun 与 Node.js >= 20
└── <plugin-id>.test.mjs   # 推荐：单元测试（bun test）
```

### 四条不可违反的铁律（防踩坑）

1. **严禁污染 `stdout`**：Worker 进程通过 `stdin` / `stdout` 的 **JSON-Line（单行 JSON）** 与 Reeve Go 宿主通信。插件代码中**绝对禁止调用 `console.log` 或向 `process.stdout` 写入任何非协议文本**，否则会直接打断 IPC 帧解析导致调用失败！调试请用返回值或测试期 `console.error`。
2. **零 `node_modules` 依赖优先**：Reeve 安装插件时会自动跳过 `.git` 与 `node_modules` 目录，并拦截指向包目录外的符号链接。请仅使用语言标准库或 Bun/Node 内置模块（`node:fs/promises`、`node:path`、`node:http`、`node:crypto`、`fetch`）。
3. **只读门禁真实一致**：查询、探测、自省类工具必须声明 `"readOnly": true`（可在 Reeve `plan` 规划只读模式下放行），且内部严禁修改文件、数据库或远端状态；写操作工具设为 `"readOnly": false`。
4. **严格边界与凭据脱敏**：
   - 文件读写必须基于 `context.project.rootPath` 做 `path.resolve` 并拦截 `..` 路径穿越；
   - 禁止将明文 Token/密码写入 `.reeve/*.json`，引导用户使用环境变量；返回结果主动遮蔽 `Authorization`、`token`、`secret`、`password`、`Set-Cookie`；
   - 发起外部带鉴权 HTTP 请求时统一设置 `redirect: 'error'`，防止跨源重定向泄露凭据；
   - 执行系统命令必须使用参数数组形式（`execFile` / `spawn`），严禁拼接 Shell 字符串。

---

## 3. 清单 `reeve.plugin.json` 字段校验规范

| 字段 | 必填 | 校验规则 |
| --- | --- | --- |
| `id` | 是 | `^[a-z0-9][a-z0-9-]{0,79}$`（小写字母或数字开头，仅限小写字母、数字、连字符） |
| `name` | 是 | 显示名称，1～120 字符 |
| `version` | 是 | 标准 SemVer：`^\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?$`（如 `"1.0.0"`） |
| `description` | 推荐 | 插件用途说明，在设置页与插件市场展示 |
| `kind` | 是 | `"worker"` 或 `"config"` |
| `entry` | `worker` 必填 | 包内相对入口路径（推荐 `"index.mjs"`；也支持 `.js` / `.ts` / `.py` / 可执行文件） |
| `icon` | 可选 | 包内 `.svg` 相对路径（如 `"icon.svg"`）或内置图标名（如 `"spark"`、`"plugin"`） |
| `tools` | 是 | 数组（0～100 项；`config` 模式必须为 `[]`）。每项必含 `name`、`description`、`inputSchema` |
| `tools[].name` | 是 | `^[a-z][a-z0-9_]{0,59}$`（小写字母开头，小写字母、数字、下划线） |
| `tools[].inputSchema` | 是 | 标准 JSON Schema（顶层 `"type": "object"`，推荐设 `"additionalProperties": false`），宿主会递归强校验入参 |
| `tools[].readOnly` | 推荐 | `true` 表示纯只读工具；`false`（默认）表示会产生副作用 |
| `tools[].timeoutMs` | 可选 | 单次调用超时毫秒数（默认 `30000`，最高 `600000` 即 10 分钟） |
| `slots` | 可选 | 原生声明式界面插槽数组（最多 20 个），详见 `references/plugin-slots-ui.md` |
| `skills` | 可选 | 随插件注入的技能数组：`[{ "name", "description", "content" }]` |
| `permissions` | 可选 | 权限声明标签（如 `["fs:project-read", "fs:project-write", "network:http"]`） |

> 注册后的 Agent 工具全名为 `plugin_<id将连字符转为下划线>__<tool_name>`（例如插件 `git-forge` 的 `list_prs` 注册为 `plugin_git_forge__list_prs`）。

---

## 4. Worker 模块标准模板（`index.mjs`）

对于 `.mjs` / `.js` / `.ts` 插件，Reeve 宿主会自动注入 JSON-Line IPC Shim，插件只需导出 `tools`、可选生命周期钩子 `activate` / `deactivate` 及可选插槽处理器 `slots`：

```javascript
import { mkdir, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

export function resolveInsideWorkspace(rootPath, subPath = '.') {
  const base = path.resolve(rootPath || '.');
  const resolved = path.resolve(base, subPath || '.');
  const rel = path.relative(base, resolved);
  if (rel.startsWith('..') || path.isAbsolute(rel)) {
    throw new Error('不允许访问项目工作区之外的路径');
  }
  return { base, resolved, relative: rel || '.' };
}

export async function activate(context) {
  // 初始化超时 10s；严禁在此处调用 console.log
}

export async function deactivate() {
  // 退出清理优雅等待 3s
}

// 键名必须完整覆盖 reeve.plugin.json 中声明的所有 tools[].name
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

  async save_note(args = {}, context = {}) {
    const notesDir = resolveInsideWorkspace(context.project?.rootPath, '.reeve/notes').resolved;
    await mkdir(notesDir, { recursive: true });
    const safeTitle = String(args.title || 'note').replace(/[<>:"/\\|?*\x00-\x1f]/g, '-').slice(0, 80);
    const fullPath = path.join(notesDir, `${safeTitle}.md`);
    await writeFile(fullPath, `# ${args.title}\n\n${args.content}\n`, 'utf8');
    return { ok: true, path: `.reeve/notes/${safeTitle}.md` };
  },
};
```

---

## 5. 原生界面插槽（Plugin Slots）速览

Reeve 采用零 WebView 的原生 Liquid Glass 声明式 UI 树（`PluginUINode`），支持挂载到 **7 个标准桌面位置**：

1. `conversation.composer.dock`：对话输入框正上方停靠条（适合快捷提示按钮、番茄钟、SVG 小挂件）
2. `conversation.header.utilities`：主区顶栏右侧胶囊（支持状态徽标 + 点击弹出毛玻璃气泡卡片）
3. `main`：主内容区全幅工作台页面（自动在左侧栏生成导航入口）
4. `sidebar.nav`：左侧导航栏扩展入口（同 `id` 自动与 `main` 视图配对合并）
5. `right_panel`：顶栏工具胶囊图标 + 右侧可拖拽分栏面板
6. `conversation.starter`：新对话空白欢迎页底部的推荐引导卡片
7. `conversation.message.footer`：每条助手消息底栏附加操作按钮（自动携带 `{ messageId, conversationId, content }`）

**需要编写 `slots` 界面组件、SVG 插画、表单状态或交互动作时，请务必先读取**：
- `references/plugin-slots-ui.md`：包含全部 22 种 `PluginUINode` 节点字段、语义色 `tone`、6 种 `Action` 协议及动态 `slots` 代码范式。

---

## 6. 单元测试、安装验证与市场发布

编写插件后，始终创建配套测试并执行验证：

1. **校验清单与导出对齐**：断言 `reeve.plugin.json` 的 `tools[].name` 在 `Object.keys(tools)` 中全部存在，且 `slots` 渲染返回合法节点树。
2. **运行测试与双运行时验证**：
   ```bash
   bun test ./<plugin-dir>
   node -e 'import("./<plugin-dir>/index.mjs").then(m => console.error("Loaded tools:", Object.keys(m.tools || {})))'
   ```
3. **安装与启用**：
   - 在 Reeve 创造模式直接调用 `install_plugin`；
   - 或指引用户在桌面端「设置 → 插件 → 安装本地插件」选择该插件目录并启用。
4. **需要编写 Python/二进制 Worker 或发布到团队自定义插件市场（`registry.json` + `.tar.gz` SHA-256 校验）时，请读取**：
   - `references/marketplace-and-security.md`
