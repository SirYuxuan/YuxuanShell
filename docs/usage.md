# YuxuanShell 使用手册

提示：文档中的命令使用默认全局命令名 `easy`。如果你在安装时通过 `YS_CMD` 指定了其他名称（或使用兼容命令 `yuxuan-shell`/`easy.sh`），请将以下示例中的 `easy` 替换为你的命令名。
### 网络监控

```bash
# 监控默认网络接口
easy network monitor

# 监控指定接口
easy network monitor eth0

# 自定义监控间隔
easy network monitor eth0 3
```
# 停止服务
easy system service stop <服务名>

# 重启服务
easy system service restart <服务名>

# 启用服务（开机自启）
easy system service enable <服务名>

# 禁用服务
easy system service disable <服务名>
```

示例：
```bash
# nginx 服务管理
easy system service status nginx
easy system service restart nginx

# SSH 服务管理
easy system service status ssh
easy system service start ssh
```

### 进程管理

```bash
# 列出所有进程（前20个）
easy system process list

# 查找特定进程
easy system process list firefox

# 终止进程
easy system process kill <进程名>

# 强制终止所有同名进程
easy system process killall <进程名>
```

## 网络工具

### 连接测试

```bash
# ping 测试（默认4次）
easy network ping google.com

# 自定义ping次数
easy network ping google.com 10
```

### 网络信息

```bash
# 显示网络配置信息
easy network info
```

显示内容：
- 网络接口信息
- IP地址（内网和公网）
- 路由信息
- DNS设置
- 活动网络连接

### 端口检测

```bash
# 检测端口是否开放
easy network port google.com 80
easy network port localhost 22

# 自定义超时时间（默认5秒）
easy network port example.com 443 10
```

### 网络扫描

```bash
# 扫描本地网络
easy network scan

# 扫描指定网段
easy network scan 192.168.1.0/24
```

### DNS查询

```bash
# 查询A记录
easy network dns example.com

# 查询特定记录类型
easy network dns example.com MX
easy network dns example.com NS
easy network dns example.com TXT
```

### 路由跟踪

```bash
# 跟踪到目标的路由
easy network traceroute google.com

# 自定义最大跳数
easy network traceroute google.com 15
```

### 网速测试

```bash
# 网速测试
easy network speed
```

### 网络监控

```bash
# 监控默认网络接口
easy network monitor

# 监控指定接口
easy network monitor eth0

# 自定义监控间隔
easy network monitor eth0 3
```

### 端口进程管理

```bash
# 查看占用 8080 端口的进程
easy network list-port 8080

# 结束占用 3000 端口的进程（会提示确认）
easy network kill-port 3000

# 强制结束占用 3306 端口的所有进程
easy network kill-port 3306 --force
```

命令说明：
- `list-port <port>` 会列出指定端口上的全部进程，包含 PID、进程名与启动用户。
- `kill-port <port>` 默认在结束进程前进行确认，可通过 `--force` 直接终止。
- macOS 默认使用 `lsof`，Linux 使用 `ss` 或 `netstat` 进行检测。
## 高级功能

### 批处理模式

```bash
# 使用管道
echo "google.com" | xargs easy network ping

# 批量处理文件
# 检查一组主机的端口
cat hosts.txt | while read host; do
   easy network port "$host" 22
done

# 结合其他命令
easy system info | grep "内存"
```

### 环境变量

```bash
# 临时启用调试模式
DEBUG=true easy system info

# 设置详细输出
VERBOSE=true easy network scan

# 自定义超时
NETWORK_TIMEOUT=60 easy network ping slow-server.com
```

### 别名和快捷方式

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
# 常用命令别名
alias ys='easy'
alias sysinfo='easy system info'
alias netinfo='easy network info'
alias sysmon='easy system monitor'
alias ports8080='easy network list-port 8080'

# 快速查看高负载进程
heavy_processes() {
   easy system process list | head -n 10
}
```

## 故障排除

### 常见错误

#### 1. 命令找不到

**错误信息：**
```
bash: yuxuan-shell: command not found
```

**解决方法：**
```bash
# 检查PATH
echo $PATH | grep yuxuan

# 手动添加到PATH
export PATH="$HOME/.yuxuan_shell/bin:$PATH"

# 永久添加到shell配置
echo 'export PATH="$HOME/.yuxuan_shell/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### 2. 权限错误

**错误信息：**
```
Permission denied: /home/user/.yuxuan_shell/bin/yuxuan-shell
```

**解决方法：**
```bash
chmod +x ~/.yuxuan_shell/bin/yuxuan-shell
```

#### 3. 模块加载失败

**错误信息：**
```
No such file or directory: /home/user/.yuxuan_shell/src/modules/utils.sh
```

**解决方法：**
```bash
# 重新安装（修复缺失模块）
sudo -E bash /path/to/YuxuanShell/scripts/install.sh
```

#### 4. 网络功能不工作

**可能原因：**
- 网络连接问题
- 防火墙阻止
- DNS配置问题

**解决方法：**
```bash
# 检查网络连接
ping 8.8.8.8

# 检查DNS
nslookup google.com

# 使用调试模式
easy --debug network ping google.com
```

### 调试技巧

#### 启用调试输出

```bash
# 全局调试
easy --debug system info

# 模块级调试
DEBUG=true easy network scan

# 详细输出
easy --verbose network scan
```

#### 检查日志

```bash
# 查看系统日志
tail -f ~/.yuxuan_shell/logs/yuxuan-shell.log

# 查看错误日志
grep ERROR ~/.yuxuan_shell/logs/yuxuan-shell.log
```

#### 验证/修复安装

```bash
# 重新运行安装脚本（系统级）
sudo -E bash scripts/install.sh

# 验证全局命令
easy --version
which easy
```

### 获取帮助

1. **查看内置帮助**
   ```bash
   easy --help
   easy system help
   easy network help
   ```

2. **查看文档**
   ```bash
   ls ~/.yuxuan_shell/docs/
   ```

3. **提交Issue**
   - GitHub: https://github.com/SirYuxuan/YuxuanShell/issues
   - 包含系统信息、错误描述和重现步骤

4. **运行诊断**
   ```bash
   easy system info > system_report.txt
   easy --debug network ping example.com > network_report.txt 2>&1
   ```