#!/bin/sh
# Reeve 跨平台一键环境检测与安装脚本 (macOS / Linux)
#
# 一键检测环境并安装最新版 Reeve：
#   curl -fsSL https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.sh | sh
#
# 一键检测、自动补齐缺失环境依赖（Git / Ripgrep / Node / Linux GTK4 等）并安装 Reeve：
#   curl -fsSL https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.sh | sh -s -- --install-deps
#
# 仅执行宿主机环境诊断：
#   curl -fsSL https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.sh | sh -s -- --check-only
#
# 卸载 Reeve（保留用户项目与会话数据）：
#   curl -fsSL https://github.com/MokitaStark/reeve-releases/releases/latest/download/install.sh | sh -s -- --uninstall

set -eu

APP_NAME="Reeve"
SLUG="reeve"
BUNDLE="Reeve.app"
RELEASE_REPO="${REEVE_RELEASE_REPO:-MokitaStark/reeve-releases}"
GITHUB_BASE="${REEVE_GITHUB_BASE:-https://github.com}"
UPDATE_PUBLIC_KEY="${REEVE_UPDATE_PUBLIC_KEY:-ZkdQ9//91Bgho1v91l2J/cd5LYI4htz58Lml9YZ7uvw=}"
INSTALL_DIR="${REEVE_INSTALL_DIR:-}"
NO_OPEN="${REEVE_NO_OPEN:-}"
AUTO_INSTALL_DEPS="${REEVE_INSTALL_DEPS:-0}"
CHECK_ONLY=0
UNINSTALL=0

usage() {
	cat <<EOF
用法: sh install.sh [选项]

选项:
  --install-deps   自动调用系统包管理器 (brew/apt/dnf/pacman) 安装缺失的推荐环境依赖
  --check-only     仅执行宿主机环境检测，不下载或安装 $APP_NAME
  --no-open        安装完成后不自动启动 $APP_NAME
  --uninstall      卸载已安装的 ${APP_NAME}（保留用户配置与项目数据）
  -h, --help       显示本帮助信息

环境变量:
  REEVE_INSTALL_DEPS=1   等同于 --install-deps
  REEVE_INSTALL_DIR=...  自定义安装目录（macOS 默认 /Applications 或 ~/Applications，Linux 默认 ~/.local/reeve.app）
  REEVE_NO_OPEN=1        等同于 --no-open
EOF
}

info() {
	printf '\033[1;34m==>\033[0m %s\n' "$*"
}

ok() {
	printf '  \033[1;32m✓\033[0m %s\n' "$*"
}

warn() {
	printf '  \033[1;33m!\033[0m %s\n' "$*" >&2
}

fail() {
	printf '\033[1;31m错误:\033[0m %s\n' "$*" >&2
	exit 1
}

has_cmd() {
	command -v "$1" >/dev/null 2>&1
}

fetch_text() {
	if has_cmd curl; then
		curl -fsSL "$1"
	elif has_cmd wget; then
		wget -qO- "$1"
	else
		fail "未检测到 curl 或 wget，请先安装其中之一"
	fi
}

fetch_file() {
	url="$1"
	dest="$2"
	if has_cmd curl; then
		curl -fL --progress-bar "$url" -o "$dest"
	elif has_cmd wget; then
		wget -q --show-progress -O "$dest" "$url" || wget -qO "$dest" "$url"
	else
		fail "未检测到 curl 或 wget，请先安装其中之一"
	fi
}

detect_platform() {
	os_name="$(uname -s)"
	arch_name="$(uname -m)"
	case "$os_name" in
	Darwin)
		OS="darwin"
		case "$arch_name" in
		arm64 | aarch64) ARCH="arm64" ;;
		x86_64 | amd64)
			# 在 Apple Silicon 的 Rosetta 终端下自动识别原生 arm64
			if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = "1" ]; then
				ARCH="arm64"
			else
				fail "当前 macOS 官方发行包仅针对 Apple Silicon (arm64) 构建"
			fi
			;;
		*) fail "不支持的 macOS 架构: $arch_name" ;;
		esac
		;;
	Linux)
		OS="linux"
		case "$arch_name" in
		x86_64 | amd64) ARCH="amd64" ;;
		aarch64 | arm64) ARCH="arm64" ;;
		*) fail "不支持的 Linux 架构: $arch_name" ;;
		esac
		;;
	*)
		fail "当前脚本仅支持 macOS 与 Linux（Windows 请使用 PowerShell 运行 install.ps1）"
		;;
	esac
	TARGET="${OS}-${ARCH}"
}

detect_browser() {
	if [ "$OS" = "darwin" ]; then
		for app in \
			"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
			"$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
			"/Applications/Chromium.app/Contents/MacOS/Chromium" \
			"/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
			"/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"; do
			if [ -x "$app" ]; then
				printf '%s' "$app"
				return 0
			fi
		done
	fi
	for bin in google-chrome google-chrome-stable chromium chromium-browser microsoft-edge brave-browser; do
		if has_cmd "$bin"; then
			command -v "$bin"
			return 0
		fi
	done
	return 1
}

run_root_pkg() {
	if [ "$(id -u)" = "0" ]; then
		"$@"
	elif has_cmd sudo; then
		sudo "$@"
	else
		warn "需要 root 权限或 sudo 以执行: $*"
		return 1
	fi
}

install_missing_deps() {
	missing_list="$1"
	if [ -z "$missing_list" ]; then
		return 0
	fi
	info "正在自动安装缺失的环境依赖: $missing_list"
	if [ "$OS" = "darwin" ]; then
		if ! has_cmd brew; then
			warn "未检测到 Homebrew (brew)，跳过自动安装可选依赖。可前往 https://brew.sh 安装后重试。"
			return 0
		fi
		for pkg in $missing_list; do
			case "$pkg" in
			git) brew install git || true ;;
			ripgrep) brew install ripgrep || true ;;
			node) brew install node || true ;;
			esac
		done
		return 0
	fi

	if has_cmd apt-get; then
		run_root_pkg apt-get update -y || true
		apt_pkgs=""
		for pkg in $missing_list; do
			case "$pkg" in
			git) apt_pkgs="$apt_pkgs git" ;;
			ripgrep) apt_pkgs="$apt_pkgs ripgrep" ;;
			node) apt_pkgs="$apt_pkgs nodejs npm" ;;
			gtk4) apt_pkgs="$apt_pkgs libgtk-4-1 libatspi2.0-0 xdg-utils" ;;
			esac
		done
		if [ -n "$apt_pkgs" ]; then
			# shellcheck disable=SC2086
			run_root_pkg apt-get install -y $apt_pkgs || true
		fi
	elif has_cmd dnf; then
		dnf_pkgs=""
		for pkg in $missing_list; do
			case "$pkg" in
			git) dnf_pkgs="$dnf_pkgs git" ;;
			ripgrep) dnf_pkgs="$dnf_pkgs ripgrep" ;;
			node) dnf_pkgs="$dnf_pkgs nodejs npm" ;;
			gtk4) dnf_pkgs="$dnf_pkgs gtk4 at-spi2-core xdg-utils" ;;
			esac
		done
		if [ -n "$dnf_pkgs" ]; then
			# shellcheck disable=SC2086
			run_root_pkg dnf install -y $dnf_pkgs || true
		fi
	elif has_cmd pacman; then
		pac_pkgs=""
		for pkg in $missing_list; do
			case "$pkg" in
			git) pac_pkgs="$pac_pkgs git" ;;
			ripgrep) pac_pkgs="$pac_pkgs ripgrep" ;;
			node) pac_pkgs="$pac_pkgs nodejs npm" ;;
			gtk4) pac_pkgs="$pac_pkgs gtk4 at-spi2-core xdg-utils" ;;
			esac
		done
		if [ -n "$pac_pkgs" ]; then
			# shellcheck disable=SC2086
			run_root_pkg pacman -Sy --noconfirm $pac_pkgs || true
		fi
	else
		warn "未识别到 apt-get / dnf / pacman，请手动安装: $missing_list"
	fi
}

check_environment() {
	info "1/3 检测宿主机运行环境 ($TARGET)"
	ok "操作系统与架构: $(uname -s) $(uname -m) -> $TARGET"
	ok "Reeve 核心运行时: 安装包已内置独立 Go 后台与 SQLite 引擎（零外部运行时依赖）"

	missing_deps=""

	if ! has_cmd tar || ! has_cmd gzip; then
		fail "系统缺少基础解压工具 tar 或 gzip"
	fi

	# Linux GTK4 桌面环境检查
	if [ "$OS" = "linux" ]; then
		if has_cmd ldconfig && ldconfig -p 2>/dev/null | grep -q "libgtk-4.so"; then
			ok "Linux 图形运行时: 已就绪 (libgtk-4)"
		elif [ -f /usr/lib/x86_64-linux-gnu/libgtk-4.so.1 ] || [ -f /usr/lib64/libgtk-4.so.1 ] || [ -f /usr/lib/libgtk-4.so.1 ]; then
			ok "Linux 图形运行时: 已就绪 (libgtk-4)"
		else
			warn "Linux 图形运行时: 未检测到 libgtk-4（桌面窗口渲染需要 GTK4）"
			missing_deps="$missing_deps gtk4"
		fi
	fi

	# Git 检查
	if has_cmd git; then
		ok "Git 版本控制与多智能体 Worktree 隔离: $(git --version 2>/dev/null | head -n 1)"
	else
		warn "Git: 未安装（建议安装以启用代码变更审阅与多智能体 Worktree 沙箱）"
		missing_deps="$missing_deps git"
	fi

	# Ripgrep 检查
	if has_cmd rg; then
		ok "Ripgrep 高速代码搜索: $(rg --version 2>/dev/null | head -n 1)"
	else
		warn "Ripgrep (rg): 未安装（将自动回退至内置 Go 文件检索；安装 rg 可获得更快大仓库搜索体验）"
		missing_deps="$missing_deps ripgrep"
	fi

	# Node / Bun 检查（用于内置 JS 插件 Worker）
	if has_cmd bun; then
		ok "插件脚本运行时: Bun $(bun --version 2>/dev/null | head -n 1)"
	elif has_cmd node; then
		ok "插件脚本运行时: Node.js $(node --version 2>/dev/null | head -n 1)"
	else
		warn "Node.js / Bun: 未安装（基础对话与内置工具无需安装；运行 JS 插件 Worker 或 npm 安装外部 CLI 时需要）"
		missing_deps="$missing_deps node"
	fi

	# Chrome / Chromium 检查（用于 CDP 浏览器自动化）
	if browser_bin="$(detect_browser)"; then
		ok "CDP 自动化浏览器: $browser_bin"
	else
		warn "Chrome / Chromium: 未检测到（如需使用内置 CDP 自动化浏览器面板，可安装 Google Chrome 或 Chromium）"
	fi

	# 外部编码 Agent CLI 探测
	detected_clis=""
	for cli in claude codex gemini aider agy opencode goose; do
		if has_cmd "$cli"; then
			detected_clis="$detected_clis $cli"
		fi
	done
	if [ -n "$detected_clis" ]; then
		ok "已识别外部编码 CLI:${detected_clis}（可直接作为团队角色协同调度）"
	else
		ok "外部编码 CLI: 暂未安装（启动 Reeve 后可在「设置 → Agent CLI」中一键安装）"
	fi

	if [ -n "$missing_deps" ]; then
		if [ "$AUTO_INSTALL_DEPS" = "1" ]; then
			install_missing_deps "$missing_deps"
		else
			printf '  \033[0;36m提示:\033[0m 如需脚本自动补齐上述可选依赖，可追加 \033[1m--install-deps\033[0m 参数重新运行。\n'
		fi
	fi
}

parse_json_top_field() {
	kind="$1"
	key="$2"
	json_text="$3"
	if has_cmd python3; then
		printf '%s' "$json_text" | python3 -c '
import json, sys
kind, key = sys.argv[1], sys.argv[2]
v = json.load(sys.stdin).get(key)
if kind == "string" and isinstance(v, str):
    sys.stdout.write(v)
elif kind == "int" and isinstance(v, int) and not isinstance(v, bool):
    sys.stdout.write(str(v))
' "$kind" "$key" 2>/dev/null && return 0
	elif has_cmd node; then
		printf '%s' "$json_text" | node -e '
const fs = require("fs");
const [kind, key] = process.argv.slice(1);
const v = JSON.parse(fs.readFileSync(0, "utf8"))[key];
if (kind === "string" && typeof v === "string") process.stdout.write(v);
else if (kind === "int" && typeof v === "number" && Number.isFinite(v)) process.stdout.write(String(Math.trunc(v)));
' "$kind" "$key" 2>/dev/null && return 0
	fi
	printf '%s' "$json_text" | awk -v kind="$kind" -v target="$key" '
	{ s = s $0 "\n" }
	END {
		n = length(s)
		depth = 0
		in_str = 0
		esc = 0
		expect_key = 0
		for (i = 1; i <= n; i++) {
			c = substr(s, i, 1)
			if (in_str) {
				if (esc) { esc = 0 }
				else if (c == "\\") { esc = 1 }
				else if (c == "\"") { in_str = 0 }
				continue
			}
			if (c == "{" || c == "[") {
				depth++
				expect_key = (depth == 1 && c == "{")
				continue
			}
			if (c == "}" || c == "]") {
				depth--
				expect_key = 0
				continue
			}
			if (c == "," && depth == 1) {
				expect_key = 1
				continue
			}
			if (depth == 1 && expect_key && c == "\"") {
				k = ""
				j = i + 1
				kesc = 0
				while (j <= n) {
					kc = substr(s, j, 1)
					if (kesc) { k = k kc; kesc = 0 }
					else if (kc == "\\") { k = k kc; kesc = 1 }
					else if (kc == "\"") { break }
					else { k = k kc }
					j++
				}
				i = j
				expect_key = 0
				p = i + 1
				while (p <= n && substr(s, p, 1) ~ /[ \t\r\n]/) p++
				if (substr(s, p, 1) == ":") {
					p++
					while (p <= n && substr(s, p, 1) ~ /[ \t\r\n]/) p++
					if (k == target) {
						vc = substr(s, p, 1)
						if (kind == "string" && vc == "\"") {
							val = ""
							q = p + 1
							vesc = 0
							while (q <= n) {
								vch = substr(s, q, 1)
								if (vesc) {
									if (vch == "\"" || vch == "\\" || vch == "/") val = val vch
									else val = val "\\" vch
									vesc = 0
								} else if (vch == "\\") {
									vesc = 1
								} else if (vch == "\"") {
									break
								} else {
									val = val vch
								}
								q++
							}
							printf "%s\n", val
							exit
						}
						if (kind == "int" && vc ~ /[0-9]/) {
							val = ""
							q = p
							while (q <= n && substr(s, q, 1) ~ /[0-9]/) {
								val = val substr(s, q, 1)
								q++
							}
							printf "%s\n", val
							exit
						}
						exit
					}
				}
				continue
			}
			if (c == "\"") {
				in_str = 1
			}
		}
	}'
}

parse_json_string() {
	parse_json_top_field "string" "$1" "$2"
}

parse_json_int() {
	parse_json_top_field "int" "$1" "$2"
}

validate_base_url() {
	base="${1%/}"
	case "$base" in
	https://*)
		return 0
		;;
	http://127.0.0.1 | http://127.0.0.1:* | http://localhost | http://localhost:*)
		return 0
		;;
	*)
		fail "拒绝非 HTTPS 安装源地址: $base"
		;;
	esac
}

validate_version_string() {
	case "$1" in
	"" | *[!0-9A-Za-z.-]* | .* | *.)
		fail "版本号格式非法: $1"
		;;
	esac
	if ! printf '%s' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$'; then
		fail "版本号格式不符合发布规范: $1"
	fi
}

compute_sha256_file() {
	file="$1"
	if has_cmd sha256sum; then
		sha256sum "$file" | awk '{print $1}'
	elif has_cmd shasum; then
		shasum -a 256 "$file" | awk '{print $1}'
	elif has_cmd openssl; then
		openssl dgst -sha256 -r "$file" | awk '{print $1}'
	elif has_cmd python3; then
		python3 -c '
import hashlib, sys
h = hashlib.sha256()
with open(sys.argv[1], "rb") as f:
    for chunk in iter(lambda: f.read(65536), b""):
        h.update(chunk)
sys.stdout.write(h.hexdigest())
' "$file"
	elif has_cmd node; then
		node -e '
const fs = require("fs"), crypto = require("crypto");
const h = crypto.createHash("sha256");
h.update(fs.readFileSync(process.argv[1]));
process.stdout.write(h.digest("hex"));
' "$file"
	else
		fail "未找到 SHA-256 计算工具（sha256sum/shasum/openssl/python3/node）"
	fi
}

verify_ed25519_digest_python() {
	digest_hex="$1"
	sig_b64="$2"
	pub_b64="$3"
	python3 -c '
import base64, hashlib, sys

digest = bytes.fromhex(sys.argv[1])
sig = base64.b64decode(sys.argv[2], validate=True)
pub = base64.b64decode(sys.argv[3], validate=True)
if len(digest) != 32 or len(sig) != 64 or len(pub) != 32:
    sys.exit(1)

b = 256
q = 2**255 - 19
l = 2**252 + 27742317777372353535851937790883648493
d = (-121665 * pow(121666, q - 2, q)) % q
I = pow(2, (q - 1) // 4, q)

def ed_add(P, Q):
    X1, Y1, Z1, T1 = P
    X2, Y2, Z2, T2 = Q
    A = ((Y1 - X1) * (Y2 - X2)) % q
    B = ((Y1 + X1) * (Y2 + X2)) % q
    C = (2 * d * T1 * T2) % q
    D = (2 * Z1 * Z2) % q
    E = (B - A) % q
    F = (D - C) % q
    G = (D + C) % q
    H = (B + A) % q
    return ((E * F) % q, (G * H) % q, (F * G) % q, (E * H) % q)

def scalarmult(P, e):
    Q = (0, 1, 1, 0)
    while e > 0:
        if e & 1:
            Q = ed_add(Q, P)
        P = ed_add(P, P)
        e >>= 1
    return Q

def xrecover(y):
    xx = ((y * y - 1) * pow(d * y * y + 1, q - 2, q)) % q
    x = pow(xx, (q + 3) // 8, q)
    if (x * x - xx) % q != 0:
        x = (x * I) % q
    if (x * x - xx) % q != 0:
        raise ValueError("not on curve")
    if x % 2 != 0:
        x = q - x
    return x

def decodepoint(s):
    y = int.from_bytes(s, "little") & ((1 << 255) - 1)
    if y >= q:
        raise ValueError("y >= q")
    x = xrecover(y)
    sign = (s[31] >> 7) & 1
    if x == 0 and sign == 1:
        raise ValueError("non-canonical zero")
    if (x & 1) != sign:
        x = q - x
    return (x, y, 1, (x * y) % q)

def encodepoint(P):
    x, y, z, _ = P
    zinv = pow(z, q - 2, q)
    x = (x * zinv) % q
    y = (y * zinv) % q
    bits = bytearray(y.to_bytes(32, "little"))
    bits[31] |= (x & 1) << 7
    return bytes(bits)

def is_equal(P, Q):
    x1, y1, z1, _ = P
    x2, y2, z2, _ = Q
    return (x1 * z2 - x2 * z1) % q == 0 and (y1 * z2 - y2 * z1) % q == 0

try:
    Bx = (15112221349535400772501151409588531511454012693041857206046113283949847762202) % q
    By = (46316835694926478169428394003475163141307993866256225615783033603165251855960) % q
    B = (Bx, By, 1, (Bx * By) % q)
    A = decodepoint(pub)
    R = decodepoint(sig[:32])
    S = int.from_bytes(sig[32:], "little")
    if S >= l:
        sys.exit(1)
    h = int.from_bytes(hashlib.sha512(sig[:32] + pub + digest).digest(), "little") % l
    left = scalarmult(B, S)
    right = ed_add(R, scalarmult(A, h))
    sys.exit(0 if is_equal(left, right) else 1)
except Exception:
    sys.exit(1)
' "$digest_hex" "$sig_b64" "$pub_b64"
}

verify_ed25519_digest_node() {
	digest_hex="$1"
	sig_b64="$2"
	pub_b64="$3"
	node -e '
const crypto = require("crypto");
const digest = Buffer.from(process.argv[1], "hex");
const sig = Buffer.from(process.argv[2], "base64");
const pubRaw = Buffer.from(process.argv[3], "base64");
if (digest.length !== 32 || sig.length !== 64 || pubRaw.length !== 32) process.exit(1);
const spkiPrefix = Buffer.from("302a300506032b6570032100", "hex");
const key = crypto.createPublicKey({ key: Buffer.concat([spkiPrefix, pubRaw]), format: "der", type: "spki" });
if (!crypto.verify(null, digest, key, sig)) process.exit(1);
' "$digest_hex" "$sig_b64" "$pub_b64"
}

verify_ed25519_digest_openssl() {
	digest_hex="$1"
	sig_b64="$2"
	pub_b64="$3"
	ver="$(openssl version 2>/dev/null || true)"
	case "$ver" in
	OpenSSL\ *) ;;
	*) return 1 ;;
	esac
	vtmp="$(mktemp -d)"
	decode_err=0
	if has_cmd xxd; then
		printf '%s' "$digest_hex" | xxd -r -p >"$vtmp/msg.bin" 2>/dev/null || decode_err=1
	else
		rem="$digest_hex"
		: >"$vtmp/msg.bin"
		while [ -n "$rem" ]; do
			byte_hex="${rem%"${rem#??}"}"
			rem="${rem#??}"
			case "$byte_hex" in
			[0-9a-fA-F][0-9a-fA-F])
				printf '%b' "\\$(printf '%03o' "0x$byte_hex")" >>"$vtmp/msg.bin" || {
					decode_err=1
					break
				}
				;;
			*)
				decode_err=1
				break
				;;
			esac
		done
	fi
	if [ "$decode_err" = "0" ] && has_cmd base64; then
		printf '%s' "$sig_b64" | base64 -d >"$vtmp/sig.bin" 2>/dev/null || decode_err=1
		printf 'MCowBQYDK2VwAyEA' | base64 -d >"$vtmp/pub.der" 2>/dev/null || decode_err=1
		printf '%s' "$pub_b64" | base64 -d >>"$vtmp/pub.der" 2>/dev/null || decode_err=1
		if [ "$decode_err" = "0" ] && openssl pkeyutl -verify -pubin -inform DER -inkey "$vtmp/pub.der" -rawin -in "$vtmp/msg.bin" -sigfile "$vtmp/sig.bin" >/dev/null 2>&1; then
			rm -rf "$vtmp"
			return 0
		fi
	fi
	rm -rf "$vtmp"
	return 1
}

verify_archive_signature() {
	archive_file="$1"
	sig_b64="$2"
	pub_b64="$3"
	if [ -z "$sig_b64" ] || [ -z "$pub_b64" ]; then
		fail "缺少安装包 Ed25519 签名或公钥"
	fi
	digest_hex="$(compute_sha256_file "$archive_file")"
	if has_cmd python3; then
		if verify_ed25519_digest_python "$digest_hex" "$sig_b64" "$pub_b64"; then
			ok "安装包 Ed25519 密码学签名校验通过 (SHA-256: ${digest_hex})"
			return 0
		fi
		fail "安装包 Ed25519 签名校验失败，文件可能已被篡改"
	elif has_cmd node; then
		if verify_ed25519_digest_node "$digest_hex" "$sig_b64" "$pub_b64"; then
			ok "安装包 Ed25519 密码学签名校验通过 (SHA-256: ${digest_hex})"
			return 0
		fi
		fail "安装包 Ed25519 签名校验失败，文件可能已被篡改"
	elif has_cmd openssl; then
		if verify_ed25519_digest_openssl "$digest_hex" "$sig_b64" "$pub_b64"; then
			ok "安装包 Ed25519 密码学签名校验通过 (SHA-256: ${digest_hex})"
			return 0
		fi
		fail "安装包 Ed25519 签名校验失败或 OpenSSL 版本过旧，文件可能已被篡改"
	else
		fail "未找到支持 Ed25519 验签的运行时 (python3 / node / OpenSSL)，已拒绝继续安装"
	fi
}

validate_install_dir() {
	dir="$1"
	if [ -z "$dir" ]; then
		fail "安装目录不能为空"
	fi
	nl="$(printf '\n_')"
	nl="${nl%_}"
	cr="$(printf '\r')"
	case "$dir" in
	*"$nl"* | *"$cr"*)
		fail "安装目录包含非法控制字符"
		;;
	*'$'* | *'`'* | *'"'* | *"'"* | *'\'* | *';'* | *'|'* | *'&'* | *'<'* | *'>'*)
		fail "安装目录包含不安全特殊字符: $dir"
		;;
	esac
	norm="${dir%/}"
	if [ -z "$norm" ] || [ "$norm" = "/" ] || [ "$norm" = "." ] || [ "$norm" = ".." ] || [ "$norm" = "$HOME" ]; then
		fail "拒绝使用危险的安装目录: $dir"
	fi
	case "$norm" in
	.. | ../* | */.. | */../*)
		fail "安装目录不允许包含 .. 路径片段: $dir"
		;;
	esac
}

verify_tar_archive_safety() {
	archive_file="$1"
	required_prefix="${2:-}"
	entries="$(tar -tzf "$archive_file")" || fail "读取归档目录失败: $archive_file"
	if [ -z "$entries" ]; then
		fail "安装包归档内容为空"
	fi
	old_ifs="$IFS"
	IFS='
'
	for entry in $entries; do
		clean="${entry#./}"
		clean="${clean%/}"
		if [ -z "$clean" ] && [ "$entry" = "./" ]; then
			continue
		fi
		case "$entry" in
		/*)
			IFS="$old_ifs"
			fail "安装包包含非法的绝对路径成员: $entry"
			;;
		esac
		case "$clean" in
		.. | ../* | */.. | */../*)
			IFS="$old_ifs"
			fail "安装包包含路径穿越成员: $entry"
			;;
		esac
		if [ -n "$required_prefix" ]; then
			case "$clean" in
			"$required_prefix" | "$required_prefix"/*) ;;
			*)
				IFS="$old_ifs"
				fail "安装包包含预期目录外的成员: $entry"
				;;
			esac
		fi
	done
	IFS="$old_ifs"

	if has_cmd python3; then
		python3 -c '
import posixpath, sys, tarfile
with tarfile.open(sys.argv[1], "r:*") as tf:
    for m in tf.getmembers():
        if m.islnk():
            sys.stderr.write(f"hardlink member rejected: {m.name} -> {m.linkname}\n")
            sys.exit(1)
        if m.issym():
            target = m.linkname or ""
            if not target or target.startswith("/") or target.startswith("\\"):
                sys.stderr.write(f"absolute symlink rejected: {m.name} -> {target}\n")
                sys.exit(1)
            parent = posixpath.dirname(m.name.lstrip("./"))
            joined = posixpath.normpath(posixpath.join(parent, target))
            if joined == ".." or joined.startswith("../"):
                sys.stderr.write(f"escaping symlink rejected: {m.name} -> {target}\n")
                sys.exit(1)
' "$archive_file" || fail "安装包在解压前检测到危险符号链接或硬链接成员"
	else
		tar -tvzf "$archive_file" | awk '
			substr($1, 1, 1) == "h" { exit 1 }
			substr($1, 1, 1) == "l" {
				pos = index($0, " -> ")
				if (pos == 0) exit 1
				target = substr($0, pos + 4)
				if (target == "" || target ~ /^\// || target ~ /(^|\/)\.\.(\/|$)/) exit 1
			}
		' || fail "安装包在解压前检测到危险符号链接或硬链接成员"
	fi
}

verify_extracted_symlinks() {
	root_dir="$1"
	links="$(find "$root_dir" -type l 2>/dev/null || true)"
	if [ -z "$links" ]; then
		return 0
	fi
	if has_cmd python3; then
		python3 -c '
import os, sys
root = os.path.realpath(sys.argv[1])
for path in sys.stdin.read().splitlines():
    if not path:
        continue
    resolved = os.path.realpath(path)
    if resolved != root and not resolved.startswith(root + os.sep):
        sys.stderr.write(f"symlink escapes staging directory: {path} -> {resolved}\n")
        sys.exit(1)
' "$root_dir" <<EOF || fail "安装包解压后包含越界符号链接"
$links
EOF
	elif has_cmd node; then
		node -e '
const fs = require("fs"), path = require("path");
const root = fs.realpathSync(process.argv[1]);
const lines = fs.readFileSync(0, "utf8").split(/\r?\n/).filter(Boolean);
for (const p of lines) {
  let resolved;
  try { resolved = fs.realpathSync(p); } catch { process.exit(1); }
  if (resolved !== root && !resolved.startsWith(root + path.sep)) process.exit(1);
}
' "$root_dir" <<EOF || fail "安装包解压后包含越界符号链接"
$links
EOF
	else
		fail "安装包包含符号链接但缺少路径校验运行时"
	fi
}

resolve_latest_manifest() {
	validate_base_url "$GITHUB_BASE"
	manifest_url="${GITHUB_BASE%/}/${RELEASE_REPO}/releases/latest/download/update-${TARGET}.json"
	info "2/3 获取最新发行版清单 ($manifest_url)"
	manifest_json="$(fetch_text "$manifest_url")" || fail "无法获取 $TARGET 的更新清单，请检查网络连接"
	VERSION="$(parse_json_string "version" "$manifest_json")"
	ARCHIVE_URL="$(parse_json_string "url" "$manifest_json")"
	SIGNATURE="$(parse_json_string "signature" "$manifest_json")"
	EXPECTED_SIZE="$(parse_json_int "size" "$manifest_json")"
	if [ -z "$VERSION" ] || [ -z "$ARCHIVE_URL" ] || [ -z "$SIGNATURE" ]; then
		fail "解析更新清单失败（缺少版本、下载地址或 Ed25519 签名）: $manifest_url"
	fi
	validate_version_string "$VERSION"
	expected_archive_url="${GITHUB_BASE%/}/${RELEASE_REPO}/releases/download/desktop-v${VERSION}/${SLUG}-${VERSION}-${TARGET}.tar.gz"
	if [ "$ARCHIVE_URL" != "$expected_archive_url" ]; then
		fail "更新清单中的安装包地址异常: ${ARCHIVE_URL}（期望 ${expected_archive_url}）"
	fi
	ok "最新版本: v${VERSION}"
}

uninstall_reeve() {
	detect_platform
	if [ -n "$INSTALL_DIR" ]; then
		validate_install_dir "$INSTALL_DIR"
	fi
	if [ "$OS" = "darwin" ]; then
		for dir in "${INSTALL_DIR:-}" "/Applications" "$HOME/Applications"; do
			if [ -n "$dir" ] && [ -d "$dir/$BUNDLE" ]; then
				rm -rf "$dir/$BUNDLE"
				ok "已移除 $dir/$BUNDLE"
			fi
		done
		rm -f "$HOME/.local/bin/$SLUG"
		ok "$APP_NAME 已卸载（个人配置与项目数据保留在 ~/Library/Application Support/Reeve）"
	else
		app_dir="${INSTALL_DIR:-$HOME/.local/$SLUG.app}"
		validate_install_dir "$app_dir"
		data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
		rm -rf "$app_dir"
		rm -f "$HOME/.local/bin/$SLUG" "$data_home/applications/$SLUG.desktop"
		ok "$APP_NAME 已卸载（个人配置与项目数据保留在 ~/.config/Reeve）"
	fi
}

install_macos() {
	dest_root="$INSTALL_DIR"
	if [ -z "$dest_root" ]; then
		if [ -w "/Applications" ]; then
			dest_root="/Applications"
		else
			dest_root="$HOME/Applications"
		fi
	fi
	validate_install_dir "$dest_root"
	mkdir -p "$dest_root"

	work_dir="$(mktemp -d)"
	trap 'rm -rf "$work_dir"' EXIT INT TERM
	archive_file="$work_dir/${SLUG}-${VERSION}-${TARGET}.tar.gz"

	info "3/3 下载并安装 $APP_NAME v${VERSION} -> ${dest_root}/${BUNDLE}"
	fetch_file "$ARCHIVE_URL" "$archive_file"

	if [ -n "$EXPECTED_SIZE" ]; then
		actual_size="$(wc -c <"$archive_file" | tr -d '[:space:]')"
		if [ "$actual_size" != "$EXPECTED_SIZE" ]; then
			fail "安装包字节大小校验不匹配（期望 ${EXPECTED_SIZE}，实际 ${actual_size}）"
		fi
		ok "安装包字节长度校验通过 (${actual_size} 字节)"
	fi

	verify_archive_signature "$archive_file" "$SIGNATURE" "$UPDATE_PUBLIC_KEY"
	verify_tar_archive_safety "$archive_file" "$BUNDLE"

	tar -xzf "$archive_file" -C "$work_dir"
	verify_extracted_symlinks "$work_dir"
	if [ ! -d "$work_dir/$BUNDLE" ]; then
		fail "归档中未找到 $BUNDLE"
	fi

	# 清除 macOS 下载隔离扩展属性，确保下载后可直接双击或命令行打开
	xattr -dr com.apple.quarantine "$work_dir/$BUNDLE" 2>/dev/null || true

	target_app="${dest_root}/${BUNDLE}"
	rm -rf "$target_app"
	mv "$work_dir/$BUNDLE" "$target_app"
	ok "已安装应用至: $target_app"

	# 注册命令行快捷启动入口 ~/.local/bin/reeve
	if mkdir -p "$HOME/.local/bin" 2>/dev/null; then
		cat >"$HOME/.local/bin/$SLUG" <<EOF
#!/bin/sh
exec open -a '$target_app' "\$@"
EOF
		chmod +x "$HOME/.local/bin/$SLUG"
		ok "已创建命令行启动入口: ~/.local/bin/$SLUG"
	fi

	printf '\n\033[1;32m🎉 %s v%s 安装完成，现在可以直接使用！\033[0m\n' "$APP_NAME" "$VERSION"
	if [ -z "$NO_OPEN" ]; then
		info "正在启动 $APP_NAME..."
		open "$target_app" || true
	fi
}

install_linux() {
	app_dir="${INSTALL_DIR:-$HOME/.local/$SLUG.app}"
	validate_install_dir "$app_dir"
	bin_dir="$HOME/.local/bin"
	data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
	desktop_file="$data_home/applications/$SLUG.desktop"

	work_dir="$(mktemp -d)"
	staging_dir="${app_dir}.staging.$$"
	trap 'rm -rf "$work_dir" "$staging_dir"' EXIT INT TERM
	archive_file="$work_dir/${SLUG}-${VERSION}-${TARGET}.tar.gz"

	info "3/3 下载并安装 $APP_NAME v${VERSION} -> $app_dir"
	fetch_file "$ARCHIVE_URL" "$archive_file"

	if [ -n "$EXPECTED_SIZE" ]; then
		actual_size="$(wc -c <"$archive_file" | tr -d '[:space:]')"
		if [ "$actual_size" != "$EXPECTED_SIZE" ]; then
			fail "安装包字节大小校验不匹配（期望 ${EXPECTED_SIZE}，实际 ${actual_size}）"
		fi
		ok "安装包字节长度校验通过 (${actual_size} 字节)"
	fi

	verify_archive_signature "$archive_file" "$SIGNATURE" "$UPDATE_PUBLIC_KEY"
	verify_tar_archive_safety "$archive_file"

	mkdir -p "$staging_dir"
	tar -xzf "$archive_file" -C "$staging_dir"
	verify_extracted_symlinks "$staging_dir"
	chmod +x "$staging_dir/$SLUG" 2>/dev/null || true
	if [ -f "$staging_dir/resources/bin/reeve" ]; then
		chmod +x "$staging_dir/resources/bin/reeve" 2>/dev/null || true
	fi

	mkdir -p "$(dirname "$app_dir")" "$bin_dir" "$data_home/applications"
	rm -rf "$app_dir"
	mv "$staging_dir" "$app_dir"
	ln -sf "$app_dir/$SLUG" "$bin_dir/$SLUG"
	ok "已安装应用目录: $app_dir"
	ok "已创建命令行启动入口: $bin_dir/$SLUG"

	icon_path="$app_dir/$SLUG.png"
	cat >"$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=原生多智能体工程与个人工作台
Exec="$app_dir/$SLUG" %U
Icon=$icon_path
Terminal=false
Categories=Development;IDE;Utility;
StartupWMClass=$SLUG
EOF
	ok "已注册桌面应用菜单: $desktop_file"

	case ":${PATH:-}:" in
	*":$bin_dir:"*) ;;
	*) warn "请将 $bin_dir 加入 PATH，或直接运行 $app_dir/$SLUG 启动" ;;
	esac

	printf '\n\033[1;32m🎉 %s v%s 安装完成，现在可以直接运行 `reeve` 或从桌面菜单启动！\033[0m\n' "$APP_NAME" "$VERSION"
}

while [ $# -gt 0 ]; do
	case "$1" in
	--install-deps)
		AUTO_INSTALL_DEPS=1
		;;
	--check-only)
		CHECK_ONLY=1
		;;
	--no-open)
		NO_OPEN=1
		;;
	--uninstall)
		UNINSTALL=1
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		fail "未知参数: $1（使用 --help 查看帮助）"
		;;
	esac
	shift
done

if [ "$UNINSTALL" = "1" ]; then
	uninstall_reeve
	exit 0
fi

detect_platform
check_environment

if [ "$CHECK_ONLY" = "1" ]; then
	info "环境检测完成（--check-only 模式未执行安装）"
	exit 0
fi

resolve_latest_manifest
if [ "$OS" = "darwin" ]; then
	install_macos
else
	install_linux
fi
