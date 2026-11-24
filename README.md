<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/logo/reeve-logo-dark.png" />
  <source media="(prefers-color-scheme: light)" srcset="assets/logo/reeve-logo.png" />
  <img src="assets/logo/reeve-logo.png" alt="Reeve" width="440" />
</picture>

# Reeve · 原生多智能体工程与个人工作台

**Reeve** 是一款本地优先（Local-First）、采用 **Apple 原生液态玻璃（Liquid Glass）** 设计语言的跨平台多智能体桌面工作台。它将**多智能体自动编排（Orchestrator）**、**跨智能体实时共享黑板**、**Aide 个人知识与灵感空间**、**全栈宿主机工程套件**、**LoopForge 2D 自动化流程画布**、**移动端远程协同控制台**与**原生声明式插件生态**融为一体——让你既能随时开启多角色智囊团头脑风暴，又能指挥一支纪律严明的 AI 工程团队在隔离 Git Worktree 沙箱中并行编码、交叉验收并安全交付。

安装包已完整内置原生后台守护引擎与本地 SQLite 数据库，**零外部运行时依赖，安装后直接打开即可使用**。

> **仓库说明**：本仓库（[`MokitaStark/reeve-releases`](https://github.com/MokitaStark/reeve-releases)）是 Reeve 的**官方公开发布与插件生态中心**，提供经 Ed25519 数字签名的跨平台安装包、一键环境检测安装脚本、自动更新公钥，以及面向开发者的**官方插件编写 AI 技能包（Skills）、开发文档与示例模板**。

- **当前最新版本**：**`v0.1.010`**（[查看更新日志](CHANGELOG.md) · [前往 Releases 下载页](https://github.com/MokitaStark/reeve-releases/releases/latest) · [插件编写指南与 Skills](#插件编写指南与-ai-技能包skills)）

---

## 目录

- [一键安装与环境检测](#一键安装与环境检测安装即用)
- [核心能力全景](#核心能力全景)
- [插件编写指南与 AI 技能包（Skills）](#插件编写指南与-ai-技能包skills)
- [快速上手](#快速上手3-步开启多智能体协作)
- [安全验签与平滑自动更新](#安全验签与平滑自动更新)

---

## 一键安装与环境检测（安装即用）

Reeve 提供跨平台**宿主机环境自动诊断与一键验签安装脚本**。脚本会自动识别操作系统与芯片架构、检测本机可选工具链（Git、Ripgrep、Node/Bun、Chrome/Chromium 与外部编码 CLI）、使用内置 Ed25519 公钥校验发布清单签名，并自动安装最新版 Reeve 桌面客户端。

### 方式一：命令行一键检测并安装（推荐）

#### macOS（Apple Silicon M1–M4）与 Linux（x86_64）

```bash
curl -fsSL https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.sh | sh
```

进阶选项：

```bash
# 自动调用系统包管理器（brew / apt / dnf / pacman）补齐缺失推荐工具（git / rg / node / Linux GTK4）后安装 Reeve
curl -fsSL https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.sh | sh -s -- --install-deps

# 仅执行宿主机环境诊断（不下载安装）
curl -fsSL https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.sh | sh -s -- --check-only

# 卸载 Reeve 客户端（保留个人配置与本地项目数据库）
curl -fsSL https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.sh | sh -s -- --uninstall
```

#### Windows（x64 / ARM64，PowerShell）

```powershell
irm https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.ps1 | iex
```

如需在 Windows 下通过 `winget` 自动补齐缺失的 Git、Ripgrep 与 Node.js 环境：

```powershell
$env:REEVE_INSTALL_DEPS="1"; irm https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.ps1 | iex
```

### 方式二：直接下载官方签名安装包

您也可以前往 [**Releases 下载页**](https://github.com/MokitaStark/reeve-releases/releases/latest) 直接下载对应平台的安装包：

| 平台与架构 | 官方安装包直链（`v0.1.010`） | 安装说明 |
| --- | --- | --- |
| **macOS**（Apple Silicon `arm64`，macOS 12+） | [**`reeve-0.1.010-arm64.dmg`**](https://github.com/MokitaStark/reeve-releases/releases/download/desktop-v0.1.010/reeve-0.1.010-arm64.dmg) | 打开 `.dmg` 将 `Reeve.app` 拖入「应用程序」即可运行 |
| **Windows**（64 位 `x64`） | [**`reeve-setup-0.1.010-amd64.exe`**](https://github.com/MokitaStark/reeve-releases/releases/download/desktop-v0.1.010/reeve-setup-0.1.010-amd64.exe) | 双击运行安装向导，自动创建桌面与开始菜单快捷方式 |
| **Windows**（骁龙 / Surface `ARM64`） | [**`reeve-setup-0.1.010-arm64.exe`**](https://github.com/MokitaStark/reeve-releases/releases/download/desktop-v0.1.010/reeve-setup-0.1.010-arm64.exe) | 原生 ARM64 安装程序，双击安装即用 |
| **Linux**（64 位 `x86_64`） | [**`reeve-0.1.010-linux-amd64.tar.gz`**](https://github.com/MokitaStark/reeve-releases/releases/download/desktop-v0.1.010/reeve-0.1.010-linux-amd64.tar.gz) | 配合上方 `install.sh` 自动安装至 `~/.local/reeve.app` 并注册桌面菜单 |

---

## 核心能力全景

### 1. 内置多智能体编排器与 Git Worktree 并发沙箱
告别繁琐的手动预建角色，Reeve 将多智能体编排器直接集成在输入框底部的选择器与 `/` 斜杠指令中：

- **自动编排器（`/orchestrator`）**：主控模型根据任务复杂度动态决策——简单问答直接响应；复杂工程自动按需创建专业角色（架构师、前后端、测试、安全审查）并委派协同。
- **蜂群并行（`/swarm`）+ 自动 Worktree 沙箱隔离**：自动将跨模块重构或大规模排查拆解为互不重叠的独立分片并发推进；系统自动为每个编码子智能体分配独立 **Git Worktree 沙箱分支**，完成后支持 `/worktrees` 一键审阅聚合 Diff、冲突预检与批量合入，彻底杜绝并发改坏同一份文件。
- **团队协同（`/teamwork`）与实时共享黑板（`/board`）**：按「方案设计 → 核心实现 → 交叉审查与测试验收」接力推进；任何子智能体均可通过 `post_team_message` 向共享黑板实时发布**接口契约（`contract`）**、**关键发现（`finding`）**、**交接事项（`handoff`）**与**风险（`risk`）**，同轮并发同伴下一步即可增量感知。
- **云端 API + 本地 Agent CLI 双引擎混编**：支持 OpenAI、Anthropic Claude、Google Gemini、DeepSeek 等协议及自定义网关，同时可将本机安装的 **Claude Code、Codex、Gemini CLI、Aider、OpenCode、Goose** 直接纳管为团队成员（支持应用内一键检测安装）。

### 2. Apple 原生液态玻璃桌面、生成式 UI（GenUI）与灵动岛/桌宠交互
- **液态玻璃皮肤与官方渐变主题**：默认搭载「Apple 原生」液态玻璃界面（全高悬浮侧栏、跟随系统强调色），内置蔚蓝、极光薄荷、深海青、樱粉、暮光紫、落日琥珀 **6 套双模式渐变与氛围光晕主题**。
- **对话内原生生成式 UI（`render_ui`）与可扩展风格引擎**：无需笨重的内嵌 WebView，对话流原生渲染 **KPI 指标磁贴（含 Sparkline 迷你走势）**、**多序列折线/柱状/面积/环形图**、**可排序状态表格**、**方案优劣对比卡**、**时间线**、**交互核对清单**与**分段标签页**（桌面端与手机端一致呈现）；内置 `Reeve 原生`、`shadcn/ui`、`Linear 极客`、`Editorial 出版物`、`Terminal 工程` 5 套预设及 `Catppuccin 柔彩`、`Vercel Geist` 等风格包。
- **macOS 菜单栏胶囊、刘海灵动岛与边缘贴靠灵动球（Pet Orb）**：支持在不打断心流的前提下通过灵动岛或屏幕边缘自动收拢悬浮球实时偷看进度（Live Peek）、快捷截图、秒切工作区，并在全屏演示时自动隐身避让；多智能体长任务运行期间自动启用**智能防系统休眠**。
- **三套对话视图 + 横向并排对比 + Worker 钻取**：顶栏一键切换**文档流**、**气泡流**与**时间线**；使用 `@全体成员` 同题并发时支持横向**「并排对比」**与一键汇总结论；点击任意子智能体卡片可弹窗钻取流式推理、工具耗时轨迹、黑板通信与变更文件账本。

### 3. Aide 全局个人空间、交互式知识图谱与移动端远程协同
- **Aide 个人空间（知识图谱 · 每日简报 · 灵感火花 · 媒体图库）**：无需先建代码仓即可直接开聊，内置**每日简报（Briefing）**、**灵感火花（Sparks）**、多模态**知识库与力导向交互式知识图谱（`Knowledge Graph`）**及**媒体图库（`Gallery`）**，可视化串联文档、产物、长期记忆与标签；讨论成熟后点击**「以此新建工作项目…」**即可携带结论无缝跃迁至工程目录。
- **手机端远程协同控制台（LAN / Tailscale）**：在「设置 → 移动端与远程」开启局域网或 Tailscale 安全监听，通过 5 分钟单次有效 **6 位配对码**或双模式二维码扫码接入手机 App / 浏览器 `/mobile` 控制台——离开电脑也能在手机上实时同步会话焦点、查看生成式 UI 卡片、回答分步单题向导、远程批准高危工具调用或一键紧急暂停。

### 4. 四列看板、LoopForge 2D AI 画布、检查点回滚与热敏小票账单
- **四列任务 DAG 看板与客观验收门禁**：支持「待开始 / 进行中 / 待验收 / 已完成」拖拽流转与父子任务依赖拓扑，绑定真实测试命令进行客观验收核验。
- **LoopForge 2D 自动化流程画布**：支持四端口贝塞尔连线（含失败自动返工回边）、自然语言 AI 自动生成流程图、节点单步试跑、人工审批门与标准 **5 段 Cron 表达式**定时巡检。
- **两级权限审批与每轮自动检查点回滚**：支持「请求批准 / 完全访问」实时权限门控；文件修改自动生成轮次快照，随时通过 `/checkpoints` 与 `/rollback` 冲突感知预览并安全回滚。
- **热敏票据风格高清 AI 账单（`/bill`）**：内置工具返回智能压缩引擎节省上下文 Token；支持一键生成单轮或整场对话的 **2x Retina 热敏纸小票海报**与每日用量报表，原生支持 `USD ($)` / `CNY (¥)` 汇率实时换算与 CSV 导出。

### 5. 全栈宿主机工程工具箱
右侧与底部集成零切屏原生工程面板：**版本乐观锁代码编辑器**、**Git 多仓与沙箱管理**、**多标签交互式 PTY 终端**、**Chrome CDP 自动化浏览器（Browser Use）**、**跨 macOS / Windows / Linux 零 CGO 原生桌面无障碍控制（Computer Use + 画中画观察窗）**、**双向 MCP（Client + Server）**、**生命周期 Hooks** 以及 **22 款自带原生右侧诊断面板与矢量图标的官方内置插件**（涵盖 Docker、Kubernetes、SQLite/PG/MySQL、Redis、S3、HTTP 调试、GitHub/GitLab、Vercel、Supabase、Cloudflare、Sentry、Linear、Notion、Slack、飞书、Stripe、页面探针、CVE 依赖审计与 Unity / Unreal / Godot 引擎）。

---

## 插件编写指南与 AI 技能包（Skills）

Reeve 拥有安全隔离、零 WebView 开销的本地插件与原生界面插槽体系。为了让开发者与 AI 编码助手都能在几分钟内构建出高质量插件，本仓库直接提供**官方插件编写 Skills**、**完整中文开发手册**与**可运行脚手架模板**。

### 1. 一键安装官方插件编写 Skills（推荐）

无论您是在 **Reeve** 中开发，还是使用 **Claude Code、Codex、Gemini CLI、Cursor、Antigravity** 等 AI 编程工具，只需一条命令即可安装官方插件开发技能包：

```bash
# 一键安装全部 Reeve 官方插件与主题开发技能
npx skills add MokitaStark/reeve-releases

# 也可按需单独安装指定技能
npx skills add MokitaStark/reeve-releases --skill reeve-plugin-dev
npx skills add MokitaStark/reeve-releases --skill reeve-theme-dev
```

> **在 Reeve 桌面端内图形化安装**：打开 `设置 → Skills → 命令安装`，输入 `MokitaStark/reeve-releases` 点击安装，Reeve 会自动拉取并导入启用以下两套技能：

| 官方技能名称 | 适用场景与核心能力 | 技能文档直达 |
| --- | --- | --- |
| **`reeve-plugin-dev`** | 指导 AI 编写 `worker` 工具插件、`config` 配置插件、**7 大原生界面插槽（Plugin Slots）**声明式 UI、矢量 SVG 挂件、单元测试及 `registry.json` 插件市场配置 | [SKILL.md](skills/reeve-plugin-dev/SKILL.md) · [插槽 UI 字典](skills/reeve-plugin-dev/references/plugin-slots-ui.md) · [市场与安全规范](skills/reeve-plugin-dev/references/marketplace-and-security.md) |
| **`reeve-theme-dev`** | 指导 AI 设计并校验 `kind: "theme"` 液态玻璃渐变主题插件，以及 `kind: "genui-style"` **对话生成式 UI 视觉风格插件**（圆角/密度/图表色板跨桌面与移动端同步生效） | [SKILL.md](skills/reeve-theme-dev/SKILL.md) · [GenUI 风格规范](skills/reeve-theme-dev/references/genui-style-plugins.md) |

### 2. 零代码方式：在 Reeve「创造模式（`/create`）」中对话写插件

无需手动创建文件或敲终端命令，直接在 Reeve 对话框中即可完成「需求描述 → 自动编码 → 安装自检 → 界面热挂载」：

1. 在对话输入框输入 **`/create`**（或左下角模式切换为「创造模式」，也可在 `设置 → 插件` 点击 **「通过创造模式编写插件」**）。
2. 用自然语言说出你的想法，例如：
   - *“帮我在输入框上方做一个番茄钟与快捷代码走查停靠条，带精美的矢量图标”*
   - *“帮我写一个右侧栏灵感便签插件，支持把助手回复一键收藏进来”*
3. 智能体会自动调用 `inspect_plugin_slots` 读取插槽协议，在工作区编写代码后调用 `install_plugin` 执行 **`slotVerification` 逐槽渲染自检**，通过后插件立即出现在您的 Reeve 界面上。

### 3. 手动 / 脚手架开发：四大原生插件形态速览

您可以直接参考完整手册 [**《Reeve 插件与主题开发完整指南》**](docs/plugin-development.md) 或克隆本仓库的 `examples/plugins/` 模板起步：

| 插件形态 | 清单 `kind` | 核心结构与能力说明 | 官方入门模板 |
| --- | --- | --- | --- |
| **工具与动态插槽插件** | `"worker"` | 包含 `reeve.plugin.json` + 零依赖 `index.mjs`（兼容 Bun 与 Node.js >= 20），通过 `stdin/stdout` JSON-Line 导出 `tools` 与动态 `slots` | [examples/plugins/quick-starter](examples/plugins/quick-starter/README.md)<br>[examples/plugins/slot-starter](examples/plugins/slot-starter/README.md) |
| **静态配置与插槽插件** | `"config"` | 仅需 `reeve.plugin.json`（`tools: []`，零子进程开销），适合分发内置 `skills`、静态快捷按钮条或 SVG 装饰卡片 | 见 [开发指南 §五](docs/plugin-development.md#五原生声明式插件槽plugin-slots--7-大挂载位) |
| **液态玻璃渐变主题** | `"theme"` | 纯声明式 JSON 定义 `themes[].light / dark` 共 19 个色彩与渐变光晕令牌，在 `设置 → 外观` 一键导入热切换 | [examples/plugins/theme-starter](examples/plugins/theme-starter/README.md) |
| **生成式 UI 视觉风格** | `"genui-style"` | 纯声明式 JSON 定义对话 `render_ui` 卡片圆角、密度、图表曲线与双模式 8 色图表色板，在 `设置 → 生成式 UI` 导入并跨桌面/手机同步生效 | [examples/plugins/genui-style-starter](examples/plugins/genui-style-starter/README.md) |

#### 原生插件槽（Plugin Slots）支持的 7 大挂载位置

Reeve 将插件返回的声明式 JSON 节点树（22 种 `PluginUINode` 组件 + 安全清洗矢量 `.svg` + 6 种交互 `Action`）直接渲染为原生桌面组件：

- `conversation.composer.dock`：对话输入框正上方停靠条（快捷提示词、计时器、SVG 小挂件）
- `conversation.header.utilities`：主区顶栏右侧状态胶囊（支持点击展开毛玻璃微面板）
- `main`：主内容区全幅工作台面板（左侧栏自动生成导航入口）
- `sidebar.nav`：左侧导航栏扩展入口（同 `id` 自动与 `main` 主面板配对合并）
- `right_panel`：顶栏工具胶囊图标 + 右侧可拖拽分栏面板
- `conversation.starter`：新对话空白欢迎页底部的创作引导卡片
- `conversation.message.footer`：每条助手消息底栏附加操作按钮（自动传入消息 ID 与正文）

#### 插件开发四条黄金守则

1. **严禁污染 `stdout`**：Worker 通过 `stdin/stdout` 单行 JSON 通信，代码中**禁止调用 `console.log`**（调试可用返回值或测试期 `console.error`）。
2. **零 `node_modules` 标准库优先**：宿主安装时自动跳过 `node_modules` 与外部符号链接，请使用 Node/Bun 标准内置模块（单包上限 20 MB）。
3. **只读声明真实一致**：纯查询工具显式标记 `"readOnly": true` 以适配 `plan` 规划只读门禁，且内部严禁产生写操作。
4. **路径防穿越与凭据脱敏**：文件操作须校验在 `context.project.rootPath` 边界内；不落盘明文密钥，外部鉴权请求设置 `redirect: 'error'` 并对输出敏感字段主动脱敏。

#### 本地测试与团队私有插件市场（`registry.json`）

```bash
# 使用 Bun 运行全部四类示例插件与风格合规单测
bun test ./examples/plugins/quick-starter ./examples/plugins/slot-starter ./examples/plugins/theme-starter ./examples/plugins/genui-style-starter
```

- **本地安装**：打开 Reeve `设置 → 插件 → 安装本地插件`，选择包含 `reeve.plugin.json` 的目录即可启用。
- **团队市场分发**：将 `registry.json` 与 `.tar.gz` 插件包（附 `sha256` 校验摘要）托管至内网、Git 仓库或 GitHub Releases，团队成员在 `设置 → 插件 → 插件市场 → 添加市场源` 填入地址即可一键浏览、验签安装与热更新。

---

## 快速上手（3 步开启多智能体协作）

1. **连接模型或一键纳管本地 CLI**：
   - 打开 Reeve，按 `⌘,`（Windows / Linux `Ctrl+,`）进入 **「设置 → 提供商」** 配置模型 API Key；
   - 或进入 **「设置 → Agent CLI」**，一键扫描并点击安装 Claude Code、Codex、Gemini CLI 等命令行智能体。
2. **在个人空间或工程项目中发起协作**：
   - 直接在左侧 **「个人空间」** 开启对话与知识沉淀，或新建/打开本地代码仓库；
   - 在输入框底部选择 **「自动编排器」**、**「蜂群并行 `/swarm`」** 或 **「团队协同 `/teamwork`」**，也可输入 **`/create`** 定制专属工作台插件。
3. **审阅、对比、验收与远程协同**：
   - 顶栏自由切换「文档流 / 气泡流 / 时间线」或「并排对比」，通过 `/worktrees` 一键合入无冲突沙箱分支，使用 `/bill` 查阅热敏小票账单，或扫码连接手机远程随时审批推进。

---

## 安全验签与平滑自动更新

- **Ed25519 数字签名防篡改**：每次发布的平台更新清单（`update-<target>.json`）、全量包、增量差分包（`.delta`）以及校验和文件（`SHA256SUMS` / `SHA256SUMS.sig`）均经过离线私钥签名，公开验证公钥固定于本仓库根目录的 [`update.pub`](https://github.com/MokitaStark/reeve-releases/blob/main/update.pub)。
- **免限流应用内自动更新**：桌面端内置自研更新管理器（`设置 → 应用更新`），支持稳定版与 Beta 预发布通道静默下载、增量升级及**升级前自动本地数据库备份**，全程直连静态签名资产，不受 GitHub API 匿名速率限制影响。
