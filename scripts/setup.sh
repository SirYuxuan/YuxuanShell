#!/bin/bash
#==============================================================================
# YuxuanShell 设置脚本
#==============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 配置变量
readonly INSTALL_DIR="$HOME/.yuxuan_shell"
readonly CONFIG_DIR="$INSTALL_DIR/config"
readonly USER_CONFIG="$CONFIG_DIR/user_config.sh"

#==============================================================================
# 日志函数
#==============================================================================
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

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
    fi
    
    read -r response
    
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#==============================================================================
# 获取用户输入
#==============================================================================
get_user_input() {
    local prompt="$1"
    local default="$2"
    local response
    
    if [[ -n "$default" ]]; then
        echo -n "$prompt [$default]: "
    else
        echo -n "$prompt: "
    fi
    
    read -r response
    
    if [[ -z "$response" && -n "$default" ]]; then
        echo "$default"
    else
        echo "$response"
    fi
}

#==============================================================================
# 系统检测
#==============================================================================
detect_system() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     
            if [[ -f /etc/debian_version ]]; then
                echo "debian"
            elif [[ -f /etc/redhat-release ]]; then
                echo "redhat"
            else
                echo "linux"
            fi
            ;;
        *)          echo "unknown" ;;
    esac
}

#==============================================================================
# 检测包管理器
#==============================================================================
detect_package_manager() {
    local os_type
    os_type=$(detect_system)
    
    case "$os_type" in
        "macos")
            if command -v brew >/dev/null 2>&1; then
                echo "brew"
            elif command -v port >/dev/null 2>&1; then
                echo "port"
            else
                echo "none"
            fi
            ;;
        "debian")
            if command -v apt >/dev/null 2>&1; then
                echo "apt"
            elif command -v apt-get >/dev/null 2>&1; then
                echo "apt-get"
            else
                echo "none"
            fi
            ;;
        "redhat")
            if command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            elif command -v yum >/dev/null 2>&1; then
                echo "yum"
            else
                echo "none"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

#==============================================================================
# 创建用户配置
#==============================================================================
create_user_config() {
    log_info "创建用户配置..."
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    # 检查是否已有用户配置
    if [[ -f "$USER_CONFIG" ]]; then
        if ! ask_confirmation "用户配置文件已存在，是否要重新配置？"; then
            log_info "保留现有配置"
            return 0
        fi
        
        # 备份现有配置
        cp "$USER_CONFIG" "$USER_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "已备份现有配置"
    fi
    
    # 获取系统信息
    local os_type
    local pkg_manager
    os_type=$(detect_system)
    pkg_manager=$(detect_package_manager)
    
    echo "# YuxuanShell 用户配置文件" > "$USER_CONFIG"
    echo "# 生成时间: $(date)" >> "$USER_CONFIG"
    echo "" >> "$USER_CONFIG"
    
    # 基本配置
    echo "=== 基本配置 ==="
    
    local debug_mode
    debug_mode=$(get_user_input "启用调试模式" "false")
    echo "DEBUG=$debug_mode" >> "$USER_CONFIG"
    
    local verbose_mode
    verbose_mode=$(get_user_input "启用详细输出模式" "false")
    echo "VERBOSE=$verbose_mode" >> "$USER_CONFIG"
    
    local log_level
    echo "日志级别选项: ERROR, WARN, INFO, DEBUG"
    log_level=$(get_user_input "设置日志级别" "INFO")
    echo "LOG_LEVEL=$log_level" >> "$USER_CONFIG"
    
    echo "" >> "$USER_CONFIG"
    
    # 目录配置
    echo "=== 目录配置 ==="
    
    local backup_dir
    backup_dir=$(get_user_input "备份目录" "$HOME/.yuxuan_shell/backups")
    echo "BACKUP_DIR=\"$backup_dir\"" >> "$USER_CONFIG"
    
    local temp_dir
    temp_dir=$(get_user_input "临时目录" "/tmp/yuxuan_shell")
    echo "TEMP_DIR=\"$temp_dir\"" >> "$USER_CONFIG"
    
    echo "" >> "$USER_CONFIG"
    
    # 网络配置
    echo "=== 网络配置 ==="
    
    local network_timeout
    network_timeout=$(get_user_input "网络超时时间（秒）" "30")
    echo "NETWORK_TIMEOUT=$network_timeout" >> "$USER_CONFIG"
    
    echo "" >> "$USER_CONFIG"
    
    # 系统相关配置
    echo "=== 系统配置 ==="
    
    local monitor_interval
    monitor_interval=$(get_user_input "系统监控刷新间隔（秒）" "5")
    echo "MONITOR_INTERVAL=$monitor_interval" >> "$USER_CONFIG"
    
    local max_backups
    max_backups=$(get_user_input "最大备份保留数量" "10")
    echo "MAX_BACKUPS=$max_backups" >> "$USER_CONFIG"
    
    local auto_cleanup_days
    auto_cleanup_days=$(get_user_input "自动清理文件天数" "7")
    echo "AUTO_CLEANUP_DAYS=$auto_cleanup_days" >> "$USER_CONFIG"
    
    echo "" >> "$USER_CONFIG"
    
    # 工具配置
    echo "=== 工具配置 ==="
    
    local default_editor
    if command -v code >/dev/null 2>&1; then
        default_editor="code"
    elif command -v nano >/dev/null 2>&1; then
        default_editor="nano"
    elif command -v vim >/dev/null 2>&1; then
        default_editor="vim"
    else
        default_editor="vi"
    fi
    default_editor=$(get_user_input "默认编辑器" "$default_editor")
    echo "DEFAULT_EDITOR=\"$default_editor\"" >> "$USER_CONFIG"
    
    local default_compression
    echo "压缩格式选项: tar.gz, tar.bz2, zip, 7z"
    default_compression=$(get_user_input "默认压缩格式" "tar.gz")
    echo "DEFAULT_COMPRESSION=\"$default_compression\"" >> "$USER_CONFIG"
    
    echo "" >> "$USER_CONFIG"
    
    # 系统特定配置
    echo "# 系统特定配置" >> "$USER_CONFIG"
    echo "OS_TYPE=\"$os_type\"" >> "$USER_CONFIG"
    echo "PACKAGE_MANAGER=\"$pkg_manager\"" >> "$USER_CONFIG"
    
    log_info "用户配置创建完成: $USER_CONFIG"
}

#==============================================================================
# 安装可选依赖
#==============================================================================
install_optional_dependencies() {
    local os_type
    local pkg_manager
    os_type=$(detect_system)
    pkg_manager=$(detect_package_manager)
    
    if [[ "$pkg_manager" == "none" || "$pkg_manager" == "unknown" ]]; then
        log_warn "未检测到包管理器，跳过可选依赖安装"
        return 0
    fi
    
    log_info "检查可选依赖..."
    
    local optional_tools=(
        "git:版本控制工具"
        "rsync:文件同步工具" 
        "openssl:加密工具"
        "curl:网络工具"
        "wget:下载工具"
        "tree:目录树显示"
        "htop:进程监控"
        "speedtest-cli:网速测试"
        "nmap:网络扫描"
        "fdupes:重复文件查找"
    )
    
    local missing_tools=()
    local tools_to_install=()
    
    for tool_info in "${optional_tools[@]}"; do
        local tool
        local description
        tool=$(echo "$tool_info" | cut -d: -f1)
        description=$(echo "$tool_info" | cut -d: -f2)
        
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool:$description")
        fi
    done
    
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        log_info "所有可选工具都已安装"
        return 0
    fi
    
    echo
    log_info "发现以下缺失的可选工具:"
    for tool_info in "${missing_tools[@]}"; do
        local tool
        local description
        tool=$(echo "$tool_info" | cut -d: -f1)
        description=$(echo "$tool_info" | cut -d: -f2)
        echo "  - $tool: $description"
    done
    echo
    
    if ask_confirmation "是否要安装这些可选工具？"; then
        for tool_info in "${missing_tools[@]}"; do
            local tool
            tool=$(echo "$tool_info" | cut -d: -f1)
            
            if ask_confirmation "安装 $tool？"; then
                tools_to_install+=("$tool")
            fi
        done
        
        if [[ ${#tools_to_install[@]} -gt 0 ]]; then
            log_info "安装选定的工具: ${tools_to_install[*]}"
            
            case "$pkg_manager" in
                "brew")
                    brew install "${tools_to_install[@]}"
                    ;;
                "apt"|"apt-get")
                    sudo "$pkg_manager" update
                    sudo "$pkg_manager" install -y "${tools_to_install[@]}"
                    ;;
                "dnf"|"yum")
                    sudo "$pkg_manager" install -y "${tools_to_install[@]}"
                    ;;
            esac
            
            log_info "工具安装完成"
        fi
    fi
}

#==============================================================================
# 配置开发环境
#==============================================================================
setup_development_environment() {
    if ! ask_confirmation "是否要设置开发环境？（添加有用的别名和函数）"; then
        return 0
    fi
    
    log_info "配置开发环境..."
    
    local dev_config="$CONFIG_DIR/dev_aliases.sh"
    
    cat > "$dev_config" << 'EOF'
#!/bin/bash
# YuxuanShell 开发环境配置

# 有用的别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# 系统相关别名
alias sysinfo='yuxuan-shell system info'
alias sysmon='yuxuan-shell system monitor'
alias netinfo='yuxuan-shell network info'
alias diskinfo='yuxuan-shell system disk'

# 文件操作别名
alias backup='yuxuan-shell file backup'
alias findfile='yuxuan-shell file find'
alias cleanup='yuxuan-shell file cleanup'

# 网络工具别名
alias myip='yuxuan-shell network info | grep "公网IP"'
alias speedtest='yuxuan-shell network speed'
alias netping='yuxuan-shell network ping'

# Git 别名（如果安装了git）
if command -v git >/dev/null 2>&1; then
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git log --oneline'
    alias gd='git diff'
fi

# 快速函数
mcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    yuxuan-shell file extract "$1"
}

backup_quick() {
    yuxuan-shell file backup "$1"
}

# 系统快捷键
if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS 特定别名
    alias brewup='brew update && brew upgrade'
    alias finder='open -a Finder'
else
    # Linux 特定别名
    alias aptup='sudo apt update && sudo apt upgrade'
    alias ports='netstat -tulanp'
fi
EOF
    
    # 添加到用户配置
    echo "" >> "$USER_CONFIG"
    echo "# 加载开发环境配置" >> "$USER_CONFIG"
    echo "source \"$dev_config\"" >> "$USER_CONFIG"
    
    log_info "开发环境配置完成"
}

#==============================================================================
# 性能优化配置
#==============================================================================
configure_performance() {
    if ! ask_confirmation "是否要应用性能优化配置？"; then
        return 0
    fi
    
    log_info "配置性能优化..."
    
    echo "" >> "$USER_CONFIG"
    echo "# 性能优化配置" >> "$USER_CONFIG"
    
    # 并行处理
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "2")
    echo "PARALLEL_JOBS=$cpu_cores" >> "$USER_CONFIG"
    
    # 缓存配置
    echo "ENABLE_CACHE=true" >> "$USER_CONFIG"
    echo "CACHE_SIZE=100" >> "$USER_CONFIG"
    
    # 历史记录
    echo "HISTORY_SIZE=1000" >> "$USER_CONFIG"
    
    log_info "性能优化配置完成"
}

#==============================================================================
# 创建快速启动脚本
#==============================================================================
create_quick_launch_scripts() {
    if ! ask_confirmation "是否要创建快速启动脚本？"; then
        return 0
    fi
    
    log_info "创建快速启动脚本..."
    
    local scripts_dir="$INSTALL_DIR/scripts"
    mkdir -p "$scripts_dir"
    
    # 系统监控脚本
    cat > "$scripts_dir/monitor.sh" << 'EOF'
#!/bin/bash
# 系统监控快速启动脚本
yuxuan-shell system monitor
EOF
    
    # 网络诊断脚本
    cat > "$scripts_dir/netdiag.sh" << 'EOF'
#!/bin/bash
# 网络诊断快速启动脚本
echo "=== 网络诊断 ==="
yuxuan-shell network info
echo ""
yuxuan-shell network ping 8.8.8.8
EOF
    
    # 系统清理脚本
    cat > "$scripts_dir/cleanup.sh" << 'EOF'
#!/bin/bash
# 系统清理快速启动脚本
yuxuan-shell system cleanup
yuxuan-shell file cleanup "$HOME/Downloads" 30
EOF
    
    chmod +x "$scripts_dir"/*.sh
    
    log_info "快速启动脚本创建完成: $scripts_dir"
}

#==============================================================================
# 显示配置总结
#==============================================================================
show_configuration_summary() {
    echo
    echo -e "${BLUE}==================== 配置总结 ====================${NC}"
    
    if [[ -f "$USER_CONFIG" ]]; then
        echo -e "${GREEN}用户配置文件:${NC} $USER_CONFIG"
        echo
        echo -e "${YELLOW}当前配置:${NC}"
        grep -v "^#" "$USER_CONFIG" | grep -v "^$" | sed 's/^/  /'
    fi
    
    echo
    echo -e "${GREEN}配置文件位置:${NC}"
    echo "  - 主配置: $INSTALL_DIR/src/config/settings.sh"
    echo "  - 用户配置: $USER_CONFIG"
    echo "  - 开发环境: $CONFIG_DIR/dev_aliases.sh"
    
    echo
    echo -e "${GREEN}快速启动脚本:${NC}"
    if [[ -d "$INSTALL_DIR/scripts" ]]; then
        find "$INSTALL_DIR/scripts" -name "*.sh" -type f | sed 's/^/  /'
    fi
    
    echo
    echo -e "${YELLOW}使用建议:${NC}"
    echo "  1. 重启终端或运行 'source ~/.bashrc' 使配置生效"
    echo "  2. 运行 'yuxuan-shell --help' 查看所有可用命令"
    echo "  3. 运行 'yuxuan-shell test' 测试所有功能"
    echo "  4. 查看文档: $INSTALL_DIR/docs/"
}

#==============================================================================
# 主设置流程
#==============================================================================
main_setup() {
    echo -e "${BLUE}==================== YuxuanShell 设置向导 ====================${NC}"
    echo -e "${GREEN}欢迎使用YuxuanShell设置向导${NC}"
    echo
    
    # 检查是否已安装
    if [[ ! -f "$INSTALL_DIR/bin/yuxuan-shell" ]]; then
        log_error "YuxuanShell尚未安装，请先运行安装脚本"
        return 1
    fi
    
    log_info "开始配置YuxuanShell..."
    
    # 配置步骤
    create_user_config
    echo
    install_optional_dependencies
    echo
    setup_development_environment
    echo
    configure_performance
    echo
    create_quick_launch_scripts
    echo
    
    show_configuration_summary
    
    echo
    echo -e "${GREEN}==================== 设置完成 ====================${NC}"
    log_info "YuxuanShell设置向导完成"
}

#==============================================================================
# 显示帮助信息
#==============================================================================
show_help() {
    cat << EOF
YuxuanShell 设置脚本

用法: $0 [选项]

选项:
    setup       运行设置向导 (默认)
    config      仅创建用户配置
    deps        仅安装可选依赖
    dev         仅设置开发环境
    --help      显示此帮助信息

配置文件位置:
    用户配置: $USER_CONFIG
    主配置: $INSTALL_DIR/src/config/settings.sh
EOF
}

#==============================================================================
# 主函数
#==============================================================================
main() {
    case "${1:-setup}" in
        "setup")
            main_setup
            ;;
        "config")
            create_user_config
            ;;
        "deps")
            install_optional_dependencies
            ;;
        "dev")
            setup_development_environment
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