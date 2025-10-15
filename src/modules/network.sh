#!/bin/bash
#==============================================================================
# Network Module - 网络相关操作
#==============================================================================

#==============================================================================
# 网络命令处理
#==============================================================================
handle_network_command() {
    if [[ $# -eq 0 ]]; then
        show_network_help
        return 0
    fi
    
    local cmd="$1"
    shift
    
    case "$cmd" in
        "ping")
            network_ping "$@"
            ;;
        "scan")
            network_scan "$@"
            ;;
        "port")
            check_port "$@"
            ;;
        "speed")
            test_speed "$@"
            ;;
        "info")
            show_network_info "$@"
            ;;
        "dns")
            check_dns "$@"
            ;;
        "traceroute")
            network_traceroute "$@"
            ;;
        "monitor")
            monitor_network "$@"
            ;;
        "kill-port")
            kill_port_process "$@"
            ;;
        "list-port")
            list_port_processes "$@"
            ;;
        "help")
            show_network_help
            ;;
        *)
            log_error "未知网络命令: $cmd"
            show_network_help
            return 1
            ;;
    esac
}

#==============================================================================
# 网络帮助信息
#==============================================================================
show_network_help() {
    cat << EOF
网络管理命令:

用法: $(basename "$0") network <命令> [选项]

命令:
    ping <host>              ping 测试
    scan <network>           网络扫描
    port <host> <port>       端口检查
    speed                    网速测试
    info                     显示网络信息
    dns <domain>             DNS查询
    traceroute <host>        路由跟踪
    monitor [interface]      网络监控
    kill-port <port>         结束占用指定端口的进程
    list-port <port>         查看占用指定端口的进程

示例:
    $(basename "$0") network ping google.com
    $(basename "$0") network scan 192.168.1.0/24
    $(basename "$0") network port google.com 80
    $(basename "$0") network dns example.com
    $(basename "$0") network list-port 8080
    $(basename "$0") network kill-port 8080
EOF
}

#==============================================================================
# Ping测试
#==============================================================================
network_ping() {
    local host="$1"
    local count="${2:-4}"
    
    if [[ -z "$host" ]]; then
        log_error "用法: ping <host> [count]"
        return 1
    fi
    
    log_info "正在 ping $host (${count}次)..."
    
    if ping -c "$count" "$host"; then
        log_info "ping 测试成功"
        return 0
    else
        log_error "ping 测试失败"
        return 1
    fi
}

#==============================================================================
# 网络扫描
#==============================================================================
network_scan() {
    local network="$1"
    
    if [[ -z "$network" ]]; then
        # 自动检测本地网络
        local os_type
        os_type=$(get_os_type)
        
        case "$os_type" in
            "macos")
                network=$(route -n get default | grep gateway | awk '{print $2}' | sed 's/\.[0-9]*$/\.0\/24/')
                ;;
            "debian"|"linux")
                network=$(ip route | grep default | awk '{print $3}' | sed 's/\.[0-9]*$/\.0\/24/')
                ;;
        esac
        
        if [[ -z "$network" ]]; then
            log_error "无法自动检测网络，请手动指定: scan <network>"
            log_info "示例: scan 192.168.1.0/24"
            return 1
        fi
    fi
    
    log_info "扫描网络: $network"
    
    if command -v nmap >/dev/null 2>&1; then
        nmap -sn "$network"
    else
        log_warn "未安装nmap，使用简单ping扫描"
        simple_network_scan "$network"
    fi
}

simple_network_scan() {
    local network="$1"
    local base_ip
    base_ip=$(echo "$network" | cut -d'/' -f1 | cut -d'.' -f1-3)
    
    echo -e "${GREEN}活动主机:${NC}"
    for i in {1..254}; do
        local ip="${base_ip}.$i"
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            echo "  $ip"
        fi
    done
}

#==============================================================================
# 端口检查
#==============================================================================
check_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-5}"
    
    if [[ -z "$host" || -z "$port" ]]; then
        log_error "用法: port <host> <port> [timeout]"
        return 1
    fi
    
    log_info "检查 ${host}:${port} (超时: ${timeout}秒)"
    
    if timeout "$timeout" bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        log_info "端口 ${host}:${port} 开放"
        return 0
    else
        log_warn "端口 ${host}:${port} 关闭或不可达"
        return 1
    fi
}

#==============================================================================
# 网速测试
#==============================================================================
test_speed() {
    log_info "开始网速测试..."
    
    if command -v speedtest-cli >/dev/null 2>&1; then
        speedtest-cli
    elif command -v curl >/dev/null 2>&1; then
        log_info "使用curl进行简单下载测试..."
        local test_url="http://speedtest.wdc01.softlayer.com/downloads/test10.zip"
        curl -o /dev/null -s -w "下载速度: %{speed_download} 字节/秒\n平均速度: %{size_download}字节 in %{time_total}秒\n" "$test_url"
    else
        log_error "未找到网速测试工具，请安装 speedtest-cli"
        log_info "安装命令: pip install speedtest-cli"
        return 1
    fi
}

#==============================================================================
# 网络信息显示
#==============================================================================
show_network_info() {
    local os_type
    os_type=$(get_os_type)
    
    echo -e "${BLUE}==================== 网络信息 ====================${NC}"
    
    # 网络接口
    echo -e "${GREEN}网络接口:${NC}"
    case "$os_type" in
        "macos")
            ifconfig | grep -E "^[a-z]|inet "
            ;;
        "debian"|"linux")
            ip addr show
            ;;
    esac
    
    echo
    
    # 路由表
    echo -e "${GREEN}路由信息:${NC}"
    case "$os_type" in
        "macos")
            route -n get default
            ;;
        "debian"|"linux")
            ip route
            ;;
    esac
    
    echo
    
    # DNS设置
    echo -e "${GREEN}DNS设置:${NC}"
    if [[ -f /etc/resolv.conf ]]; then
        grep nameserver /etc/resolv.conf
    fi
    
    echo
    
    # 网络连接
    echo -e "${GREEN}活动连接:${NC}"
    netstat -an | grep ESTABLISHED | head -10
    
    echo
    
    # 公网IP
    echo -e "${GREEN}公网IP:${NC}"
    get_public_ip
}

get_public_ip() {
    local services=("ifconfig.me" "ipecho.net/plain" "icanhazip.com")
    
    for service in "${services[@]}"; do
        local ip
        ip=$(curl -s --connect-timeout 5 "$service" 2>/dev/null)
        if [[ -n "$ip" && "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    log_warn "无法获取公网IP"
}

#==============================================================================
# DNS查询
#==============================================================================
check_dns() {
    local domain="$1"
    local record_type="${2:-A}"
    
    if [[ -z "$domain" ]]; then
        log_error "用法: dns <domain> [record_type]"
        log_info "记录类型: A, AAAA, MX, NS, TXT, CNAME"
        return 1
    fi
    
    log_info "查询 $domain 的 $record_type 记录"
    
    if command -v dig >/dev/null 2>&1; then
        dig "$domain" "$record_type" +short
    elif command -v nslookup >/dev/null 2>&1; then
        nslookup -type="$record_type" "$domain"
    else
        log_error "未找到DNS查询工具 (dig 或 nslookup)"
        return 1
    fi
}

#==============================================================================
# 路由跟踪
#==============================================================================
network_traceroute() {
    local host="$1"
    local max_hops="${2:-30}"
    
    if [[ -z "$host" ]]; then
        log_error "用法: traceroute <host> [max_hops]"
        return 1
    fi
    
    log_info "跟踪到 $host 的路由 (最大跳数: $max_hops)"
    
    if command -v traceroute >/dev/null 2>&1; then
        traceroute -m "$max_hops" "$host"
    elif command -v tracert >/dev/null 2>&1; then
        tracert -h "$max_hops" "$host"
    else
        log_error "未找到路由跟踪工具"
        return 1
    fi
}

#==============================================================================
# 网络监控
#==============================================================================
monitor_network() {
    local interface="${1:-}"
    local interval="${2:-5}"
    
    if [[ -z "$interface" ]]; then
        interface=$(get_default_interface)
    fi
    
    if [[ -z "$interface" ]]; then
        log_error "无法确定网络接口"
        return 1
    fi
    
    log_info "监控网络接口: $interface (间隔: ${interval}秒，按Ctrl+C退出)"
    
    local prev_rx=0
    local prev_tx=0
    local prev_time
    prev_time=$(date +%s)
    
    while true; do
        local stats
        stats=$(get_interface_stats "$interface")
        
        if [[ -n "$stats" ]]; then
            local rx tx
            rx=$(echo "$stats" | awk '{print $1}')
            tx=$(echo "$stats" | awk '{print $2}')
            local current_time
            current_time=$(date +%s)
            
            if [[ $prev_rx -ne 0 ]]; then
                local time_diff=$((current_time - prev_time))
                local rx_speed=$(((rx - prev_rx) / time_diff))
                local tx_speed=$(((tx - prev_tx) / time_diff))
                
                clear
                echo -e "${BLUE}==================== 网络监控 ====================${NC}"
                echo -e "${GREEN}接口:${NC} $interface"
                echo -e "${GREEN}时间:${NC} $(date)"
                echo
                echo -e "${GREEN}接收速度:${NC} $(format_bytes $rx_speed)/s"
                echo -e "${GREEN}发送速度:${NC} $(format_bytes $tx_speed)/s"
                echo
                echo -e "${GREEN}总接收:${NC} $(format_bytes $rx)"
                echo -e "${GREEN}总发送:${NC} $(format_bytes $tx)"
                echo -e "${BLUE}================================================${NC}"
            fi
            
            prev_rx=$rx
            prev_tx=$tx
            prev_time=$current_time
        fi
        
        sleep "$interval"
    done
}

get_default_interface() {
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            route -n get default 2>/dev/null | grep interface | awk '{print $2}'
            ;;
        "debian"|"linux")
            ip route | grep default | awk '{print $5}' | head -1
            ;;
    esac
}

get_interface_stats() {
    local interface="$1"
    local os_type
    os_type=$(get_os_type)
    
    case "$os_type" in
        "macos")
            netstat -ibn | grep "$interface" | awk '{print $7, $10}' | head -1
            ;;
        "debian"|"linux")
            if [[ -f "/sys/class/net/$interface/statistics/rx_bytes" ]]; then
                local rx
                local tx
                rx=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
                tx=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
                echo "$rx $tx"
            fi
            ;;
    esac
}

format_bytes() {
    local bytes="$1"
    
    if [[ $bytes -gt 1073741824 ]]; then
        echo "$(( bytes / 1073741824 )) GB"
    elif [[ $bytes -gt 1048576 ]]; then
        echo "$(( bytes / 1048576 )) MB"
    elif [[ $bytes -gt 1024 ]]; then
        echo "$(( bytes / 1024 )) KB"
    else
        echo "$bytes B"
    fi
}

#==============================================================================
# 结束占用端口的进程
#==============================================================================
kill_port_process() {
    local port="$1"
    
    if [[ -z "$port" ]]; then
        log_error "用法: kill-port <port>"
        log_info "示例: kill-port 8080"
        return 1
    fi
    
    # 验证端口号
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        log_error "无效的端口号: $port (有效范围: 1-65535)"
        return 1
    fi
    
    log_info "检查端口 $port 的占用情况..."
    
    local processes
    local os_type
    os_type=$(get_os_type)
    
    # 根据操作系统使用不同的命令查找进程
    case "$os_type" in
        "macos")
            processes=$(lsof -ti :$port 2>/dev/null || true)
            ;;
        "debian"|"linux")
            processes=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' || true)
            if [[ -z "$processes" ]]; then
                # 尝试使用 ss 命令
                processes=$(ss -tlnp 2>/dev/null | grep ":$port " | grep -o 'pid=[0-9]*' | cut -d'=' -f2 || true)
            fi
            if [[ -z "$processes" ]]; then
                # 尝试使用 fuser 命令
                processes=$(fuser $port/tcp 2>/dev/null || true)
            fi
            ;;
        *)
            log_error "当前操作系统不支持端口进程查询"
            return 1
            ;;
    esac
    
    if [[ -z "$processes" ]]; then
        log_info "端口 $port 未被任何进程占用"
        return 0
    fi
    
    # 显示占用端口的进程信息
    echo -e "${BLUE}==================== 端口 $port 占用情况 ====================${NC}"
    echo -e "${GREEN}进程ID(PID)  进程名称                命令行${NC}"
    echo -e "${BLUE}================================================${NC}"
    
    local pids=()
    for pid in $processes; do
        # 清理PID（移除可能的额外字符）
        pid=$(echo "$pid" | grep -o '^[0-9]*' || true)
        if [[ -n "$pid" ]] && [[ "$pid" =~ ^[0-9]+$ ]]; then
            pids+=("$pid")
            
            # 获取进程详细信息
            local process_info
            if ps -p "$pid" >/dev/null 2>&1; then
                case "$os_type" in
                    "macos")
                        process_info=$(ps -p "$pid" -o pid,comm,args | tail -n +2)
                        ;;
                    "debian"|"linux")
                        process_info=$(ps -p "$pid" -o pid,comm,args --no-headers)
                        ;;
                esac
                
                if [[ -n "$process_info" ]]; then
                    echo "$process_info"
                else
                    echo "$pid          未知进程"
                fi
            else
                log_warn "进程 $pid 可能已经结束"
            fi
        fi
    done
    
    echo -e "${BLUE}================================================${NC}"
    
    if [[ ${#pids[@]} -eq 0 ]]; then
        log_warn "没有找到有效的进程ID"
        return 0
    fi
    
    # 询问用户是否要结束进程
    echo
    if ask_confirmation "发现 ${#pids[@]} 个进程占用端口 ${port}，是否要结束这些进程？" "n"; then
        local killed_count=0
        local failed_count=0
        
        for pid in "${pids[@]}"; do
            log_info "正在结束进程 $pid..."
            
            # 首先尝试优雅地结束进程（SIGTERM）
            if kill "$pid" 2>/dev/null; then
                sleep 2
                
                # 检查进程是否还在运行
                if ps -p "$pid" >/dev/null 2>&1; then
                    log_warn "进程 $pid 仍在运行，强制结束..."
                    if kill -9 "$pid" 2>/dev/null; then
                        killed_count=$((killed_count + 1))
                        log_info "进程 $pid 已被强制结束"
                    else
                        failed_count=$((failed_count + 1))
                        log_error "无法结束进程 $pid（可能权限不足）"
                    fi
                else
                    killed_count=$((killed_count + 1))
                    log_info "进程 $pid 已优雅结束"
                fi
            else
                failed_count=$((failed_count + 1))
                log_error "无法结束进程 $pid（可能权限不足或进程已结束）"
            fi
        done
        
        echo
    echo -e "${GREEN}结果统计:${NC}"
    echo -e "  成功结束: ${killed_count} 个进程"
        if [[ $failed_count -gt 0 ]]; then
            echo -e "  ${RED}失败: ${failed_count} 个进程${NC}"
            log_warn "某些进程可能需要管理员权限才能结束"
        fi
        
        # 再次检查端口状态
        sleep 1
    log_info "重新检查端口 ${port} 状态..."
        
        case "$os_type" in
            "macos")
                local remaining
                remaining=$(lsof -ti :${port} 2>/dev/null || true)
                ;;
            "debian"|"linux")
                local remaining
                remaining=$(netstat -tlnp 2>/dev/null | grep ":${port} " || true)
                ;;
        esac
        
        if [[ -z "$remaining" ]]; then
            log_info "✓ 端口 ${port} 现在空闲"
        else
            log_warn "⚠ 端口 ${port} 仍被占用，可能有其他进程或需要更高权限"
        fi
    else
        log_info "用户取消操作，保持进程运行"
    fi
}

#==============================================================================
# 获取端口占用进程列表（不结束进程）
#==============================================================================
list_port_processes() {
    local port="$1"
    
    if [[ -z "$port" ]]; then
        log_error "用法: list-port <port>"
        return 1
    fi
    
    # 验证端口号
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        log_error "无效的端口号: $port"
        return 1
    fi
    
    local os_type
    os_type=$(get_os_type)
    
    log_info "查询端口 $port 的占用情况..."
    
    case "$os_type" in
        "macos")
            if command -v lsof >/dev/null 2>&1; then
                echo -e "${GREEN}端口 $port 占用详情:${NC}"
                lsof -i :$port 2>/dev/null || log_info "端口 $port 未被占用"
            else
                log_error "需要 lsof 命令来查询端口占用"
                return 1
            fi
            ;;
        "debian"|"linux")
            if command -v netstat >/dev/null 2>&1; then
                echo -e "${GREEN}端口 $port 占用详情 (netstat):${NC}"
                netstat -tlnp 2>/dev/null | head -1
                netstat -tlnp 2>/dev/null | grep ":$port " || log_info "端口 $port 未被占用"
            elif command -v ss >/dev/null 2>&1; then
                echo -e "${GREEN}端口 $port 占用详情 (ss):${NC}"
                ss -tlnp | head -1
                ss -tlnp | grep ":$port " || log_info "端口 $port 未被占用"
            else
                log_error "需要 netstat 或 ss 命令来查询端口占用"
                return 1
            fi
            ;;
        *)
            log_error "当前操作系统不支持端口查询"
            return 1
            ;;
    esac
}