#!/usr/bin/env bash
# ==============================================================================
# YuxuanShell 安装脚本（支持 curl 一键安装）
# - 支持 macOS 与 Debian/Ubuntu
# - 支持通过环境变量自定义安装：
#     YS_CMD=easy            # 主命令名（默认：easy）
#     YS_COMPAT_CMDS="easy.sh yuxuan-shell"  # 兼容命令（可选）
#     YS_PREFIX=/usr/local   # 安装前缀（默认：/usr/local）
#     YS_FORCE=1             # 覆盖已有命令/链接（默认：0）
# - 既可在仓库本地运行，也可通过 curl | bash 运行（自动从 GitHub 下载源码）
# ==============================================================================

set -euo pipefail

# --------------------------- 配置与常量 ---------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

YS_PREFIX="${YS_PREFIX:-/usr/local}"
YS_CMD="${YS_CMD:-easy}"
YS_COMPAT_CMDS_DEFAULT="easy.sh yuxuan-shell"
YS_COMPAT_CMDS="${YS_COMPAT_CMDS:-$YS_COMPAT_CMDS_DEFAULT}"
YS_FORCE="${YS_FORCE:-0}"

APP_DIR="$YS_PREFIX/share/yuxuan_shell"
BIN_DIR="$YS_PREFIX/bin"
PRIMARY_BIN="$BIN_DIR/$YS_CMD"

REPO_OWNER="SirYuxuan"
REPO_NAME="YuxuanShell"
REPO_BRANCH="${YS_BRANCH:-main}"
TARBALL_URL="https://codeload.github.com/$REPO_OWNER/$REPO_NAME/tar.gz/refs/heads/$REPO_BRANCH"

if [[ "$(id -u)" -ne 0 ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

TMP_DIR=""

# --------------------------- 日志函数 -----------------------------------------
log_info()  { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()  { echo -e "${BLUE}==>${NC} $*" >&2; }

# --------------------------- 实用函数 -----------------------------------------
check_dependencies() {
    local missing=()
    local req=(curl tar)
    for c in "${req[@]}"; do
        command -v "$c" >/dev/null 2>&1 || missing+=("$c")
    done
    if ((${#missing[@]} > 0)); then
        log_error "缺少必要依赖: ${missing[*]}"
        log_info  "请先安装上述依赖后重试。"
        exit 1
    fi
}

# 返回可能的仓库根目录（如果脚本存在于本地仓库内），否则返回空
guess_local_root() {
    local script_path
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        script_path="${BASH_SOURCE[0]}"
    else
        script_path="$0"
    fi
    # 当通过管道执行时，$0 多为 bash/-bash，找不到本地路径；此时返回空
    if [[ ! -e "$script_path" ]]; then
        echo ""
        return 0
    fi
    local dir
    dir="$(cd "$(dirname "$script_path")" >/dev/null 2>&1 && pwd || echo "")"
    if [[ -z "$dir" ]]; then
        echo ""
        return 0
    fi
    local root="$(cd "$dir/.." >/dev/null 2>&1 && pwd || echo "")"
    if [[ -n "$root" && -f "$root/src/main.sh" ]]; then
        echo "$root"
    else
        echo ""
    fi
}

# 下载仓库源码到临时目录，并输出源码根目录路径
download_source() {
    check_dependencies
    TMP_DIR="$(mktemp -d)"
    trap '[[ -n "$TMP_DIR" ]] && rm -rf "$TMP_DIR" || true' EXIT
    log_step "下载源码：$TARBALL_URL"
    # 将下载与解压的进度输出到 stderr，避免污染 stdout
    curl -fsSL "$TARBALL_URL" | tar -xzf - -C "$TMP_DIR" 1>&2
    local extracted
    extracted="$(find "$TMP_DIR" -maxdepth 1 -type d -name "$REPO_NAME-*" | head -n 1 || true)"
    if [[ -z "$extracted" ]]; then
        log_error "解压失败：未找到源码目录"
        exit 1
    fi
    # 仅将路径输出到 stdout
    echo "$extracted"
}

# 创建目录（需要 root）
ensure_dirs() {
    $SUDO mkdir -p "$APP_DIR" "$BIN_DIR"
}

# 复制源码到 APP_DIR（默认使用 cp；如设置 YS_USE_RSYNC=1 且 rsync 可用，则使用 rsync）
copy_source() {
    local src_root="$1"
    log_info "复制源码: src_root='$src_root' -> APP_DIR='$APP_DIR'"
    if [[ "${YS_USE_RSYNC:-0}" == "1" ]] && command -v rsync >/dev/null 2>&1; then
        $SUDO rsync -a --delete -- "$src_root/src/" "$APP_DIR/"
    else
        $SUDO rm -rf "$APP_DIR"/* 2>/dev/null || true
        $SUDO mkdir -p "$APP_DIR"
        # 使用 tar 管道复制以更好地保留权限（兼容空目录）
        (cd "$src_root/src" && tar -cf - .) | $SUDO tar -xf - -C "$APP_DIR"
    fi
    $SUDO chmod +x "$APP_DIR/main.sh" || true
}

# 创建命令（主命令 + 兼容命令）
create_command() {
    local target_bin="$1" # 如 /usr/local/bin/easy
    local overwrite="$2"  # 1/0
    if [[ -e "$target_bin" && "$overwrite" != "1" ]]; then
        log_warn "已存在: $target_bin（跳过，设置 YS_FORCE=1 可覆盖）"
        return 0
    fi
    # 优先尝试符号链接
    if $SUDO ln -sf "$APP_DIR/main.sh" "$target_bin" 2>/dev/null; then
        :
    else
        # 回退为启动器脚本
        local tmp_launcher
        tmp_launcher="$(mktemp)"
        printf '#!/usr/bin/env bash\nexec "%s/main.sh" "$@"\n' "$APP_DIR" > "$tmp_launcher"
        $SUDO install -m 0755 "$tmp_launcher" "$target_bin"
        rm -f "$tmp_launcher"
    fi
    log_info "已安装命令: $target_bin -> $APP_DIR/main.sh"
}

install_main() {
    log_step "开始安装 YuxuanShell"
    log_info "安装前缀: $YS_PREFIX"
    log_info "安装目录: $APP_DIR"
    log_info "主命令名: $YS_CMD"
    [[ -n "$YS_COMPAT_CMDS" ]] && log_info "兼容命令: $YS_COMPAT_CMDS"

    ensure_dirs

    local root
    root="$(guess_local_root)"
    if [[ -n "$root" ]]; then
        log_step "使用本地源码: $root"
    else
        root="$(download_source)"
        log_step "使用下载源码: $root"
    fi

    copy_source "$root"
    create_command "$PRIMARY_BIN" "$YS_FORCE"

    # 兼容命令
    if [[ -n "$YS_COMPAT_CMDS" ]]; then
        for alt in $YS_COMPAT_CMDS; do
            [[ "$alt" == "$YS_CMD" ]] && continue
            create_command "$BIN_DIR/$alt" "$YS_FORCE"
        done
    fi

    # 验证
    if "$PRIMARY_BIN" --version >/dev/null 2>&1 || "$PRIMARY_BIN" -v >/dev/null 2>&1; then
        log_step "安装成功"
        echo
        echo -e "${GREEN}YuxuanShell 已安装${NC}"
        echo "- 程序目录: $APP_DIR"
        echo "- 主命令:   $PRIMARY_BIN"
        if [[ -n "$YS_COMPAT_CMDS" ]]; then
            echo "- 兼容命令: $(for a in $YS_COMPAT_CMDS; do [[ $a != $YS_CMD ]] && printf '%s ' "$BIN_DIR/$a"; done)"
        fi
        echo
        echo "用法示例:"
        echo "  $YS_CMD --help"
        echo "  $YS_CMD system info"
        echo "  $YS_CMD network list-port"
        echo
        # PATH 提示
        case ":$PATH:" in
            *":$BIN_DIR:"*) :;;
            *) log_warn "当前 PATH 可能不包含 $BIN_DIR，请确保它在 PATH 中或重启终端。";;
        esac
    else
        log_warn "安装完成，但运行验证未通过，请手动运行: $PRIMARY_BIN --help"
    fi
}

uninstall_main() {
    log_step "卸载 YuxuanShell"
    # 删除主命令
    if [[ -e "$PRIMARY_BIN" || -L "$PRIMARY_BIN" ]]; then
        $SUDO rm -f "$PRIMARY_BIN"
        log_info "已删除: $PRIMARY_BIN"
    fi
    # 删除兼容命令
    if [[ -n "$YS_COMPAT_CMDS" ]]; then
        for alt in $YS_COMPAT_CMDS; do
            local p="$BIN_DIR/$alt"
            [[ -e "$p" || -L "$p" ]] && $SUDO rm -f "$p" && log_info "已删除: $p"
        done
    fi
    # 删除程序目录
    if [[ -d "$APP_DIR" ]]; then
        $SUDO rm -rf "$APP_DIR"
        log_info "已删除目录: $APP_DIR"
    fi
    log_step "卸载完成"
}

show_help() {
    cat <<EOF
YuxuanShell 安装脚本

用法:
    bash install.sh [install|uninstall|--help]
    # 或者通过 curl 一键安装（默认 install）：
    curl -fsSL https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$REPO_BRANCH/scripts/install.sh | sudo -E bash

环境变量:
    YS_CMD=easy                主命令名（默认：easy）
    YS_COMPAT_CMDS="easy.sh yuxuan-shell"  兼容命令名（可为空）
    YS_PREFIX=/usr/local       安装前缀（默认：/usr/local）
    YS_FORCE=1                 覆盖已有命令/链接（默认：0）
    YS_BRANCH=main             指定下载分支（默认：main）

示例:
    YS_CMD=easy YS_FORCE=1 curl -fsSL https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$REPO_BRANCH/scripts/install.sh | sudo -E bash
EOF
}

main() {
    local action="${1:-install}"
    case "$action" in
        install)
            check_dependencies
            install_main
            ;;
        uninstall)
            uninstall_main
            ;;
        -h|--help|help)
            show_help
            ;;
        *)
            log_error "未知命令: $action"
            show_help
            exit 1
            ;;
    esac
}

main "$@"