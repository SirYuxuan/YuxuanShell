# YuxuanShell

<div align="center">

![YuxuanShell Logo](https://img.shields.io/badge/YuxuanShell-v1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)
![Shell](https://img.shields.io/badge/shell-bash-green.svg)
![License](https://img.shields.io/badge/license-MIT-orange.svg)

**通用Shell工具包 - 让命令行更高效**

[安装指南](#安装) • [使用文档](#使用) • [功能特性](#功能特性) • [贡献指南](#贡献)

</div>

## 概述

YuxuanShell 是一个功能强大、跨平台的Shell工具包，旨在简化日常的系统管理和网络诊断任务。它提供了统一的命令界面，支持 macOS 和 Debian/Ubuntu 系统。

### ✨ 主要特性

- 🔧 **模块化设计** - 清晰的模块划分，易于扩展和维护
- 🌍 **跨平台支持** - 完美兼容 macOS 和 Linux 系统
- 🚀 **功能丰富** - 覆盖系统监控、维护与网络诊断等常见场景
- 📊 **直观输出** - 彩色日志和进度显示
- 🔒 **安全可靠** - 内置错误处理和安全检查

## 功能特性

### 🖥️ 系统管理
- 系统信息显示
- 实时性能监控
- 系统清理和优化
- 进程和服务管理
- 内存和磁盘分析

### 🌐 网络工具
- 网络连接诊断
- IP地址查询
- 端口扫描和检测
- 端口占用进程查看与结束（list-port / kill-port）
- 网速测试
- DNS查询和解析

## 安装

### 一键安装（推荐）

将脚本安装到系统目录（默认前缀 /usr/local），并创建全局命令 `yuxuan-shell`：

```bash
curl -fsSL https://raw.githubusercontent.com/SirYuxuan/YuxuanShell/main/scripts/install.sh | sudo -E bash
```

自定义安装前缀（例如安装到 /opt/yuxuan）：

```bash
curl -fsSL https://raw.githubusercontent.com/SirYuxuan/YuxuanShell/main/scripts/install.sh | YS_PREFIX=/opt sudo -E bash
```

如果你的环境不方便联网，也可以克隆仓库后本地执行安装脚本：

```bash
git clone https://github.com/SirYuxuan/YuxuanShell.git
cd YuxuanShell
bash scripts/install.sh
```

### 依赖要求

**必需依赖：**
- bash (≥ 4.0)
- curl
- tar, find, grep, awk, sed

**可选依赖：**
- git (版本控制)
- nmap (网络扫描)
- speedtest-cli (网速测试)

## 使用

### 基本语法

```bash
yuxuan-shell [选项] <命令> [参数...]
```

### 常用命令示例

#### 系统管理
```bash
# 显示系统信息
yuxuan-shell system info

# 实时监控系统资源
yuxuan-shell system monitor

# 系统清理
yuxuan-shell system cleanup

# 管理服务
yuxuan-shell system service status nginx
yuxuan-shell system service restart apache2
```

#### 网络工具
```bash
# 网络连接测试
yuxuan-shell network ping google.com

# 显示网络信息
yuxuan-shell network info

# 端口检测
yuxuan-shell network port google.com 80

# 网速测试
yuxuan-shell network speed

# DNS查询
yuxuan-shell network dns example.com

# 查看端口占用的进程
yuxuan-shell network list-port 8080

# 结束占用端口的进程（含确认提示）
yuxuan-shell network kill-port 3000
```
### 高级功能

## 开发

### 项目结构

```
YuxuanShell/
├── src/                    # 源代码
│   ├── main.sh            # 主程序入口
│   ├── config/            # 配置文件
│   │   └── settings.sh    # 主配置文件
│   └── modules/           # 功能模块
│       ├── utils.sh       # 通用工具函数
│       ├── system.sh      # 系统管理模块
│       └── network.sh     # 网络工具模块
├── scripts/               # 脚本文件
│   └── install.sh         # 安装脚本（唯一入口）
├── docs/                  # 文档
└── README.md             # 项目说明
```

### 常用脚本

```bash
# 安装/修复安装（系统级）
sudo -E bash scripts/install.sh
```

### 添加新功能

1. **创建新模块**：在 `src/modules/` 目录下创建新的 `.sh` 文件
2. **实现功能**：按照现有模块的模式实现功能
3. **更新主程序**：在 `src/main.sh` 中添加新命令的处理逻辑

### 代码规范

- 使用 4 空格缩进
- 函数名使用下划线分隔
- 添加详细的注释和文档
- 遵循 Shell 脚本最佳实践
- 使用 `shellcheck` 进行代码检查

### 配置

### 配置文件位置

- **主配置（源码内）**：`src/config/settings.sh`

### 主要配置项

```bash
# 调试模式
DEBUG=false

# 详细输出
VERBOSE=false

# 备份目录
BACKUP_DIR="$HOME/.yuxuan_shell/backups"

# 日志级别
LOG_LEVEL="INFO"

# 网络超时
NETWORK_TIMEOUT=30

# 监控间隔
MONITOR_INTERVAL=5
```

## 故障排除

### 常见问题

**Q: 命令找不到**
```bash
# 检查PATH设置
echo $PATH

# 手动添加到PATH
export PATH="$HOME/.yuxuan_shell/bin:$PATH"
```

**Q: 权限错误**
```bash
# 修复权限
chmod +x ~/.yuxuan_shell/bin/yuxuan-shell
```

**Q: 模块加载失败**
```bash
# 重新安装（以修复缺失文件）
sudo -E bash scripts/install.sh
```

### 调试模式

```bash
# 启用调试模式
yuxuan-shell --debug system info

# 查看详细日志
yuxuan-shell --verbose network scan
```

## 贡献

我们欢迎所有形式的贡献！

### 如何贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 贡献指南

- 遵循现有的代码风格
- 添加适当的测试
- 更新相关文档
- 确保所有测试通过

### Bug 报告

请使用 [GitHub Issues](https://github.com/SirYuxuan/YuxuanShell/issues) 报告 bug，包含以下信息：

- 操作系统版本
- Shell 版本
- 错误描述和重现步骤
- 相关日志输出

## 许可证

本项目基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 致谢

感谢所有贡献者和用户的支持！

## 联系方式

- **作者**：Yuxuan
- **GitHub**：[@SirYuxuan](https://github.com/SirYuxuan)
- **Issues**：[GitHub Issues](https://github.com/SirYuxuan/YuxuanShell/issues)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个星标！⭐**

Made with ❤️ by Yuxuan

</div>