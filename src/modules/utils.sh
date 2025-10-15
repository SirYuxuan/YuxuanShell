#!/bin/bash
#==============================================================================
# Utils Module - 通用工具函数
#==============================================================================

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly NC='\033[0m' # No Color

# 日志级别
readonly LOG_ERROR=1
readonly LOG_WARN=2
readonly LOG_INFO=3
readonly LOG_DEBUG=4

#==============================================================================
# 操作系统检测
#==============================================================================
get_os_type() {
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
        CYGWIN*)    echo "cygwin" ;;
        MINGW*)     echo "mingw" ;;
        *)          echo "unknown" ;;
    esac
}

get_os_version() {
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            sw_vers -productVersion
            ;;
        "debian")
            cat /etc/debian_version
            ;;
        "redhat")
            cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+'
            ;;
        *)
            uname -r
            ;;
    esac
}

#==============================================================================
# 日志函数
#==============================================================================
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} [$timestamp] $message" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} [$timestamp] $message" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} [$timestamp] $message"
            ;;
        "DEBUG")
            if [[ "${DEBUG:-false}" == "true" ]]; then
                echo -e "${BLUE}[DEBUG]${NC} [$timestamp] $message"
            fi
            ;;
        *)
            echo -e "${WHITE}[$level]${NC} [$timestamp] $message"
            ;;
    esac
}

log_error() {
    log "ERROR" "$1"
}

log_warn() {
    log "WARN" "$1"
}

log_info() {
    log "INFO" "$1"
}

log_debug() {
    log "DEBUG" "$1"
}

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
# 进度条显示
#==============================================================================
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    local bar_length=50
    local progress=$((current * bar_length / total))
    local percentage=$((current * 100 / total))
    
    printf "\r${message}: ["
    for ((i=0; i<bar_length; i++)); do
        if [[ $i -lt $progress ]]; then
            printf "█"
        else
            printf "░"
        fi
    done
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

#==============================================================================
# 命令执行函数
#==============================================================================
run_command() {
    local cmd="$1"
    local description="${2:-Running command}"
    
    log_info "$description: $cmd"
    
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        eval "$cmd"
    else
        eval "$cmd" > /dev/null 2>&1
    fi
    
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "命令执行失败: $cmd (退出代码: $exit_code)"
        return $exit_code
    fi
    
    log_debug "命令执行成功: $cmd"
    return 0
}

#==============================================================================
# 文件和目录检查
#==============================================================================
check_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "文件不存在: $file"
        return 1
    fi
    return 0
}

check_dir_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_error "目录不存在: $dir"
        return 1
    fi
    return 0
}

create_dir_if_not_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_info "创建目录: $dir"
        mkdir -p "$dir"
    fi
}

#==============================================================================
# 字符串处理函数
#==============================================================================
trim() {
    local var="$1"
    # 移除前导空格
    var="${var#"${var%%[![:space:]]*}"}"
    # 移除尾随空格
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

#==============================================================================
# 数组处理函数
#==============================================================================
array_contains() {
    local element="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

array_join() {
    local IFS="$1"
    shift
    echo "$*"
}

#==============================================================================
# 时间处理函数
#==============================================================================
get_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

get_iso_timestamp() {
    date -Iseconds
}

#==============================================================================
# 临时文件管理
#==============================================================================
create_temp_file() {
    local prefix="${1:-yuxuan_shell}"
    mktemp "/tmp/${prefix}.XXXXXX"
}

create_temp_dir() {
    local prefix="${1:-yuxuan_shell}"
    mktemp -d "/tmp/${prefix}.XXXXXX"
}

cleanup_temp_files() {
    local pattern="${1:-yuxuan_shell.*}"
    find /tmp -name "$pattern" -type f -mtime +1 -delete 2>/dev/null || true
    find /tmp -name "$pattern" -type d -empty -mtime +1 -delete 2>/dev/null || true
}

#==============================================================================
# 网络检查
#==============================================================================
check_internet() {
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 5 "$host" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

#==============================================================================
# 包管理器检测
#==============================================================================
get_package_manager() {
    local os_type
    os_type=$(get_os_type)
    
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