# Reeve Windows 一键环境检测与安装脚本 (PowerShell)
#
# 一键检测环境并安装最新版 Reeve：
#   irm https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.ps1 | iex
#
# 自动补齐缺失环境依赖 (Git / Ripgrep / Node.js) 并安装 Reeve：
#   $env:REEVE_INSTALL_DEPS="1"; irm https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.ps1 | iex

$ErrorActionPreference = "Stop"

# PowerShell 5.1 默认可能禁用 TLS 1.2，连接 GitHub Releases 前需显式开启
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {}

$AppName = "Reeve"
$ReleaseRepo = if ($env:REEVE_RELEASE_REPO) { $env:REEVE_RELEASE_REPO } else { "MokitaStark/reeve-releases" }
$GitHubBase = if ($env:REEVE_GITHUB_BASE) { $env:REEVE_GITHUB_BASE.TrimEnd('/') } else { "https://github.com" }
$UpdatePublicKey = if ($env:REEVE_UPDATE_PUBLIC_KEY) { $env:REEVE_UPDATE_PUBLIC_KEY.Trim() } else { "ZkdQ9//91Bgho1v91l2J/cd5LYI4htz58Lml9YZ7uvw=" }
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

function Assert-HttpsReleaseBase([string]$BaseUrl) {
    if ($BaseUrl -notmatch '^https://' -and $BaseUrl -notmatch '^http://(127\.0\.0\.1|localhost)(:\d+)?$') {
        throw "拒绝非 HTTPS 安装源地址: $BaseUrl"
    }
}

function Verify-Ed25519Digest([byte[]]$DigestBytes, [string]$SignatureB64, [string]$PublicKeyB64) {
    if (-not ('ReeveEd25519Verifier' -as [type])) {
        Add-Type -ReferencedAssemblies "System.Numerics" -TypeDefinition @"
using System;
using System.Numerics;
using System.Security.Cryptography;

public static class ReeveEd25519Verifier {
    private static readonly BigInteger Q = (BigInteger.One << 255) - 19;
    private static readonly BigInteger L = (BigInteger.One << 252) + BigInteger.Parse("27742317777372353535851937790883648493");
    private static readonly BigInteger D = Mod((-121665 * ModInv(121666, Q)), Q);
    private static readonly BigInteger I = BigInteger.ModPow(2, (Q - 1) / 4, Q);

    private static BigInteger Mod(BigInteger a, BigInteger m) {
        BigInteger r = a % m;
        return r.Sign < 0 ? r + m : r;
    }

    private static BigInteger ModInv(BigInteger a, BigInteger m) {
        return BigInteger.ModPow(Mod(a, m), m - 2, m);
    }

    private static BigInteger FromLittleEndian(byte[] bytes) {
        byte[] tmp = new byte[bytes.Length + 1];
        Array.Copy(bytes, tmp, bytes.Length);
        return new BigInteger(tmp);
    }

    private struct Point {
        public BigInteger X, Y, Z, T;
        public Point(BigInteger x, BigInteger y, BigInteger z, BigInteger t) {
            X = x; Y = y; Z = z; T = t;
        }
    }

    private static Point EdAdd(Point p, Point q) {
        BigInteger A = Mod((p.Y - p.X) * (q.Y - q.X), Q);
        BigInteger B = Mod((p.Y + p.X) * (q.Y + q.X), Q);
        BigInteger C = Mod(2 * D * p.T * q.T, Q);
        BigInteger DVal = Mod(2 * p.Z * q.Z, Q);
        BigInteger E = Mod(B - A, Q);
        BigInteger F = Mod(DVal - C, Q);
        BigInteger G = Mod(DVal + C, Q);
        BigInteger H = Mod(B + A, Q);
        return new Point(Mod(E * F, Q), Mod(G * H, Q), Mod(F * G, Q), Mod(E * H, Q));
    }

    private static Point ScalarMult(Point p, BigInteger e) {
        Point q = new Point(0, 1, 1, 0);
        while (e > BigInteger.Zero) {
            if (!e.IsEven) q = EdAdd(q, p);
            p = EdAdd(p, p);
            e >>= 1;
        }
        return q;
    }

    private static BigInteger XRecover(BigInteger y) {
        BigInteger yy = Mod(y * y, Q);
        BigInteger xx = Mod((yy - 1) * ModInv(Mod(D * yy + 1, Q), Q), Q);
        BigInteger x = BigInteger.ModPow(xx, (Q + 3) / 8, Q);
        if (Mod(x * x - xx, Q) != 0) x = Mod(x * I, Q);
        if (Mod(x * x - xx, Q) != 0) throw new InvalidOperationException("point not on curve");
        if (!x.IsEven) x = Q - x;
        return x;
    }

    private static Point DecodePoint(byte[] s) {
        byte[] yBytes = (byte[])s.Clone();
        int sign = (yBytes[31] >> 7) & 1;
        yBytes[31] &= 0x7f;
        BigInteger y = FromLittleEndian(yBytes);
        if (y >= Q) throw new InvalidOperationException("y >= q");
        BigInteger x = XRecover(y);
        if (x.IsZero && sign == 1) throw new InvalidOperationException("non-canonical zero");
        if ((x.IsEven ? 0 : 1) != sign) x = Q - x;
        return new Point(x, y, 1, Mod(x * y, Q));
    }

    private static bool EqualPoints(Point p, Point q) {
        return Mod(p.X * q.Z - q.X * p.Z, Q) == 0 && Mod(p.Y * q.Z - q.Y * p.Z, Q) == 0;
    }

    public static bool Verify(byte[] message, byte[] signature, byte[] publicKey) {
        if (message == null || signature == null || publicKey == null || signature.Length != 64 || publicKey.Length != 32) {
            return false;
        }
        try {
            BigInteger bx = Mod(BigInteger.Parse("15112221349535400772501151409588531511454012693041857206046113283949847762202"), Q);
            BigInteger by = Mod(BigInteger.Parse("46316835694926478169428394003475163141307993866256225615783033603165251855960"), Q);
            Point B = new Point(bx, by, 1, Mod(bx * by, Q));
            Point A = DecodePoint(publicKey);
            byte[] rBytes = new byte[32];
            byte[] sBytes = new byte[32];
            Array.Copy(signature, 0, rBytes, 0, 32);
            Array.Copy(signature, 32, sBytes, 0, 32);
            Point R = DecodePoint(rBytes);
            BigInteger S = FromLittleEndian(sBytes);
            if (S >= L) return false;
            byte[] hInput = new byte[32 + 32 + message.Length];
            Array.Copy(rBytes, 0, hInput, 0, 32);
            Array.Copy(publicKey, 0, hInput, 32, 32);
            Array.Copy(message, 0, hInput, 64, message.Length);
            byte[] hDigest;
            using (var sha512 = SHA512.Create()) {
                hDigest = sha512.ComputeHash(hInput);
            }
            BigInteger h = Mod(FromLittleEndian(hDigest), L);
            Point left = ScalarMult(B, S);
            Point right = EdAdd(R, ScalarMult(A, h));
            return EqualPoints(left, right);
        } catch {
            return false;
        }
    }
}
"@
    }
    $SigBytes = [Convert]::FromBase64String($SignatureB64.Trim())
    $PubBytes = [Convert]::FromBase64String($PublicKeyB64.Trim())
    return [ReeveEd25519Verifier]::Verify($DigestBytes, $SigBytes, $PubBytes)
}

# 2. 获取最新发行版清单（通过 GitHub Releases Web 直连，避免 REST API 403 限流）
Assert-HttpsReleaseBase $GitHubBase
$ManifestUrl = "$GitHubBase/$ReleaseRepo/releases/latest/download/update-$Target.json"
Write-Step "2/3 获取最新发行版清单 ($ManifestUrl)"
$ManifestResp = Invoke-WebRequest -Uri $ManifestUrl -UseBasicParsing
# GitHub Releases 常以 application/octet-stream 下发 .json 资产，PowerShell 5.1 下 Content 为 byte[]
$ManifestText = if ($ManifestResp.Content -is [byte[]]) {
    [System.Text.Encoding]::UTF8.GetString($ManifestResp.Content)
} else {
    [string]$ManifestResp.Content
}
$Manifest = $ManifestText | ConvertFrom-Json
$Version = [string]$Manifest.version
if (-not $Version -or $Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$') {
    throw "无法从 $ManifestUrl 解析合法版本号: $Version"
}
Write-Ok "最新版本: v$Version"

# 3. 下载并校验签名校验和文件与 Windows 官方安装程序
$ReleaseBase = "$GitHubBase/$ReleaseRepo/releases/download/desktop-v$Version"
$InstallerName = "reeve-setup-$Version-$Arch.exe"
$InstallerUrl = "$ReleaseBase/$InstallerName"
$SumsUrl = "$ReleaseBase/SHA256SUMS"
$SumsSigUrl = "$ReleaseBase/SHA256SUMS.sig"
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("reeve-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
$InstallerPath = Join-Path $TempDir $InstallerName
$SumsPath = Join-Path $TempDir "SHA256SUMS"
$SumsSigPath = Join-Path $TempDir "SHA256SUMS.sig"

try {
    Write-Step "3/3 正在下载并验签 $AppName 安装程序 ($InstallerName)..."
    $null = Invoke-WebRequest -Uri $SumsUrl -OutFile $SumsPath -UseBasicParsing
    $null = Invoke-WebRequest -Uri $SumsSigUrl -OutFile $SumsSigPath -UseBasicParsing
    $SumsBytes = [System.IO.File]::ReadAllBytes($SumsPath)
    $SumsSigText = [System.IO.File]::ReadAllText($SumsSigPath, [System.Text.Encoding]::UTF8).Trim()
    $Sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $SumsDigest = $Sha256.ComputeHash($SumsBytes)
    } finally {
        $Sha256.Dispose()
    }
    if (-not (Verify-Ed25519Digest -DigestBytes $SumsDigest -SignatureB64 $SumsSigText -PublicKeyB64 $UpdatePublicKey)) {
        throw "SHA256SUMS.sig Ed25519 密码学签名校验失败，已中止安装"
    }
    Write-Ok "已签名校验和清单 Ed25519 验签通过"

    $ExpectedSha256 = ""
    foreach ($Line in ([System.Text.Encoding]::UTF8.GetString($SumsBytes) -split "`n")) {
        $Trimmed = $Line.TrimEnd("`r")
        if ($Trimmed -match '^([0-9a-fA-F]{64})  (.+)$' -and $Matches[2] -eq $InstallerName) {
            $ExpectedSha256 = $Matches[1].ToLowerInvariant()
            break
        }
    }
    if (-not $ExpectedSha256) {
        throw "SHA256SUMS 中未找到 $InstallerName 的校验条目"
    }

    $Resp = Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing -PassThru
    $FileInfo = Get-Item $InstallerPath
    if ($FileInfo.Length -lt 1048576) {
        throw "下载的安装包大小异常 ($($FileInfo.Length) 字节)"
    }
    [int64]$ExpectedBytes = 0
    try {
        if ($Resp -and $Resp.Headers -and $Resp.Headers['Content-Length']) {
            [void][int64]::TryParse(([string]($Resp.Headers['Content-Length'] | Select-Object -First 1)), [ref]$ExpectedBytes)
        }
    } catch {}
    if ($ExpectedBytes -gt 0 -and $FileInfo.Length -ne $ExpectedBytes) {
        throw "下载的安装包大小与响应头不符（期望 $ExpectedBytes 字节，实际 $($FileInfo.Length) 字节）"
    }
    $ActualSha256 = (Get-FileHash -Path $InstallerPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ActualSha256 -ne $ExpectedSha256) {
        throw "安装程序 SHA-256 校验失败（期望 $ExpectedSha256，实际 $ActualSha256）"
    }
    Write-Ok "安装程序 SHA-256 校验通过 ($ActualSha256)"

    $AuthSig = Get-AuthenticodeSignature -FilePath $InstallerPath -ErrorAction SilentlyContinue
    if ($AuthSig -and ($AuthSig.Status -eq 'HashMismatch' -or $AuthSig.Status -eq 'NotTrusted')) {
        throw "安装程序 Authenticode 签名异常: $($AuthSig.Status)"
    }
    Write-Ok "已下载并验证安装程序 ($([math]::Round($FileInfo.Length / 1MB, 1)) MB)，正在启动安装..."
    if ($SilentInstall) {
        $Proc = Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait -PassThru
    } else {
        $Proc = Start-Process -FilePath $InstallerPath -Wait -PassThru
    }
    if ($Proc.ExitCode -ne 0) {
        throw "安装程序异常退出 (退出码: $($Proc.ExitCode))"
    }
    Write-Host "`n🎉 $AppName v$Version 安装完成，现在可以直接从桌面或开始菜单启动使用！" -ForegroundColor Green
} finally {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
