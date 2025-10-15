#!/bin/bash
#==============================================================================
# YuxuanShell - 通用Shell工具包
# 作者: Yuxuan
# 描述: 跨平台Shell工具，支持macOS和Debian系统
#==============================================================================

# 设置严格模式
set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# 导入配置
source "$SCRIPT_DIR/config/settings.sh"

# 导入工具模块
source "$SCRIPT_DIR/modules/utils.sh"
source "$SCRIPT_DIR/modules/system.sh"
source "$SCRIPT_DIR/modules/network.sh"

# 版本信息
VERSION="1.0.0"
AUTHOR="Yuxuan"

#==============================================================================
# 帮助信息
#==============================================================================
show_help() {
    cat << EOF
YuxuanShell v${VERSION} - 通用Shell工具包

用法:
    $(basename "$0") [选项] [命令] [参数...]

命令:
    system          系统相关操作
    network         网络相关操作

选项:
    -h, --help      显示此帮助信息
    -v, --version   显示版本信息
    -d, --debug     启用调试模式
    --verbose       详细输出模式

示例:
    $(basename "$0") system info
    $(basename "$0") network ping google.com
    $(basename "$0") --help

更多信息请参考: $BASE_DIR/docs/usage.md
EOF
}

#==============================================================================
# 版本信息
#==============================================================================
show_version() {
    echo "YuxuanShell v${VERSION}"
    echo "作者: ${AUTHOR}"
    echo "平台: $(get_os_type)"
}

#==============================================================================
# 主要命令处理
#==============================================================================
handle_command() {
    local cmd="$1"
    shift

    case "$cmd" in
        "system")
            handle_system_command "$@"
            ;;
        "network")
            handle_network_command "$@"
            ;;
        *)
            log_error "未知命令: $cmd"
            show_help
            exit 1
            ;;
    esac
}

#==============================================================================
# 主函数
#==============================================================================
main() {
    # 检查参数
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    # 处理选项
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
                set -x
                DEBUG=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                # 开始处理命令
                handle_command "$@"
                exit 0
                ;;
        esac
    done
}

# 运行主函数
main "$@"