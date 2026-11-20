<img src="assets/logo/reeve-logo.png" alt="Reeve" width="460" />

# Reeve · 原生多智能体工程与个人工作台

**Reeve** 是一款本地优先（Local-First）、开箱即用的原生多智能体桌面工作台。它将**多智能体自动编排（Orchestrator）**、**跨智能体实时通信黑板**、**全局个人空间**、**全栈工程工作区**与**2D 可视化自动化流程画布**融为一体——让你既能像和智囊团聊天一样推演想法，又能指挥一支分工明确的 AI 工程团队操作本地文件、Git 分支、终端、浏览器与桌面应用，完成从灵感到代码交付与自动化验收的完整闭环。

安装包已内置全量后台服务与本地数据库引擎，**零外部运行时依赖，安装后直接打开即可使用**。

- **当前版本**：**`v0.1.001`**（[查看更新日志](CHANGELOG.md) · [前往 Releases 下载页](https://github.com/chengyunyi/reeve-releases/releases/latest)）

---

## 一键安装与环境检测（安装即用）

Reeve 提供跨平台**环境自动检测与一键安装脚本**。脚本会自动识别您的操作系统与芯片架构、检测本机可选工具环境（Git、Ripgrep、Node/Bun、浏览器与外部编码 CLI），并自动下载安装最新版 Reeve 桌面客户端。

### 方式一：命令行一键检测环境并自动安装（推荐）

#### macOS（Apple Silicon M1–M4）与 Linux（x86_64）

```bash
curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh
```

进阶选项：

```bash
# 自动检测并调用系统包管理器（brew / apt / dnf / pacman）一键补齐缺失的推荐工具（git / rg / node / Linux GTK4），随后安装 Reeve
curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --install-deps

# 仅执行宿主机环境诊断（不下载安装）
curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --check-only

# 卸载 Reeve（保留个人配置与项目数据）
curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --uninstall
```

#### Windows（x64 / ARM64，PowerShell）

```powershell
irm https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.ps1 | iex
```

如需在 Windows 下通过 `winget` 自动补齐缺失的 Git、Ripgrep 与 Node.js 环境：

```powershell
$env:REEVE_INSTALL_DEPS="1"; irm https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.ps1 | iex
```

### 方式二：直接下载官方安装包

您也可以在 [**Releases 下载页**](https://github.com/chengyunyi/reeve-releases/releases/latest) 直接下载对应系统的官方安装包：

| 平台与架构 | 官方安装包直链（`v0.1.001`） | 安装说明 |
| --- | --- | --- |
| **macOS**（Apple Silicon `arm64`） | [**`reeve-0.1.001-arm64.dmg`**](https://github.com/chengyunyi/reeve-releases/releases/download/desktop-v0.1.001/reeve-0.1.001-arm64.dmg) | 打开 `.dmg` 将 `Reeve.app` 拖入「应用程序」即可运行 |
| **Windows**（64 位 `x64`） | [**`reeve-setup-0.1.001-amd64.exe`**](https://github.com/chengyunyi/reeve-releases/releases/download/desktop-v0.1.001/reeve-setup-0.1.001-amd64.exe) | 双击运行安装向导，自动创建桌面与开始菜单快捷方式 |
| **Windows**（骁龙 / Surface `ARM64`） | [**`reeve-setup-0.1.001-arm64.exe`**](https://github.com/chengyunyi/reeve-releases/releases/download/desktop-v0.1.001/reeve-setup-0.1.001-arm64.exe) | 原生 ARM64 安装程序，双击安装即用 |
| **Linux**（64 位 `x86_64`） | [**`reeve-0.1.001-linux-amd64.tar.gz`**](https://github.com/chengyunyi/reeve-releases/releases/download/desktop-v0.1.001/reeve-0.1.001-linux-amd64.tar.gz) | 配合上方 `install.sh` 自动安装至 `~/.local/reeve.app` 并注册桌面菜单 |

---

## 为什么选择 Reeve？—— 核心能力全景

### 1. 内置多智能体编排器（Orchestrator）：从单打独斗到军团作战
传统 AI 工具往往需要用户手动预设一堆繁琐的 Agent 角色。Reeve 将**编排器**直接内置在输入框底部的「选用模型」选择器中，支持会话按需自动组建并调度专家团队：

- **自动编排器**：主控模型根据任务复杂度自行判断是否需要帮手——简单问题直接作答；复杂工程自动创建专业角色（如架构师、前端、后端、测试、安全审计）并委派子智能体并行或接力完成。
- **蜂群并行 `/swarm`**：面对跨模块大规模重构、多维度调研或全仓排查，主控编排器自动将任务拆解为互不重叠的独立分片，同时派生多路子智能体并发执行，耗时成倍缩短。
- **团队协同 `/teamwork`**：按照「方案拆解 → 编码实现 → 交叉审查与测试验证 → 汇总交付」的工程纪律组织多角色协作，确保每一处改动都经过二次把关。
- **API 大模型 + 外部编码 CLI 双引擎混编**：不仅支持 OpenAI、Anthropic Claude、Google Gemini、DeepSeek 等各大模型服务与本地网关，还能将本机安装的 **Claude Code、Codex、Gemini CLI、Aider、OpenCode、Goose** 等命令行智能体直接纳管为团队成员（可在应用内「设置 → Agent CLI」一键检测与安装），实现云端 API 与本地 CLI 的混合编排。

### 2. 真正的跨智能体实时通信：共享协作黑板（Shared Blackboard）
多智能体协作最怕“各自为战、互不知情、改坏同一份文件”。Reeve 构建了三层智能体相互通信机制：

- **主动黑板通信（`post_team_message`）**：任何子智能体在执行途中都可随时向会话共享黑板发布**接口契约（`contract`）**、**关键发现（`finding`）**、**交接事项（`handoff`）**或**风险阻塞（`risk`）**，支持 `@指定角色` 点对点投递或向全员广播；同一轮并发运行的其他子智能体会在下一步推理中**实时收到同伴刚发布的黑板消息**。
- **三维自动上下文感知**：每当子智能体被委派时，系统自动向其注入**主会话用户原始诉求**、**同轮并发同伴的分工边界**（防止重复修改同一模块）以及**上游角色已交付的结论与变更文件账本（`ChangedFiles`）**。
- **动态 `@点名交接`**：在顺序接力（`chain`）中，前序智能体可根据实际发现，通过 `@角色名` 或黑板交接消息动态指定下一棒最适合接手的专家角色。

### 3. 三套自适应对话样式 + 并排对比 + 深度执行钻取
不同的协作场景需要不同的信息呈现方式，Reeve 提供三套原生对话视图并支持顶栏一键切换：

- **文档流（Document）**：高密度沉浸式排版，适合深度代码审阅、长篇架构设计与技术报告。
- **气泡流（Bubble）**：角色头像、身份色卡与消息气泡层次分明，适合个人空间日常对话与多智能体群聊讨论。
- **时间线（Timeline）**：左侧连续演进轨道串联每一次委派、工具调用与阶段节点，复杂多智能体脉络一目了然。
- **`@全体成员` 同题并行与横向「并排对比」**：一键召唤多位角色同时回答同一问题，切换「并排对比」视图即可横向对照各专家的推理过程、工具调用胶囊与最终方案，并支持一键**「汇总结论」**。
- **子智能体 Worker 钻取详情弹窗**：点击对话流中的任意子智能体工作卡片，即可弹窗查看其实时流式思考、每一步工具调用的耗时轨迹、跨智能体黑板通信记录以及本次修改的文件列表。

### 4. 「全局个人空间」与「工程项目工作区」无缝流转
- **打开即聊的个人空间**：无需先建文件夹或绑定代码仓库，启动 Reeve 即可在全局「个人空间」与内置的「个人助手」「思维与写作」「技术顾问」随时开启头脑风暴、方案推演与日常写作，自动沉淀跨项目个人偏好与记忆。
- **一键跃迁为工作项目**：当个人空间中的多智能体讨论成型后，点击会话顶栏**「以此新建工作项目…」**，即可自动携带多智能体最新讨论结论初始化工程目录，直接进入编码落地阶段。

### 5. 四列任务看板、LoopForge 2D 自动化画布与客观验收门禁
- **四列任务看板与任务 DAG**：区分日常讨论的「普通对话」与面向交付的「任务对话」。任务对话自动进入「待开始 / 进行中 / 待验收 / 已完成」四列拖拽看板，支持父子任务依赖拓扑（DAG）拆解合并、断点检查点交接与统一预算控制。
- **客观测试门禁（Verification Gate）**：工作是否真正完成不靠模型“自称完成”，而是由后台绑定实际测试命令与验证指纹进行客观核验，未通过验证自动进入缺陷闭环。
- **LoopForge 2D 交互式自动化流程画布**：支持以「对话模式」或「2D 节点画布」编排自动化任务——自由拖拽 **Agent 执行节点**、**脚本与文件验证节点**、**人工审批门**与**产物汇总节点**，配置**失败自动返工回边（Rework-on-Failure）**，并支持手动触发、固定间隔或标准 **5 段 Cron 表达式**定时巡检运行。

### 6. 全栈宿主机工程工具箱与丰富扩展生态
无需在多个软件间频繁切屏，Reeve 右侧与底部集成了完整的原生工程套件：

- **文件与代码编辑器**：内置文件树、语法高亮与版本乐观锁（防并发覆盖冲突）。
- **Git 多仓库与多 Agent Worktree 沙箱隔离**：可视化暂存、提交、分支切换、安全快照，支持为并发子智能体分配独立 Git Worktree 沙箱并在完成后检测冲突、一键合入，还支持将 PR 评论或 CI 报错一键转化为待修复缺陷。
- **交互式 PTY 终端**：原生多标签终端，支持一键将终端报错选中引用到对话输入框。
- **内置 CDP 自动化浏览器**：智能体可直接打开网页、点击输入、读取 DOM 快照、采集控制台报错并截图回传视觉模型进行 UI 联调。
- **原生桌面控制（Computer Use）**：跨 macOS、Windows、Linux 三端零 CGO 原生桌面无障碍控件树读取、窗口截图与鼠标键盘自动化操作，配备敏感操作确认门禁、频率限制与全局快捷键急停。
- **22 个官方内置插件 + 双向 MCP + Skills + Hooks**：内置 HTTP Client、Kubernetes、Redis、S3、Sentry、Linear、Notion、Slack、飞书、Stripe、依赖安全审计等 22 款开箱即用插件；支持接入外部 MCP Server，也可将 Reeve 作为 MCP Server 暴露给外部工具；内置结构化项目记忆与历史避坑（Pitfall）自动注入。

---

## 快速上手（3 步开启多智能体协作）

1. **连接模型或一键安装 CLI**：
   - 打开 Reeve，按 `⌘,`（Windows/Linux `Ctrl+,`）进入**「设置 → 提供商」**，配置任意模型厂商 API Key（或一键导入本地网关配置 `~/.config/reeve/models.json`）；
   - 也可进入**「设置 → Agent CLI」**，一键扫描并在界面内点击安装 Claude Code、Codex、Gemini CLI 等命令行智能体。
2. **在个人空间或项目中发起任务**：
   - 直接在左侧**「个人空间」**随手开聊，或新建/打开一个本地代码项目；
   - 点击输入框底部模型选择器，选择**「自动编排器」**、**「蜂群并行 `/swarm`」**或**「团队协同 `/teamwork`」**；
   - 使用 `@` 引用项目文件、目录、文档、技能或点名 `@全体成员`，用 `/` 调出快捷命令菜单。
3. **审阅、对比与交付**：
   - 顶栏自由切换「文档流 / 气泡流 / 时间线」或「并排对比」，点击子智能体卡片钻取黑板通信与文件变更；
   - 通过右侧「文件」「变更」「浏览器」「桌面控制」与底部「终端」实时检视交付成果。
