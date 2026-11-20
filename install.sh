#!/bin/sh
# Reeve 跨平台一键环境检测与安装脚本 (macOS / Linux)
#
# 一键检测环境并安装最新版 Reeve：
#   curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh
#
# 一键检测、自动补齐缺失环境依赖（Git / Ripgrep / Node / Linux GTK4 等）并安装 Reeve：
#   curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --install-deps
#
# 仅执行宿主机环境诊断：
#   curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --check-only
#
# 卸载 Reeve（保留用户项目与会话数据）：
#   curl -fsSL https://github.com/chengyunyi/reeve-releases/releases/latest/download/install.sh | sh -s -- --uninstall

set -eu

APP_NAME="Reeve"
SLUG="reeve"
BUNDLE="Reeve.app"
RELEASE_REPO="${REEVE_RELEASE_REPO:-chengyunyi/reeve-releases}"
GITHUB_BASE="${REEVE_GITHUB_BASE:-https://github.com}"
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
  --uninstall      卸载已安装的 $APP_NAME（保留用户配置与项目数据）
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

parse_json_string() {
	key="$1"
	json_text="$2"
	printf '%s' "$json_text" | tr '\n' ' ' | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

parse_json_int() {
	key="$1"
	json_text="$2"
	printf '%s' "$json_text" | tr '\n' ' ' | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p"
}

resolve_latest_manifest() {
	manifest_url="${GITHUB_BASE%/}/${RELEASE_REPO}/releases/latest/download/update-${TARGET}.json"
	info "2/3 获取最新发行版清单 ($manifest_url)"
	manifest_json="$(fetch_text "$manifest_url")" || fail "无法获取 $TARGET 的更新清单，请检查网络连接"
	VERSION="$(parse_json_string "version" "$manifest_json")"
	ARCHIVE_URL="$(parse_json_string "url" "$manifest_json")"
	EXPECTED_SIZE="$(parse_json_int "size" "$manifest_json")"
	if [ -z "$VERSION" ] || [ -z "$ARCHIVE_URL" ]; then
		fail "解析更新清单失败: $manifest_url"
	fi
	ok "最新版本: v${VERSION}"
}

uninstall_reeve() {
	detect_platform
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
	mkdir -p "$dest_root"

	work_dir="$(mktemp -d)"
	trap 'rm -rf "$work_dir"' EXIT INT TERM
	archive_file="$work_dir/${SLUG}-${VERSION}-${TARGET}.tar.gz"

	info "3/3 下载并安装 $APP_NAME v${VERSION} -> ${dest_root}/${BUNDLE}"
	fetch_file "$ARCHIVE_URL" "$archive_file"

	if [ -n "$EXPECTED_SIZE" ]; then
		actual_size="$(wc -c <"$archive_file" | tr -d '[:space:]')"
		if [ "$actual_size" != "$EXPECTED_SIZE" ]; then
			fail "安装包字节大小校验不匹配（期望 $EXPECTED_SIZE，实际 $actual_size）"
		fi
		ok "安装包完整性校验通过 (${actual_size} 字节)"
	fi

	tar -xzf "$archive_file" -C "$work_dir"
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
exec open -a "$target_app" "\$@"
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
			fail "安装包字节大小校验不匹配（期望 $EXPECTED_SIZE，实际 $actual_size）"
		fi
		ok "安装包完整性校验通过 (${actual_size} 字节)"
	fi

	mkdir -p "$staging_dir"
	tar -xzf "$archive_file" -C "$staging_dir"
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
