#!/bin/bash
#==============================================================================
# YuxuanShell 安装脚本
#==============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 安装前缀（可通过环境变量覆盖），默认 /usr/local，用于系统范围安装
readonly YS_PREFIX="${YS_PREFIX:-/usr/local}"
# 安装目录（程序主体）
readonly APP_DIR="$YS_PREFIX/share/yuxuan_shell"
# 可执行文件目标路径
readonly BIN_PATH="$YS_PREFIX/bin/yuxuan-shell"

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

#==============================================================================
# 日志函数
#==============================================================================
log() {
    local level="$1"
    local message="$2"
    # 可执行命令名（可通过环境变量覆盖），默认使用“easy”，不带 .sh
    readonly YS_CMD="${YS_CMD:-easy}"
    # 兼容命令名（以空格分隔），会额外创建为软链或启动器，可按需覆盖
    readonly YS_COMPAT_CMDS_DEFAULT="easy.sh yuxuan-shell"
    readonly YS_COMPAT_CMDS="${YS_COMPAT_CMDS:-$YS_COMPAT_CMDS_DEFAULT}"

    # 可执行文件主目标路径
    readonly BIN_PATH="$YS_PREFIX/bin/$YS_CMD"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
    create_directories() {
        log_info "创建系统目录..."
        # 需要root权限写入 /usr/local
        if [[ ! -d "$APP_DIR" ]]; then
            sudo mkdir -p "$APP_DIR"
            log_debug "创建目录: $APP_DIR"
        fi
        # 确保 bin 目录存在
        if [[ ! -d "$YS_PREFIX/bin" ]]; then
            sudo mkdir -p "$YS_PREFIX/bin"

            # 创建兼容命令软链/启动器
            for alt in $YS_COMPAT_CMDS; do
                local alt_path="$YS_PREFIX/bin/$alt"
                # 跳过与主命令同名
                [[ "$alt" == "$YS_CMD" ]] && continue
                if [[ -L "$alt_path" || -f "$alt_path" ]]; then
                    log_warn "发现已有可执行/链接: $alt_path，跳过创建（可通过先卸载或手动删除来覆盖）"
                    continue
                fi
                if sudo ln -s "$APP_DIR/main.sh" "$alt_path" 2>/dev/null; then
                    log_info "创建兼容命令: $alt_path -> $APP_DIR/main.sh"
                else
                    echo "#!/bin/bash" | sudo tee "$alt_path" >/dev/null
                    echo "exec \"$APP_DIR/main.sh\" \"\$@\"" | sudo tee -a "$alt_path" >/dev/null
                    sudo chmod +x "$alt_path"
                    log_info "已创建兼容启动器: $alt_path"
                fi
            done
            log_debug "创建目录: $YS_PREFIX/bin"
        fi
        log_info "目录创建完成"
# 系统检测
#==============================================================================
detect_system() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
    copy_files() {
        log_info "复制程序文件到 $APP_DIR ..."
        # 同步 src 到 APP_DIR（覆盖更新）
        sudo rsync -a --delete "$ROOT_DIR/src/" "$APP_DIR/" 2>/dev/null || {
            # 如果 rsync 不可用，回退到 cp
            sudo rm -rf "$APP_DIR"/* 2>/dev/null || true
            sudo mkdir -p "$APP_DIR"
            sudo cp -R "$ROOT_DIR/src/"* "$APP_DIR/"
            for alt in $YS_COMPAT_CMDS; do
                local alt_path="$YS_PREFIX/bin/$alt"
                if [[ -L "$alt_path" || -f "$alt_path" ]]; then
                    sudo rm -f "$alt_path"
                    log_info "删除兼容命令: $alt_path"
                fi
            done
        }
        # 确保主程序可执行
        sudo chmod +x "$APP_DIR/main.sh"
        log_info "文件复制完成"
    
    log_info "检查系统依赖..."
    
    # 基础工具
    local basic_tools=("curl" "tar" "find" "grep" "awk" "sed")
    create_symlink() {
        local link_path="$BIN_PATH"
        if [[ -L "$link_path" ]] || [[ -f "$link_path" ]]; then
            log_warn "发现已有可执行/链接: $link_path"
            if ask_confirmation "是否覆盖已有的可执行文件/链接？"; then
                sudo rm -f "$link_path"
            else
                log_info "跳过创建全局命令"
                return 0
            fi
        fi
        if sudo ln -s "$APP_DIR/main.sh" "$link_path" 2>/dev/null; then
            log_info "创建全局命令成功: $link_path -> $APP_DIR/main.sh"
        else
            # 回退为复制一个轻量启动器
            log_warn "符号链接创建失败，尝试复制启动器"
            echo "#!/bin/bash" | sudo tee "$link_path" >/dev/null
            echo "exec \"$APP_DIR/main.sh\" \"\$@\"" | sudo tee -a "$link_path" >/dev/null
            sudo chmod +x "$link_path"
            log_info "已创建启动器: $link_path"
        fi
        log_error "缺少必需的依赖: ${missing_deps[*]}"
        log_info "请安装这些工具后重新运行安装脚本"
        
        case "$os_type" in
            "macos")
    configure_shell() {
        if ! command -v yuxuan-shell >/dev/null 2>&1; then
            log_warn "yuxuan-shell 暂未在 PATH 中可见，已安装到: $BIN_PATH"
            log_info "请确认 /usr/local/bin 已包含在 PATH 中，或重启终端。"
        else
            log_info "全局命令已可用: yuxuan-shell"
        fi
    log_info "创建目录结构..."
    
    local directories=(
        "$INSTALL_DIR"
        "$BIN_DIR"
    create_desktop_entry() { :; }
    
    # 复制模块
    if [[ ! -d "$INSTALL_DIR/src" ]]; then
        mkdir -p "$INSTALL_DIR/src"
    fi
    
    cp -r "$ROOT_DIR/src/"* "$INSTALL_DIR/src/"
        # 主程序位置
        if [[ ! -f "$APP_DIR/main.sh" ]]; then
            log_error "主程序文件不存在: $APP_DIR/main.sh"
            return 1
        fi
        if [[ ! -x "$APP_DIR/main.sh" ]]; then
            log_error "主程序不可执行: $APP_DIR/main.sh"
            return 1
        fi
        # 测试全局命令
        if "$BIN_PATH" --version >/dev/null 2>&1; then
create_symlink() {
    local link_path="/usr/local/bin/yuxuan-shell"
    
    if [[ -L "$link_path" ]] || [[ -f "$link_path" ]]; then
        log_warn "符号链接已存在: $link_path"
        if ask_confirmation "是否要覆盖现有的符号链接？"; then
            sudo rm -f "$link_path"
        else
            log_info "跳过符号链接创建"
            return 0
        fi
    fi
    
    if sudo ln -s "$BIN_DIR/yuxuan-shell" "$link_path" 2>/dev/null; then
        log_info "符号链接创建成功: $link_path"
    else
        log_warn "无法创建全局符号链接，请手动添加到PATH: $BIN_DIR"
    fi
}

#==============================================================================
# 配置Shell
#==============================================================================
configure_shell() {
    log_info "配置Shell环境..."
    
    local shell_configs=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
    )
    
    local path_line="export PATH=\"$BIN_DIR:\$PATH\""
    local alias_line="alias yuxuan='yuxuan-shell'"
    
    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]]; then
            # 检查PATH是否已配置
            if ! grep -q "$BIN_DIR" "$config_file" 2>/dev/null; then
                echo "" >> "$config_file"
                echo "# YuxuanShell configuration" >> "$config_file"
                echo "$path_line" >> "$config_file"
                echo "$alias_line" >> "$config_file"
                log_debug "已配置 $config_file"
            fi
        fi
    done
    
    log_info "Shell环境配置完成"
}
        # 删除全局命令
        if [[ -L "$BIN_PATH" || -f "$BIN_PATH" ]]; then
            sudo rm -f "$BIN_PATH"
            log_info "删除全局命令: $BIN_PATH"
create_desktop_entry() {
    local os_type
        # 删除安装目录
        if [[ -d "$APP_DIR" ]]; then
            sudo rm -rf "$APP_DIR"
            log_info "删除安装目录: $APP_DIR"
    fi
    
    
    cat > "$HOME/.local/share/applications/yuxuan-shell.desktop" << EOF
        log_info "提示: 如有自定义 PATH 配置可自行清理"
Name=YuxuanShell
Comment=Universal Shell Toolkit
Exec=gnome-terminal -- yuxuan-shell
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF
    
    chmod +x "$HOME/.local/share/applications/yuxuan-shell.desktop"
    log_info "桌面快捷方式创建完成"
}

#==============================================================================
# 验证安装
#==============================================================================
verify_installation() {
    安装前缀: $YS_PREFIX
    程序目录: $APP_DIR
    命令路径: $BIN_PATH
    if [[ ! -f "$BIN_DIR/yuxuan-shell" ]]; then
        log_error "主程序文件不存在"
        return 1
        YS_PREFIX=/custom/prefix sudo -E bash scripts/install.sh  (自定义安装前缀)
    
    if [[ ! -x "$BIN_DIR/yuxuan-shell" ]]; then
        log_error "主程序文件不可执行"
        return 1
    fi
    
    # 测试程序是否能正常运行
    if "$BIN_DIR/yuxuan-shell" --version >/dev/null 2>&1; then
        log_info "程序运行测试通过"
    else
        log_warn "程序运行测试失败，可能存在配置问题"
    fi
        log_info "目标: $APP_DIR"
    log_info "安装验证完成"
    return 0
        if [[ -f "$BIN_PATH" || -d "$APP_DIR" ]]; then
            log_warn "检测到已安装的 YuxuanShell"
#==============================================================================
# 用户确认函数
#==============================================================================
ask_confirmation() {
    local message="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        echo -n "$message [Y/n]: "
    else
        echo -n "$message [y/N]: "
    
    read -r response
    
    if [[ -z "$response" ]]; then
            echo -e "${GREEN}YuxuanShell 已安装: $BIN_PATH -> $APP_DIR/main.sh${NC}"
    fi
    
            echo "  yuxuan-shell --help                 # 查看帮助"
            echo "  yuxuan-shell system info            # 显示系统信息"
            echo "  yuxuan-shell network ping github.com # 网络 ping 测试"
        *)
            return 1
            echo "  如命令不可用，请确认 /usr/local/bin 已在 PATH 中，或重启终端"

#==============================================================================
# 卸载功能
#==============================================================================
uninstall() {
    log_info "开始卸载YuxuanShell..."
    
    if ! ask_confirmation "确定要卸载YuxuanShell吗？这将删除所有相关文件"; then
        log_info "取消卸载"
        return 0
    fi
    
    # 删除符号链接
    if [[ -L "/usr/local/bin/yuxuan-shell" ]]; then
        sudo rm -f "/usr/local/bin/yuxuan-shell"
        log_info "删除符号链接"
    fi
    
    # 删除安装目录
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        log_info "删除安装目录: $INSTALL_DIR"
    fi
    
    # 删除桌面快捷方式
    if [[ -f "$HOME/.local/share/applications/yuxuan-shell.desktop" ]]; then
        rm -f "$HOME/.local/share/applications/yuxuan-shell.desktop"
        log_info "删除桌面快捷方式"
    fi
    
    log_info "YuxuanShell卸载完成"
    log_warn "请手动从Shell配置文件中移除相关配置"
}

#==============================================================================
# 显示帮助信息
#==============================================================================
show_help() {
    cat << EOF
YuxuanShell 安装脚本

用法: $0 [选项]

选项:
    install     安装YuxuanShell (默认)
    uninstall   卸载YuxuanShell
    --help      显示此帮助信息

安装位置: $INSTALL_DIR
二进制文件: $BIN_DIR/yuxuan-shell

安装后，你可以通过以下方式使用:
    yuxuan-shell --help
    yuxuan --help (如果配置了别名)
EOF
}

#==============================================================================
# 主安装流程
#==============================================================================
install_yuxuan_shell() {
    echo -e "${BLUE}==================== YuxuanShell 安装程序 ====================${NC}"
    echo -e "${GREEN}欢迎使用YuxuanShell安装程序${NC}"
    echo
    
    log_info "开始安装YuxuanShell..."
    log_info "安装目录: $INSTALL_DIR"
    
    # 检查是否已安装
    if [[ -f "$BIN_DIR/yuxuan-shell" ]]; then
        log_warn "YuxuanShell似乎已经安装"
        if ! ask_confirmation "是否要重新安装？"; then
            log_info "取消安装"
            return 0
        fi
    fi
    
    # 执行安装步骤
    check_dependencies || return 1
    create_directories
    copy_files
    create_symlink
    configure_shell
    create_desktop_entry
    
    if verify_installation; then
        echo
        echo -e "${GREEN}==================== 安装成功 ====================${NC}"
        echo -e "${GREEN}YuxuanShell已成功安装到: $INSTALL_DIR${NC}"
        echo
        echo -e "${YELLOW}使用方法:${NC}"
        echo "  yuxuan-shell --help    # 查看帮助"
        echo "  yuxuan-shell system info    # 显示系统信息"
        echo "  yuxuan-shell network ping google.com    # 网络ping测试"
        echo "  yuxuan-shell file backup /path/to/file    # 文件备份"
        echo
        echo -e "${YELLOW}注意:${NC}"
        echo "  请重新启动终端或运行 'source ~/.bashrc' 来使PATH生效"
        echo "  配置文件位置: $CONFIG_DIR"
        echo "  日志文件位置: $LOG_DIR"
        echo
    else
        log_error "安装验证失败"
        return 1
    fi
}

#==============================================================================
# 主函数
#==============================================================================
main() {
    case "${1:-install}" in
        "install")
            install_yuxuan_shell
            ;;
        "uninstall")
            uninstall
            ;;
        "--help"|"-h"|"help")
            show_help
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"