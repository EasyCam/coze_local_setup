# Coze Studio Local Deployment Script (Enhanced Version)

An enhanced bash script for local deployment of Coze Studio with automatic Ollama model discovery, intelligent installation detection, and configuration backup features.

## Features

- 🚀 **One-click deployment** - Automated installation and configuration
- 🔍 **Automatic Ollama model discovery** - Detects and configures available models
- 🛡️ **Intelligent installation detection** - Handles existing installations gracefully
- 💾 **Configuration backup** - Automatic backup of existing configurations
- 🔧 **Multi-platform support** - Linux, macOS, and Windows (WSL/Cygwin)
- 🐳 **Docker integration** - Automated database service setup
- 📊 **Comprehensive logging** - Colored output with detailed progress tracking

## System Requirements

### Required Software

- **Node.js** 18.0.0+
- **Go** 1.24.0+
- **Git**
- **curl**
- **jq**
- **Docker & Docker Compose** (recommended)

### Required Services

- **MySQL** 8.0+
- **Redis** 6.0+
- **etcd** 3.5+
- **Ollama** (for AI models)
- **MinIO** (optional, for file storage)
- **RocketMQ** (optional, for message queue)

## Quick Start

### 1. Basic Installation

```bash
./coze.sh
```

### 2. Custom Ollama Server

```bash
./coze.sh --ollama-host 192.168.1.100 --ollama-port 11434
```

### 3. Enable Remote Access

```bash
./coze.sh --remote-access
```

### 4. Skip Build (for restart)

```bash
./coze.sh --skip-build
```

## Usage Options

| Option                 | Description                        | Default   |
| ---------------------- | ---------------------------------- | --------- |
| `-h, --help`         | Show help information              | -         |
| `--ollama-host HOST` | Ollama server address              | localhost |
| `--ollama-port PORT` | Ollama server port                 | 11434     |
| `--remote-access`    | Enable remote access               | false     |
| `--skip-build`       | Skip build process                 | false     |
| `--backup-only`      | Only backup existing configuration | false     |

## Ollama Setup

### 1. Install Ollama

Visit [https://ollama.ai/](https://ollama.ai/) and follow the installation instructions for your platform.

### 2. Start Ollama Service

```bash
ollama serve
```

### 3. Pull Models

```bash
ollama pull llama3.2
ollama pull gemma2
ollama pull qwen2.5
```

### 4. Run Deployment Script

The script will automatically discover and configure available models.

## Project Structure

After successful deployment:
