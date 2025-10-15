#!/bin/bash
#==============================================================================
# YuxuanShell 配置文件
#==============================================================================

# 调试模式
DEBUG=false

# 详细输出模式
VERBOSE=false

# 备份目录
BACKUP_DIR="$HOME/.yuxuan_shell/backups"

# 日志级别 (ERROR, WARN, INFO, DEBUG)
LOG_LEVEL="INFO"

# 临时目录
TEMP_DIR="/tmp/yuxuan_shell"

# 网络超时设置 (秒)
NETWORK_TIMEOUT=30

# 默认压缩格式
DEFAULT_COMPRESSION="tar.gz"

# 自动清理临时文件 (天数)
AUTO_CLEANUP_DAYS=7

# 系统监控刷新间隔 (秒)
MONITOR_INTERVAL=5

# 文件备份保留数量
MAX_BACKUPS=10

#==============================================================================
# 平台特定配置
#==============================================================================

# 根据操作系统设置不同的默认值
case "$(uname -s)" in
    Darwin*)
        # macOS 特定配置
        DEFAULT_EDITOR="nano"
        DEFAULT_BROWSER="open"
        PACKAGE_MANAGER="brew"
        ;;
    Linux*)
        # Linux 特定配置
        DEFAULT_EDITOR="nano"
        DEFAULT_BROWSER="xdg-open"
        if [[ -f /etc/debian_version ]]; then
            PACKAGE_MANAGER="apt"
        elif [[ -f /etc/redhat-release ]]; then
            PACKAGE_MANAGER="yum"
        else
            PACKAGE_MANAGER="unknown"
        fi
        ;;
    *)
        # 其他系统默认配置
        DEFAULT_EDITOR="vi"
        DEFAULT_BROWSER="unknown"
        PACKAGE_MANAGER="unknown"
        ;;
esac

#==============================================================================
# 创建必要的目录
#==============================================================================
create_required_directories() {
    local dirs=(
        "$BACKUP_DIR"
        "$TEMP_DIR"
        "$HOME/.yuxuan_shell/logs"
        "$HOME/.yuxuan_shell/cache"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" 2>/dev/null || true
        fi
    done
}

# 初始化目录
create_required_directories

#==============================================================================
# 环境变量设置
#==============================================================================

# 设置 PATH
if [[ ":$PATH:" != *":$HOME/.yuxuan_shell/bin:"* ]]; then
    export PATH="$HOME/.yuxuan_shell/bin:$PATH"
fi

# 设置临时目录
export TMPDIR="$TEMP_DIR"

#==============================================================================
# 用户自定义配置
#==============================================================================

# 如果存在用户配置文件，则加载它
USER_CONFIG="$HOME/.yuxuan_shell/user_config.sh"
if [[ -f "$USER_CONFIG" ]]; then
    source "$USER_CONFIG"
fi