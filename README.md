<img src="assets/logo/reeve-logo.png" alt="Reeve" width="440" />

# Reeve · 原生多智能体工程与个人工作台

Reeve 是一款开箱即用的本地优先多智能体桌面工作台。官方安装包已**内置独立后台服务与 SQLite 数据引擎**，无需在本地安装 Go、Node、Bun 或任何开发构建环境，**安装后直接打开即可使用**。

在「全局个人空间」与「工程项目工作区」中，您可以通过内置**多智能体编排器（Orchestrator）**、主流大模型服务与本机编码 CLI 协同工作，调用文件、Git/Worktree、交互式终端、Chrome CDP 浏览器与宿主机桌面控制（Computer Use）完成从构思讨论、代码编写到自动化测试验收的全链路交付。

- **当前最新版本**：**`v0.1.001`**（[查看完整更新日志](CHANGELOG.md) · [前往 Releases 下载页](https://github.com/chengyunyi/reeve-releases/releases/latest)）
- **验签公钥**：[`update.pub`](update.pub)（所有安装包归档与自动更新差分包均经 Ed25519 私钥签名）

---

## 一键安装与环境检测（安装即用）

Reeve 提供跨平台**环境自动检测与一键安装脚本**，无需克隆源码或本地编译。脚本会自动检测您的操作系统与 CPU 架构、诊断宿主机可选工程工具链（Git、Ripgrep、插件运行时、浏览器、编码 CLI），并自动下载、校验和安装最新签名版 Reeve 桌面客户端。

### 方式一：命令行一键检测环境并自动安装（推荐）

#### macOS（Apple Silicon M1–M4）与 Linux（x86_64）

```bash
curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh
```

常用进阶选项：

```bash
# 自动检测并调用系统包管理器（brew / apt / dnf / pacman）一键补齐缺失的推荐环境依赖（git / rg / node / Linux GTK4），随后安装 Reeve
curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --install-deps

# 仅执行宿主机环境健康检测（不执行下载与安装）
curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --check-only

# 卸载 Reeve（保留个人设置与项目数据）
curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --uninstall
```

#### Windows（x64 / ARM64，PowerShell）

```powershell
irm https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.ps1 | iex
```

如需在 Windows 下通过 `winget` 一并自动补齐缺失的 Git、Ripgrep 与 Node.js 环境依赖：

```powershell
$env:REEVE_INSTALL_DEPS="1"; irm https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.ps1 | iex
```

---

### 方式二：直接下载官方安装包

您也可以直接在 [**Releases 页面**](https://github.com/chengyunyi/reeve-releases/releases/latest) 下载对应系统的预编译签名安装包，双击安装后即可使用：

| 平台与架构 | 官方安装包直链（`v0.1.001`） | 安装说明 |
| --- | --- | --- |
| **macOS**（Apple Silicon `arm64`） | [**`reeve-0.1.001-arm64.dmg`**](https://github.com/chengyunyi/reeve-releases/releases/download/desktop-v0.1.001/reeve-0.1.001-arm64.dmg) | 打开 `.dmg` 将 `Reeve.app` 拖入「应用程序」即可运行 |
| **Windows**（64 位 `x64`） | [**`reeve-setup-0.1.001-amd64.exe`**](https://github.com/chengyunyi/reeve-releases/releases/download/desktop-v0.1.001/reeve-setup-0.1.001-amd64.exe) | 双击运行向导完成安装，自动创建桌面与开始菜单快捷方式 |
| **Windows**（骁龙 / Surface `ARM64`） | [**`reeve-setup-0.1.001-arm64.exe`**](https://github.com/chengyunyi/reeve-releases/releases/download/desktop-v0.1.001/reeve-setup-0.1.001-arm64.exe) | 原生 ARM64 安装程序，双击安装即用 |
| **Linux**（64 位 `x86_64`） | [**`reeve-0.1.001-linux-amd64.tar.gz`**](https://github.com/chengyunyi/reeve-releases/releases/download/desktop-v0.1.001/reeve-0.1.001-linux-amd64.tar.gz) | 配合上方 `install.sh` 自动安装至 `~/.local/reeve.app` 并注册桌面菜单 |

---

### 环境自动检测说明与内置 CLI 安装器

| 检测项 | 是否必需 | 用途与缺失时的自动处理策略 |
| --- | --- | --- |
| **Reeve 核心后台与数据库** | **已内置** | 随桌面安装包内置编译好的独立服务与 SQLite 引擎，**零外部依赖，开箱即用** |
| **Git** | 推荐 | 用于项目「变更」面板、提交历史审阅与多智能体 Git Worktree 沙箱隔离（支持 `--install-deps` 自动安装） |
| **Ripgrep (`rg`)** | 可选 | 提供超大代码仓库极速全文检索；未安装时自动无缝回退至 Reeve 内置文件搜索引擎 |
| **Node.js / Bun** | 可选 | 基础对话与 84 个内置工具无需安装；仅在运行 JS 插件 Worker 或通过 `npm`/`bun` 安装外部 CLI 时按需使用 |
| **Chrome / Chromium** | 可选 | 仅在开启右侧内置「浏览器（CDP 自动化）」面板时按需调用本机浏览器 |
| **外部编码 Agent CLI** | 可选 | 启动 Reeve 后，打开 **「设置 → Agent CLI」** 即可一键扫描本机环境，并在图形界面内**一键安装或升级** Claude Code、Codex、Gemini CLI、Aider、OpenCode、Goose 等命令行智能体 |

---

## 快速上手（3 步开聊）

1. **启动应用并连接模型**：
   - 打开 Reeve，无需先创建项目即可直接进入内置**「个人空间」**（也可在左侧新建或导入代码文件夹作为工作项目）；
   - 按 `⌘,`（Windows/Linux `Ctrl+,`）打开**「设置 → 提供商」**，填写模型 API Key 或一键同步本地网关配置（`~/.config/reeve/models.json`）；也可在**「设置 → Agent CLI」**一键安装并启用外部编码 CLI。
2. **选择多智能体编排器**：
   - 点击输入框底部的「选用模型」选择器，在顶部直接切换编排模式：
     - **自动编排器**：根据问题复杂度按需自动创建专家角色并委派子智能体；
     - **蜂群并行 `/swarm`**：将大型复杂任务自动拆分为独立分片，多路子智能体并发攻坚；
     - **团队协同 `/teamwork`**：按「拆解 → 实现 → 审查」多角色分工接力与交叉把关；
     - **单模型直连**：由当前选定模型直接回复；
   - 也可在输入框直接输入 `/swarm`、`/teamwork`、`/plan`、`/goal`，或用 `@` 引用文件、目录、资料、技能及 `@全体成员`。
3. **检视协同过程与交付成果**：
   - 在会话顶栏随时切换 **「文档流 / 气泡流 / 时间线」** 三套聊天样式；
   - 多角色并行回答时可切换横向 **「并排对比」** 视图并一键 **「汇总结论」**；
   - 点击任意子智能体委派卡片可钻取查看实时思考流、分步耗时轨迹、**「智能体协同通信（共享黑板）」** 与 **「变更文件」**；
   - 在个人空间讨论成熟后，点击顶栏 **「以此新建工作项目…」** 即可携带多智能体最新结论直接创建工程项目。

---

## 核心特性一览

- **多智能体编排器与三层相互通信**：
  - 会话按需自动创建与复用专家子智能体（`create_team_role` / `delegate_to_role`），弱化手动预建角色负担；
  - 内置**会话共享协作黑板（`post_team_message`）**，支持子智能体在运行途中实时广播或定向发送接口契约（`contract`）、关键发现（`finding`）、交接事项（`handoff`）与风险阻塞（`risk`），同轮并发 Worker 实时增量感知；
  - 委派时自动注入用户原始诉求、同轮并发同伴分工边界、上游交付结论与变更文件账本（`ChangedFiles`），顺序接力（`chain`）支持动态 `@点名交接`。
- **三套对话视图与并排对比**：
  - 支持「文档流」「气泡流」「时间线」智能推导与一键切换；
  - `@全体成员` 同题并行回复自动聚合为横向并排对比卡片（内嵌成员思考与工具过程胶囊）并支持一键汇总。
- **全局个人空间与工作项目双空间**：
  - 内置个人空间（预置个人助手、思维与写作、技术顾问）与跨项目偏好记忆；支持自定义默认项目存储位置与保留目录防碰撞保护。
- **四列任务看板与 LoopForge 2D 自动化流程画布**：
  - 任务对话自动纳入「待开始 / 进行中 / 待验收 / 已完成」四列看板，结合任务 DAG 依赖拆分合并与客观测试指纹门禁验收；
  - 自动化任务支持「对话模式」与 2D 交互式「流程画布」（Agent 节点、脚本与文件验证节点、人工审批门、产物汇总节点、失败返工虚线回边），支持手动触发、固定间隔与标准 5 段 Cron 定时调度。
- **全栈宿主机工程工具链与免限流自动更新**：
  - 集成版本乐观锁文件编辑器、Git 多仓库与多 Agent Worktree 沙箱隔离/冲突合入、交互式 PTY 终端、Chrome CDP 浏览器、三端零 CGO 原生桌面控制（Computer Use）及 22 个内置官方插件 / 双向 MCP / Skills / Hooks；
  - 内置基于 GitHub Release 直连与 `releases.atom` 的免 API 限流自动更新器，所有更新包经 Ed25519 强签名校验并在升级前自动创建 SQLite 一致性备份。

---

## 版本规范与签名安全约定

- **三段式三位补零版本号**：采用 `MAJOR.MINOR.PATCH` 格式（从 `0.1.001` 起步；后三位 `PATCH` 为 `001`–`999`，满 `0.1.999` 后自动进位至 `0.2.000`）。
- **桌面发布标签**：`desktop-v<版本>`（例如 `desktop-v0.1.001`）。
- **Ed25519 签名校验**：每个平台的更新清单 `update-<系统>-<架构>.json`、完整归档 `.tar.gz` 与增量差分包 `.delta` 均由 Ed25519 私钥签名，客户端使用内置公钥 [`update.pub`](update.pub) 强制验签。
- **本地数据隐私**：本仓库仅提供公开安装包、环境检测安装脚本与签名更新元数据；您所有的项目、会话、记忆与加密模型凭据均 100% 存储在您本机的 `$REEVE_HOME` SQLite 数据库中。
