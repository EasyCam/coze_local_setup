# Coze Studio 本地部署脚本 (增强版)

一个功能增强的 Coze Studio 本地部署 bash 脚本，支持自动发现 Ollama 模型、智能检测已有安装、配置备份等功能。

## 功能特性

- 🚀 **一键部署** - 自动化安装和配置
- 🔍 **自动发现 Ollama 模型** - 检测并配置可用模型
- 🛡️ **智能安装检测** - 优雅处理现有安装
- 💾 **配置备份** - 自动备份现有配置
- 🔧 **多平台支持** - Linux、macOS 和 Windows (WSL/Cygwin)
- 🐳 **Docker 集成** - 自动化数据库服务设置
- 📊 **完整日志** - 彩色输出和详细进度跟踪

## 系统要求

### 必需软件
- **Node.js** 18.0.0+
- **Go** 1.24.0+
- **Git**
- **curl**
- **jq**
- **Docker & Docker Compose** (推荐)

### 依赖服务
- **MySQL** 8.0+
- **Redis** 6.0+
- **etcd** 3.5+
- **Ollama** (用于 AI 模型)
- **MinIO** (可选，用于文件存储)
- **RocketMQ** (可选，用于消息队列)

## 快速开始

### 1. 基础安装
```bash
./coze.sh
```

### 2. 自定义 Ollama 服务器
```bash
./coze.sh --ollama-host 192.168.1.100 --ollama-port 11434
```

### 3. 启用远程访问
```bash
./coze.sh --remote-access
```

### 4. 跳过构建（用于重启）
```bash
./coze.sh --skip-build
```

## 使用选项

| 选项 | 描述 | 默认值 |
|------|------|--------|
| `-h, --help` | 显示帮助信息 | - |
| `--ollama-host HOST` | Ollama 服务器地址 | localhost |
| `--ollama-port PORT` | Ollama 服务器端口 | 11434 |
| `--remote-access` | 启用远程访问 | false |
| `--skip-build` | 跳过构建过程 | false |
| `--backup-only` | 仅备份现有配置 | false |

## Ollama 设置

### 1. 安装 Ollama
访问 [https://ollama.ai/](https://ollama.ai/) 并按照您的平台安装说明进行操作。

### 2. 启动 Ollama 服务
```bash
ollama serve
```

### 3. 拉取模型
```bash
ollama pull llama3.2
ollama pull gemma2
ollama pull qwen2.5
```

### 4. 运行部署脚本
脚本将自动发现并配置可用模型。

## 项目结构

部署成功后的目录结构：