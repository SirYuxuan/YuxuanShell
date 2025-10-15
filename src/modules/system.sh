#!/bin/bash
#==============================================================================
# System Module - 系统相关操作
#==============================================================================

#==============================================================================
# 系统命令处理
#==============================================================================
handle_system_command() {
    if [[ $# -eq 0 ]]; then
        show_system_help
        return 0
    fi
    
    local cmd="$1"
    shift
    
    case "$cmd" in
        "info")
            show_system_info "$@"
            ;;
        "monitor")
            monitor_system "$@"
            ;;
        "cleanup")
            cleanup_system "$@"
            ;;
        "update")
            update_system "$@"
            ;;
        "service")
            manage_service "$@"
            ;;
        "process")
            manage_process "$@"
            ;;
        "disk")
            manage_disk "$@"
            ;;
        "memory")
            check_memory "$@"
            ;;
        "help")
            show_system_help
            ;;
        *)
            log_error "未知系统命令: $cmd"
            show_system_help
            return 1
            ;;
    esac
}

#==============================================================================
# 系统帮助信息
#==============================================================================
show_system_help() {
    cat << EOF
系统管理命令:

用法: $(basename "$0") system <命令> [选项]

命令:
    info                显示系统信息
    monitor [interval]  监控系统资源 (默认间隔5秒)
    cleanup             清理系统垃圾文件
    update              更新系统包
    service <action> <name>  管理系统服务
    process <action> [name]  管理进程
    disk                显示磁盘使用情况
    memory              显示内存使用情况

示例:
    $(basename "$0") system info
    $(basename "$0") system monitor 3
    $(basename "$0") system service status nginx
    $(basename "$0") system process kill firefox
EOF
}

#==============================================================================
# 系统信息显示
#==============================================================================
show_system_info() {
    local os_type
    os_type=$(get_os_type)
    
    echo -e "${BLUE}==================== 系统信息 ====================${NC}"
    echo -e "${GREEN}操作系统:${NC} $os_type ($(get_os_version))"
    echo -e "${GREEN}主机名:${NC} $(hostname)"
    echo -e "${GREEN}内核:${NC} $(uname -r)"
    echo -e "${GREEN}架构:${NC} $(uname -m)"
    echo -e "${GREEN}CPU:${NC} $(get_cpu_info)"
    echo -e "${GREEN}内存:${NC} $(get_memory_info)"
    echo -e "${GREEN}磁盘:${NC}"
    get_disk_info | sed 's/^/  /'
    echo -e "${GREEN}网络:${NC}"
    get_network_info | sed 's/^/  /'
    echo -e "${GREEN}系统时间:${NC} $(date)"
    echo -e "${GREEN}运行时间:${NC} $(get_uptime)"
    echo -e "${BLUE}================================================${NC}"
}

get_cpu_info() {
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            sysctl -n machdep.cpu.brand_string
            ;;
        "debian"|"linux")
            grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | trim
            ;;
        *)
            echo "未知"
            ;;
    esac
}

get_memory_info() {
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            local total_mb
            total_mb=$(($(sysctl -n hw.memsize) / 1024 / 1024))
            echo "${total_mb}MB"
            ;;
        "debian"|"linux")
            grep "MemTotal" /proc/meminfo | awk '{print $2 " KB"}'
            ;;
        *)
            echo "未知"
            ;;
    esac
}

get_disk_info() {
    df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{print $5 " " $1 " (" $3 "/" $2 ")"}'
}

get_network_info() {
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
            ;;
        "debian"|"linux")
            ip addr | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1
            ;;
    esac
}

get_uptime() {
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            uptime | awk -F'up ' '{print $2}' | awk -F', [0-9]* user' '{print $1}'
            ;;
        "debian"|"linux")
            uptime -p
            ;;
        *)
            uptime
            ;;
    esac
}

#==============================================================================
# 系统监控
#==============================================================================
monitor_system() {
    local interval="${1:-5}"
    
    log_info "开始监控系统资源，间隔: ${interval}秒 (按Ctrl+C退出)"
    
    while true; do
        clear
        echo -e "${BLUE}==================== 系统监控 ====================${NC}"
        echo -e "${GREEN}时间:${NC} $(date)"
        echo
        
        # CPU使用率
        echo -e "${YELLOW}CPU 使用率:${NC}"
        get_cpu_usage
        echo
        
        # 内存使用率
        echo -e "${YELLOW}内存使用:${NC}"
        get_memory_usage
        echo
        
        # 磁盘使用率
        echo -e "${YELLOW}磁盘使用:${NC}"
        df -h | head -5
        echo
        
        # 网络连接
        echo -e "${YELLOW}网络连接:${NC}"
        get_network_connections | head -5
        echo
        
        # 负载平均值
        echo -e "${YELLOW}系统负载:${NC}"
        get_load_average
        
        echo -e "${BLUE}================================================${NC}"
        
        sleep "$interval"
    done
}

get_cpu_usage() {
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            top -l 1 | grep "CPU usage" | awk '{print $3, $5}'
            ;;
        "debian"|"linux")
            top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
            ;;
    esac
}

get_memory_usage() {
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+):\s+(\d+)/ and printf("%-16s % 16.2f Mi\n", "$1:", $2 * $size / 1048576);'
            ;;
        "debian"|"linux")
            free -h
            ;;
    esac
}

get_network_connections() {
    netstat -an | grep ESTABLISHED
}

get_load_average() {
    uptime | awk -F'load average:' '{print $2}'
}

#==============================================================================
# 系统清理
#==============================================================================
cleanup_system() {
    local os_type
    os_type=$(get_os_type)
    
    if ! ask_confirmation "确定要清理系统垃圾文件吗？"; then
        log_info "取消清理操作"
        return 0
    fi
    
    log_info "开始清理系统..."
    
    case "$os_type" in
        "macos")
            cleanup_macos
            ;;
        "debian"|"linux")
            cleanup_debian
            ;;
        *)
            log_warn "当前系统不支持自动清理"
            ;;
    esac
    
    # 清理临时文件
    cleanup_temp_files
    
    log_info "系统清理完成"
}

cleanup_macos() {
    log_info "清理macOS系统文件..."
    
    # 清理缓存
    [[ -d ~/Library/Caches ]] && find ~/Library/Caches -type f -mtime +7 -delete 2>/dev/null
    
    # 清理下载目录中的旧文件
    [[ -d ~/Downloads ]] && find ~/Downloads -type f -mtime +30 -delete 2>/dev/null
    
    # 清理垃圾桶
    osascript -e 'tell application "Finder" to empty trash' 2>/dev/null || true
}

cleanup_debian() {
    log_info "清理Debian/Ubuntu系统文件..."
    
    local pkg_manager
    pkg_manager=$(get_package_manager)
    
    case "$pkg_manager" in
        "apt"|"apt-get")
            sudo apt autoremove -y
            sudo apt autoclean
            ;;
    esac
    
    # 清理日志文件
    sudo journalctl --vacuum-time=7d 2>/dev/null || true
    
    # 清理包缓存
    [[ -d /var/cache/apt/archives ]] && sudo find /var/cache/apt/archives -type f -name "*.deb" -mtime +7 -delete 2>/dev/null
}

#==============================================================================
# 系统更新
#==============================================================================
update_system() {
    local os_type
    os_type=$(get_os_type)
    local pkg_manager
    pkg_manager=$(get_package_manager)
    
    if ! ask_confirmation "确定要更新系统包吗？"; then
        log_info "取消更新操作"
        return 0
    fi
    
    log_info "开始更新系统..."
    
    case "$pkg_manager" in
        "brew")
            brew update && brew upgrade
            ;;
        "apt")
            sudo apt update && sudo apt upgrade -y
            ;;
        "apt-get")
            sudo apt-get update && sudo apt-get upgrade -y
            ;;
        "dnf")
            sudo dnf update -y
            ;;
        "yum")
            sudo yum update -y
            ;;
        *)
            log_warn "未检测到支持的包管理器"
            return 1
            ;;
    esac
    
    log_info "系统更新完成"
}

#==============================================================================
# 服务管理
#==============================================================================
manage_service() {
    local action="$1"
    local service_name="$2"
    
    if [[ -z "$action" || -z "$service_name" ]]; then
        log_error "用法: service <action> <service_name>"
        log_info "Actions: start, stop, restart, status, enable, disable"
        return 1
    fi
    
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            manage_macos_service "$action" "$service_name"
            ;;
        "debian"|"linux")
            manage_linux_service "$action" "$service_name"
            ;;
        *)
            log_error "当前系统不支持服务管理"
            return 1
            ;;
    esac
}

manage_macos_service() {
    local action="$1"
    local service_name="$2"
    
    case "$action" in
        "start")
            brew services start "$service_name"
            ;;
        "stop")
            brew services stop "$service_name"
            ;;
        "restart")
            brew services restart "$service_name"
            ;;
        "status")
            brew services list | grep "$service_name"
            ;;
        *)
            log_error "macOS不支持的操作: $action"
            ;;
    esac
}

manage_linux_service() {
    local action="$1"
    local service_name="$2"
    
    case "$action" in
        "start"|"stop"|"restart"|"status"|"enable"|"disable")
            sudo systemctl "$action" "$service_name"
            ;;
        *)
            log_error "不支持的操作: $action"
            ;;
    esac
}

#==============================================================================
# 进程管理
#==============================================================================
manage_process() {
    local action="$1"
    local process_name="$2"
    
    if [[ -z "$action" ]]; then
        log_error "用法: process <action> [process_name]"
        log_info "Actions: list, kill, killall"
        return 1
    fi
    
    case "$action" in
        "list")
            if [[ -n "$process_name" ]]; then
                ps aux | grep "$process_name" | grep -v grep
            else
                ps aux | head -20
            fi
            ;;
        "kill")
            if [[ -z "$process_name" ]]; then
                log_error "需要指定进程名"
                return 1
            fi
            killall "$process_name"
            log_info "已终止进程: $process_name"
            ;;
        "killall")
            if [[ -z "$process_name" ]]; then
                log_error "需要指定进程名"
                return 1
            fi
            if ask_confirmation "确定要终止所有 $process_name 进程吗？"; then
                killall -9 "$process_name"
                log_info "已强制终止所有 $process_name 进程"
            fi
            ;;
        *)
            log_error "不支持的操作: $action"
            ;;
    esac
}

#==============================================================================
# 磁盘管理
#==============================================================================
manage_disk() {
    echo -e "${BLUE}==================== 磁盘使用情况 ====================${NC}"
    df -h | head -1
    df -h | grep -vE '^Filesystem|tmpfs|cdrom'
    echo
    
    echo -e "${BLUE}==================== 大文件查找 ====================${NC}"
    echo "查找大于100MB的文件..."
    find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10
}

#==============================================================================
# 内存检查
#==============================================================================
check_memory() {
    local os_type
    os_type=$(get_os_type)
    
    echo -e "${BLUE}==================== 内存使用情况 ====================${NC}"
    
    case "$os_type" in
        "macos")
            echo -e "${GREEN}系统内存:${NC}"
            vm_stat | head -10
            echo
            echo -e "${GREEN}内存占用最高进程:${NC}"
            ps aux --sort=-%mem | head -10
            ;;
        "debian"|"linux")
            echo -e "${GREEN}系统内存:${NC}"
            free -h
            echo
            echo -e "${GREEN}内存占用最高进程:${NC}"
            ps aux --sort=-%mem | head -10
            ;;
    esac
}