# Reeve Windows 一键环境检测与安装脚本 (PowerShell)
#
# 一键检测环境并安装最新版 Reeve：
#   irm https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.ps1 | iex
#
# 自动补齐缺失环境依赖 (Git / Ripgrep / Node.js) 并安装 Reeve：
#   $env:REEVE_INSTALL_DEPS="1"; irm https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.ps1 | iex

$ErrorActionPreference = "Stop"

$AppName = "Reeve"
$ReleaseRepo = if ($env:REEVE_RELEASE_REPO) { $env:REEVE_RELEASE_REPO } else { "chengyunyi/reeve-releases" }
$GitHubBase = if ($env:REEVE_GITHUB_BASE) { $env:REEVE_GITHUB_BASE.TrimEnd('/') } else { "https://github.com" }
$InstallDeps = ($env:REEVE_INSTALL_DEPS -eq "1")
$CheckOnly = ($env:REEVE_CHECK_ONLY -eq "1")
$SilentInstall = ($env:REEVE_SILENT -eq "1")

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "  ! $Message" -ForegroundColor Yellow
}

function Test-CommandExists([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# 1. 检测 Windows 架构与宿主机环境
$ArchRaw = $env:PROCESSOR_ARCHITECTURE
if ($env:PROCESSOR_ARCHITEW6432) {
    $ArchRaw = $env:PROCESSOR_ARCHITEW6432
}
$Arch = switch -Wildcard ($ArchRaw) {
    "*ARM64*" { "arm64" }
    "*AMD64*" { "amd64" }
    "*x86_64*" { "amd64" }
    default { throw "不支持的 Windows 处理器架构: $ArchRaw" }
}
$Target = "windows-$Arch"

Write-Step "1/3 检测宿主机运行环境 ($Target)"
Write-Ok "操作系统与架构: Windows ($ArchRaw -> $Target)"
Write-Ok "Reeve 核心运行时: 安装包已内置独立 Go 后台与 SQLite 引擎（零外部运行时依赖）"

$MissingWingetIds = @()

if (Test-CommandExists "git") {
    $GitVer = (& git --version 2>$null | Select-Object -First 1)
    Write-Ok "Git 版本控制与多智能体 Worktree 隔离: $GitVer"
} else {
    Write-Warn "Git: 未安装（建议安装以启用代码变更审阅与多智能体 Worktree 沙箱）"
    $MissingWingetIds += "Git.Git"
}

if (Test-CommandExists "rg") {
    $RgVer = (& rg --version 2>$null | Select-Object -First 1)
    Write-Ok "Ripgrep 高速代码搜索: $RgVer"
} else {
    Write-Warn "Ripgrep (rg): 未安装（将自动回退至内置 Go 文件检索；安装 rg 可获得更快大仓库搜索体验）"
    $MissingWingetIds += "BurntSushi.ripgrep.MSVC"
}

if (Test-CommandExists "bun") {
    $BunVer = (& bun --version 2>$null | Select-Object -First 1)
    Write-Ok "插件脚本运行时: Bun $BunVer"
} elseif (Test-CommandExists "node") {
    $NodeVer = (& node --version 2>$null | Select-Object -First 1)
    Write-Ok "插件脚本运行时: Node.js $NodeVer"
} else {
    Write-Warn "Node.js / Bun: 未安装（基础对话与内置工具无需安装；运行 JS 插件 Worker 或安装外部 CLI 时需要）"
    $MissingWingetIds += "OpenJS.NodeJS.LTS"
}

$DetectedCLIs = @()
foreach ($Cli in @("claude", "codex", "gemini", "aider", "agy", "opencode", "goose")) {
    if (Test-CommandExists $Cli) {
        $DetectedCLIs += $Cli
    }
}
if ($DetectedCLIs.Count -gt 0) {
    Write-Ok ("已识别外部编码 CLI: " + ($DetectedCLIs -join ", ") + "（可直接作为团队角色协同调度）")
} else {
    Write-Ok "外部编码 CLI: 暂未安装（启动 Reeve 后可在「设置 → Agent CLI」中一键安装）"
}

if ($MissingWingetIds.Count -gt 0) {
    if ($InstallDeps) {
        if (Test-CommandExists "winget") {
            foreach ($PkgId in $MissingWingetIds) {
                Write-Step "正在通过 winget 安装依赖: $PkgId"
                & winget install --id $PkgId -e --accept-source-agreements --accept-package-agreements
            }
        } else {
            Write-Warn "未检测到 winget，无法自动安装缺失依赖: $($MissingWingetIds -join ', ')"
        }
    } else {
        Write-Host "  提示: 如需自动安装上述可选环境依赖，可先执行 `$env:REEVE_INSTALL_DEPS='1'` 再运行本脚本。" -ForegroundColor DarkCyan
    }
}

if ($CheckOnly) {
    Write-Step "环境检测完成（REEVE_CHECK_ONLY=1 未执行安装）"
    return
}

# 2. 获取最新发行版清单（通过 GitHub Releases Web 直连，避免 REST API 403 限流）
$ManifestUrl = "$GitHubBase/$ReleaseRepo/releases/latest/download/update-$Target.json"
Write-Step "2/3 获取最新发行版清单 ($ManifestUrl)"
$ManifestResp = Invoke-WebRequest -Uri $ManifestUrl -UseBasicParsing
$Manifest = $ManifestResp.Content | ConvertFrom-Json
$Version = [string]$Manifest.version
if (-not $Version) {
    throw "无法从 $ManifestUrl 解析版本号"
}
Write-Ok "最新版本: v$Version"

# 3. 下载并运行 Windows 官方安装程序
$InstallerName = "reeve-setup-$Version-$Arch.exe"
$InstallerUrl = "$GitHubBase/$ReleaseRepo/releases/download/desktop-v$Version/$InstallerName"
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("reeve-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
$InstallerPath = Join-Path $TempDir $InstallerName

try {
    Write-Step "3/3 正在下载 $AppName 安装程序 ($InstallerName)..."
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing
    $FileInfo = Get-Item $InstallerPath
    if ($FileInfo.Length -lt 1048576) {
        throw "下载的安装包大小异常 ($($FileInfo.Length) 字节)"
    }
    Write-Ok "已下载安装程序 ($ ([math]::Round($FileInfo.Length / 1MB, 1)) MB)，正在启动安装..."
    if ($SilentInstall) {
        Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait
    } else {
        Start-Process -FilePath $InstallerPath -Wait
    }
    Write-Host "`n🎉 $AppName v$Version 安装完成，现在可以直接从桌面或开始菜单启动使用！" -ForegroundColor Green
} finally {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
