# Zellij SSL 部署脚本

为 Zellij 终端多路复用器的 Web 界面配置 HTTPS 支持的脚本。

## 功能特性

- Let's Encrypt 免费 SSL 证书自动获取
- DNS-01 挑战验证方式
- 证书自动续订
- systemd 服务集成（可选）
- 简单模式：自签名证书（开发环境）

---

# Zellij 基础使用指南

## 什么是 Zellij？

Zellij 是一个终端工作空间（terminal workspace），内置了布局管理、插件系统、会话共享等功能。类似 tmux，但配置更简单。

## 安装

### Linux/macOS (二进制)

```bash
# 下载 releases
tar -xvf zellij*.tar.gz
chmod +x zellij
./zellij

# 或移动到 PATH
sudo mv zellij /usr/local/bin/
```

### cargo

```bash
cargo install --locked zellij
```

### macOS (Homebrew)

```bash
brew install zellij
```

## 快速开始

```bash
# 启动 Zellij（创建新会话）
zellij

# 查看所有会话
zellij list-sessions
zellij -ls

# 连接到已存在的会话
zellij attach <session-name>
zellij -a <session-name>
```

---

## Session（会话）

Session 是 Zellij 的核心概念，一个 session 包含多个 pane（窗格）和 tab。

### 基本命令

```bash
# 创建命名会话
zellij -s mydev

# 创建新会话并指定布局
zellij -s mydev -l my-layout.yaml

# 连接到会话（若不存在则创建）
zellij attach -c <session-name>

# 断开连接（保持会话运行）
Ctrl+d 或 exit
```

### Web 模式下的 Session

启动 Web 服务器后，可以通过 URL 访问特定 session：

```
http://127.0.0.1:8082              # 欢迎界面
http://127.0.0.1:8082/my-session   # 连接到名为 my-session 的会话
```

URL 行为规则：
1. 若会话不存在，创建新会话
2. 若会话存在，连接到它
3. 若会话已退出，恢复它

这意味着你可以收藏特定 URL，随时恢复到之前的会话状态。

---

## Layout（布局）

Layout 定义了会话中 pane（窗格）的排列方式。

### 使用布局

```bash
# 使用默认布局
zellij

# 使用自定义布局文件
zellij -l ~/.zellij/layouts/my-layout.kdl

# 内联布局
zellij -l '
layout {
    pane
    pane
}
'
```

### 布局语法

```kdl
# 基础布局：左右两个窗格
layout {
    pane
    pane
}

# 垂直分屏
layout {
    pane split_direction="vertical" {
        pane
        pane
    }
}

# 复杂布局：顶部 htop，底部两个窗格
layout {
    pane split_direction="vertical" {
        pane command="htop"
        pane split_direction="horizontal" {
            pane
            pane
        }
    }
}
```

### Pane 属性

```kdl
layout {
    pane                          # 基础窗格
    pane command="htop"           # 运行指定命令
    pane cwd="/path/to/dir"       # 指定工作目录
    pane size=1/3                 # 相对大小
    pane size=10                  # 固定行数
    pane borderless=true          # 无边框
}
```

### 常用布局示例

```kdl
# default.kdl - 左右分屏
layout {
    pane
    pane
}

# triple.kdl - 三列均分
layout {
    pane size=1/3
    pane size=1/3
    pane
}

# with-status.kdl - 顶部状态栏
layout {
    pane size=1 borderless=true {
        plugin location="zellij:compact-bar"
    }
    pane split_direction="vertical" {
        pane
        pane
    }
}

# development.kdl - 开发环境
layout {
    pane split_direction="vertical" {
        pane command="vim"
        pane split_direction="horizontal" {
            pane command="npm" args="run" "test"
            pane command="npm" args="run" "dev"
        }
    }
}
```

布局文件保存在 `~/.zellij/layouts/` 目录。

---

## 快捷键

Zellij 使用模式化的快捷键系统：

| 快捷键 | 说明 |
|--------|------|
| `Ctrl+g` | 切换到命令模式 |
| `Ctrl+p` | 进入窗格模式 |
| `Ctrl+o` | 进入锁模式 |
| `Ctrl+c` | 复制模式 |
| `Ctrl+z` | 暂停（返回前台） |

### 窗格模式 (Pane Mode)

进入后使用 `h/j/k/l` 移动：

| 快捷键 | 说明 |
|--------|------|
| `h` / `←` | 聚焦左窗格 |
| `j` / `↓` | 聚焦下窗格 |
| `k` / `↑` | 聚焦上窗格 |
| `l` / `→` | 聚焦右窗格 |
| `p` | 切换上一个窗格 |
| `Enter` | 确认选择 |
| `Esc` | 退出模式 |

### 常用操作

| 快捷键 | 说明 |
|--------|------|
| `Alt+n` | 新建窗格 |
| `Alt+d` | 垂直分屏 |
| `Alt+-|` | 水平分屏 |
| `Alt+h/j/k/l` | 移动窗格焦点 |
| `Alt+[1-9]` | 切换到指定 tab |
| `Ctrl+t` | 新建 tab |
| `Ctrl+w` | 关闭窗格 |
| `Tab` | 下一个 tab |

---

## Web 服务器

```bash
# 启动 Web 服务器（默认端口 8082）
zellij web

# 指定端口和 IP
zellij web --port 9000 --ip 0.0.0.0

# 指定 SSL 证书（生产环境推荐）
zellij web --port 8082 \
  --cert /path/to/fullchain.pem \
  --key /path/to/privkey.pem
```

访问 `http://127.0.0.1:8082` 打开 Web 界面。

---

## 配置文件

Zellij 配置文件位于 `~/.config/zellij/config.kdl`：

```kdl
theme "default"
theme_dir "~/.config/zellij/themes"

keybinds {
    normal {
        bind "Ctrl g" { SwitchToMode "locked"; }
        bind "Alt n" { NewPane; }
        bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
    }
    pane {
        bind "h" { MoveFocus "Left"; }
        bind "j" { MoveFocus "Down"; }
        bind "k" { MoveFocus "Up"; }
        bind "l" { MoveFocus "Right"; }
    }
}
```

---

# SSL 部署脚本使用说明

## 部署流程

### 生产环境（Let's Encrypt）

```bash
# 1. 获取证书（第一阶段：生成 DNS 挑战）
./zellij-ssl.sh cert

# 2. 在 DNS 控制台添加 TXT 记录
# 脚本会输出需要添加的记录名称和值

# 3. 完成证书获取（阶段2）
./zellij-ssl.sh cert2

# 4. 启动 Zellij Web
./zellij-ssl.sh start
```

### 开发环境（自签名证书）

```bash
# 使用默认配置（localhost:8082）
./zellij-ssl-simple.sh

# 指定域名和端口
./zellij-ssl-simple.sh example.com 9000
```

## 命令说明

| 命令 | 说明 |
|------|------|
| `./zellij-ssl.sh cert` | 获取证书（阶段1：生成挑战） |
| `./zellij-ssl.sh cert2` | 获取证书（阶段2：验证并获取） |
| `./zellij-ssl.sh start` | 启动 Zellij Web |
| `./zellij-ssl.sh stop` | 停止 Zellij Web |
| `./zellij-ssl.sh restart` | 重启 Zellij Web |
| `./zellij-ssl.sh renew` | 手动续订证书 |
| `./zellij-ssl.sh dns` | 检查 DNS 记录状态 |
| `./zellij-ssl.sh status` | 查看证书和服务状态 |
| `./zellij-ssl.sh setup` | 完整设置（安装、cron、自动启动） |

## 配置文件

编辑脚本开头的变量：

```bash
DOMAIN="your-domain.com"
EMAIL="your@email.com"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
WEB_PORT=8082
```

## Session Name 和 Session Layout 结合使用

```bash
# 创建命名会话并指定布局
zellij -s myproject -l development.kdl

# 通过 HTTPS 访问
https://your-domain.com:8082?session=myproject
```

---

## 故障排除

### 证书获取失败
- 确认 TXT 记录已正确添加
- 使用 `./zellij-ssl.sh dns` 检查记录
- DNS 记录可能需要几分钟传播

### Zellij 无法启动
```bash
cat /tmp/zellij.log
netstat -tlnp | grep 8082
```

### 访问被拒绝
- 检查防火墙设置
- 确认域名已解析到服务器 IP
