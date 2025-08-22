#!/bin/bash

# Coze Studio 本地部署脚本 (增强版)
# 支持自动发现Ollama模型、智能检测已有安装、配置备份等功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置变量
PROJECT_NAME="coze-studio"
GIT_REPO="https://github.com/coze-dev/coze-studio.git"
INSTALL_DIR="$(pwd)/${PROJECT_NAME}"
BACKUP_DIR="$(pwd)/coze-studio-backup-$(date +%Y%m%d_%H%M%S)"
OLLAMA_HOST="localhost"
OLLAMA_PORT="11434"
REMOTE_ACCESS="false"

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if command_exists netstat; then
        netstat -tuln | grep ":$port " >/dev/null 2>&1
    elif command_exists ss; then
        ss -tuln | grep ":$port " >/dev/null 2>&1
    else
        # 尝试连接端口
        timeout 3 bash -c "</dev/tcp/localhost/$port" >/dev/null 2>&1
    fi
}

# 检查项目是否已存在
check_existing_installation() {
    if [ -d "$INSTALL_DIR" ]; then
        log_info "检测到已存在的 Coze Studio 目录: $INSTALL_DIR"
        
        # 检查是否是有效的 coze-studio 项目
        if [ -f "$INSTALL_DIR/rush.json" ] && [ -f "$INSTALL_DIR/backend/go.mod" ] && [ -f "$INSTALL_DIR/frontend/apps/coze-studio/package.json" ]; then
            log_success "检测到有效的 Coze Studio 安装"
            
            # 询问用户是否要重置配置
            echo
            read -p "是否要备份现有配置并重置为默认配置？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                reset_configuration
                return 1  # 不需要克隆
            else
                log_info "使用现有安装和配置，跳过克隆和配置重置"
                cd "$INSTALL_DIR"
                return 1  # 不需要克隆
            fi
        else
            log_warning "目录存在但不是有效的 Coze Studio 项目"
            read -p "是否删除现有目录并重新克隆？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$INSTALL_DIR"
                return 0  # 需要克隆
            else
                log_error "无法继续，请手动处理现有目录"
                exit 1
            fi
        fi
    fi
    return 0  # 需要克隆
}

# 重置配置（不重新克隆）
reset_configuration() {
    log_info "开始备份现有配置..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 备份重要配置文件
    local config_files=(
        ".env"
        ".env.debug"
        "docker/.env"
        "docker/.env.debug"
        "backend/conf/model"
        "backend/conf/plugin"
        "backend/conf/prompt"
    )
    
    cd "$INSTALL_DIR"
    for config_file in "${config_files[@]}"; do
        if [ -e "$config_file" ]; then
            log_info "备份: $config_file"
            mkdir -p "$BACKUP_DIR/$(dirname "$config_file")"
            cp -r "$config_file" "$BACKUP_DIR/$config_file"
        fi
    done
    
    # 备份自定义模型配置
    if [ -d "backend/conf/model" ]; then
        log_info "备份模型配置目录"
        cp -r "backend/conf/model" "$BACKUP_DIR/backend/conf/"
    fi
    
    log_success "配置备份完成: $BACKUP_DIR"
    
    # 重置配置文件（不删除整个项目）
    log_info "重置配置文件为默认状态..."
    
    # 删除现有配置文件
    for config_file in "${config_files[@]}"; do
        if [ -e "$config_file" ]; then
            log_info "删除现有配置: $config_file"
            rm -rf "$config_file"
        fi
    done
    
    # 清理构建产物
    log_info "清理构建产物..."
    [ -d "bin" ] && rm -rf "bin"
    [ -d "frontend/apps/coze-studio/dist" ] && rm -rf "frontend/apps/coze-studio/dist"
    [ -d "frontend/apps/coze-studio/node_modules" ] && rm -rf "frontend/apps/coze-studio/node_modules"
    [ -d "node_modules" ] && rm -rf "node_modules"
    
    # 重置 Git 状态（保留本地更改但重置配置相关文件）
    log_info "重置 Git 状态..."
    git checkout HEAD -- .env.example .env.debug.example 2>/dev/null || true
    git clean -fd backend/conf/ 2>/dev/null || true
    
    log_success "配置重置完成，将使用默认配置重新初始化"
}

# 备份配置并重新初始化（保留原函数用于 --backup-only 选项）
backup_and_reinitialize() {
    log_info "开始备份现有配置..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 备份重要配置文件
    local config_files=(
        ".env"
        ".env.debug"
        "docker/.env"
        "docker/.env.debug"
        "backend/conf/model"
        "backend/conf/plugin"
        "backend/conf/prompt"
    )
    
    cd "$INSTALL_DIR"
    for config_file in "${config_files[@]}"; do
        if [ -e "$config_file" ]; then
            log_info "备份: $config_file"
            mkdir -p "$BACKUP_DIR/$(dirname "$config_file")"
            cp -r "$config_file" "$BACKUP_DIR/$config_file"
        fi
    done
    
    # 备份自定义模型配置
    if [ -d "backend/conf/model" ]; then
        log_info "备份模型配置目录"
        cp -r "backend/conf/model" "$BACKUP_DIR/backend/conf/"
    fi
    
    log_success "配置备份完成: $BACKUP_DIR"
    
    # 清理并重新克隆
    cd ..
    log_info "清理现有安装..."
    rm -rf "$INSTALL_DIR"
    
    log_info "重新克隆项目..."
    git clone "$GIT_REPO" "$PROJECT_NAME"
    cd "$INSTALL_DIR"
    
    # 恢复配置文件
    log_info "恢复配置文件..."
    for config_file in "${config_files[@]}"; do
        if [ -e "$BACKUP_DIR/$config_file" ]; then
            log_info "恢复: $config_file"
            mkdir -p "$(dirname "$config_file")"
            cp -r "$BACKUP_DIR/$config_file" "$config_file"
        fi
    done
    
    log_success "配置恢复完成"
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    # 检查是否为Ubuntu系统
    if [ ! -f "/etc/os-release" ]; then
        log_error "无法检测操作系统信息"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "此脚本仅支持Ubuntu系统，当前系统: $ID"
        exit 1
    fi
    
    # 检查Ubuntu版本
    local ubuntu_version=$(echo $VERSION_ID | cut -d. -f1)
    if [ "$ubuntu_version" -lt 20 ]; then
        log_error "需要Ubuntu 20.04或更高版本，当前版本: $VERSION_ID"
        exit 1
    fi
    
    log_success "操作系统: Ubuntu $VERSION_ID"
    
    # 检查必要工具
    local required_tools=("git" "curl" "jq")
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            log_error "缺少必要工具: $tool"
            case $tool in
                "git")
                    log_info "安装命令: sudo apt update && sudo apt install -y git"
                    ;;
                "curl")
                    log_info "安装命令: sudo apt update && sudo apt install -y curl"
                    ;;
                "jq")
                    log_info "安装命令: sudo apt update && sudo apt install -y jq"
                    ;;
            esac
            exit 1
        fi
    done
    
    log_success "系统要求检查通过"
}

# 安装 Node.js (简化版)
install_nodejs() {
    if command_exists node; then
        local node_version=$(node --version | sed 's/v//')
        local major_version=$(echo $node_version | cut -d. -f1)
        if [ "$major_version" -ge 18 ]; then
            log_success "Node.js 已安装: v$node_version"
            return
        fi
    fi
    
    log_info "通过apt安装Node.js..."
    sudo apt update
    sudo apt install -y nodejs npm
    
    # 配置npm使用国内镜像
    npm config set registry https://registry.npmmirror.com
    
    if command_exists node; then
        local installed_version=$(node --version)
        log_success "Node.js 安装完成: $installed_version"
    else
        log_error "Node.js 安装失败"
        exit 1
    fi
}

# 安装 Go (简化版)
install_go() {
    if command_exists go; then
        local go_version=$(go version | awk '{print $3}' | sed 's/go//')
        log_success "Go 已安装: $go_version"
        return
    fi
    
    log_info "通过apt安装Go..."
    sudo apt update
    sudo apt install -y golang-go
    
    # 配置Go环境变量
    if ! grep -q "GOPATH" ~/.bashrc; then
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin' >> ~/.bashrc
        log_info "已配置Go环境变量"
    fi
    
    # 配置Go代理
    go env -w GOPROXY=https://goproxy.cn,direct
    go env -w GOSUMDB=sum.golang.google.cn
    
    export GOPATH=$HOME/go
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    
    if command_exists go; then
        local installed_version=$(go version | awk '{print $3}')
        log_success "Go 安装完成: $installed_version"
    else
        log_error "Go 安装失败"
        exit 1
    fi
}

# 一键安装所有依赖
install_all_dependencies() {
    log_info "安装所有系统依赖..."
    
    # 更新包列表
    sudo apt update
    
    # 安装所有依赖
    sudo apt install -y \
        git \
        curl \
        jq \
        nodejs \
        npm \
        golang-go \
        docker.io \
        docker-compose
    
    # 配置npm镜像
    npm config set registry https://registry.npmmirror.com
    
    # 配置Go代理
    go env -w GOPROXY=https://goproxy.cn,direct
    go env -w GOSUMDB=sum.golang.google.cn
    
    # 启动Docker服务
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # 添加用户到docker组
    sudo usermod -aG docker $USER
    
    log_success "所有依赖安装完成！"
    log_info "请重新登录以使docker组权限生效"
}

# 安装 Rush.js
install_rush() {
    if command_exists rush; then
        log_success "Rush.js 已安装"
        return
    fi
    
    log_info "安装 Rush.js..."
    npm install -g @microsoft/rush
    log_success "Rush.js 安装完成"
}

# 检查并启动数据库服务
setup_database_services() {
    log_info "检查数据库服务..."
    
    # 检查 Docker
    if command_exists docker && command_exists docker-compose; then
        log_info "使用 Docker 启动数据库服务..."
        
        # 检查 docker-compose.yml 是否存在
        if [ -f "docker/docker-compose.yml" ]; then
            cd docker
            
            # 启动数据库相关服务
            docker-compose up -d mysql redis etcd minio rocketmq
            
            # 等待服务启动
            log_info "等待数据库服务启动..."
            sleep 10
            
            cd ..
            log_success "数据库服务启动完成"
        else
            log_error "未找到 docker-compose.yml 文件"
            exit 1
        fi
    else
        log_warning "Docker 未安装，请手动安装以下服务："
        echo "  - MySQL 8.0+"
        echo "  - Redis 6.0+"
        echo "  - etcd 3.5+"
        echo "  - MinIO (可选，用于文件存储)"
        echo "  - RocketMQ (可选，用于消息队列)"
        echo
        read -p "是否已手动安装这些服务？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "请先安装必要的数据库服务"
            exit 1
        fi
    fi
}

# 发现 Ollama 模型
discover_ollama_models() {
    log_info "连接到 Ollama 服务器 ($OLLAMA_HOST:$OLLAMA_PORT)..."
    
    # 检查 Ollama 服务是否可用
    if ! curl -s "http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags" >/dev/null; then
        log_error "无法连接到 Ollama 服务器"
        log_info "请确保 Ollama 服务正在运行："
        echo "  ollama serve"
        echo
        read -p "是否跳过 Ollama 配置？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return
        else
            exit 1
        fi
    fi
    
    # 获取模型列表
    local models_json
    models_json=$(curl -s "http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags")
    
    if [ $? -ne 0 ] || [ -z "$models_json" ]; then
        log_error "获取模型列表失败"
        return
    fi
    
    # 解析模型列表
    local models
    models=$(echo "$models_json" | jq -r '.models[]?.name // empty' 2>/dev/null)
    
    if [ -z "$models" ]; then
        log_warning "未发现任何 Ollama 模型"
        log_info "请先拉取一些模型，例如："
        echo "  ollama pull llama3.2"
        echo "  ollama pull gemma2"
        echo "  ollama pull qwen2.5"
        return
    fi
    
    log_success "发现以下 Ollama 模型："
    echo "$models" | while read -r model; do
        echo "  - $model"
    done
    
    # 生成模型配置
    generate_model_configs "$models"
}

# 生成模型配置文件
generate_model_configs() {
    local models="$1"
    local model_config_dir="backend/conf/model"
    
    log_info "生成模型配置文件..."
    
    # 确保配置目录存在
    mkdir -p "$model_config_dir"
    
    # 为每个模型生成配置
    echo "$models" | while read -r model; do
        if [ -n "$model" ]; then
            # 生成模型 ID（移除特殊字符）
            local model_id=$(echo "$model" | sed 's/[^a-zA-Z0-9]/_/g')
            local config_file="$model_config_dir/ollama_${model_id}.yaml"
            
            # 生成友好的显示名称
            local display_name=$(echo "$model" | sed 's/:latest$//' | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
            
            # 创建配置文件
            cat > "$config_file" << EOF
id: "ollama_${model_id}"
name: "${display_name} (Ollama)"
type: "ollama"
config:
  base_url: "http://${OLLAMA_HOST}:${OLLAMA_PORT}"
  model: "${model}"
  temperature: 0.7
  max_tokens: 4096
  stream: true
EOF
            
            log_success "生成配置: $config_file"
        fi
    done
}

# 配置环境变量
setup_environment() {
    log_info "配置环境变量..."
    
    # 创建 .env 文件（如果不存在）
    if [ ! -f ".env" ]; then
        cat > .env << EOF
# Coze Studio 环境配置

# 服务配置
APP_ENV=production
SERVER_PORT=8080
SERVER_HOST=0.0.0.0

# 数据库配置
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=123456
MYSQL_DATABASE=coze_studio

# Redis 配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Ollama 配置
OLLAMA_HOST=${OLLAMA_HOST}
OLLAMA_PORT=${OLLAMA_PORT}

# 远程访问配置
REMOTE_ACCESS=${REMOTE_ACCESS}
EOF
        log_success "创建 .env 文件"
    else
        log_info ".env 文件已存在，跳过创建"
    fi
    
    # 创建 .env.debug 文件（如果不存在）
    if [ ! -f ".env.debug" ]; then
        cp .env .env.debug
        sed -i 's/APP_ENV=production/APP_ENV=debug/' .env.debug
        log_success "创建 .env.debug 文件"
    fi
}

# 构建前端
build_frontend() {
    log_info "构建前端应用..."
    
    # 安装前端依赖
    log_info "安装前端依赖..."
    rush update
    
    # 构建前端
    log_info "编译前端代码..."
    rush rebuild --to @coze-studio/app
    
    log_success "前端构建完成"
}

# 构建后端
build_backend() {
    log_info "构建后端应用..."
    
    cd backend
    
    # 下载 Go 依赖
    log_info "下载 Go 依赖..."
    go mod download
    
    # 构建后端
    log_info "编译后端代码..."
    go build -o ../bin/opencoze ./main.go
    
    cd ..
    
    # 复制配置文件
    log_info "复制配置文件..."
    mkdir -p bin/resources
    cp -r backend/conf bin/resources/
    
    # 复制前端静态文件（如果存在）
    if [ -d "frontend/apps/coze-studio/dist" ]; then
        cp -r frontend/apps/coze-studio/dist bin/resources/static
    fi
    
    log_success "后端构建完成"
}

# 检查服务连接
check_services() {
    log_info "检查服务连接..."
    
    # 检查 MySQL
    if check_port 3306; then
        log_success "MySQL 服务正在运行"
    else
        log_warning "MySQL 服务未运行"
    fi
    
    # 检查 Redis
    if check_port 6379; then
        log_success "Redis 服务正在运行"
    else
        log_warning "Redis 服务未运行"
    fi
    
    # 检查 Ollama
    if check_port "$OLLAMA_PORT"; then
        log_success "Ollama 服务正在运行"
    else
        log_warning "Ollama 服务未运行"
    fi
}

# 启动服务
start_services() {
    log_info "启动 Coze Studio 服务..."
    
    # 检查可执行文件
    if [ ! -f "bin/opencoze" ]; then
        log_error "未找到可执行文件 bin/opencoze"
        exit 1
    fi
    
    # 启动服务
    log_success "Coze Studio 正在启动..."
    echo
    log_info "访问地址: http://localhost:8080"
    log_info "按 Ctrl+C 停止服务"
    echo
    
    cd bin
    ./opencoze
}

# 显示帮助信息
show_help() {
    cat << EOF
Coze Studio 本地部署脚本 (增强版)

用法: $0 [选项]

选项:
  -h, --help              显示此帮助信息
  --ollama-host HOST      Ollama 服务器地址 (默认: localhost)
  --ollama-port PORT      Ollama 服务器端口 (默认: 11434)
  --remote-access         启用远程访问
  --skip-build            跳过构建步骤
  --backup-only           仅备份现有配置

示例:
  $0                                    # 标准部署
  $0 --ollama-host 192.168.1.100       # 指定 Ollama 服务器
  $0 --remote-access                    # 启用远程访问
  $0 --skip-build                       # 跳过构建（适用于重新启动）

系统要求:
  - Node.js 18.0.0+
  - Go 1.24.0+
  - Git
  - curl
  - jq
  - Docker & Docker Compose (推荐)

依赖服务:
  - MySQL 8.0+
  - Redis 6.0+
  - etcd 3.5+
  - Ollama (用于 AI 模型)
  - MinIO (可选，文件存储)
  - RocketMQ (可选，消息队列)

Ollama 配置:
  1. 安装 Ollama: https://ollama.ai/
  2. 启动服务: ollama serve
  3. 拉取模型: ollama pull llama3.2
  4. 运行此脚本自动配置

故障排除:
  1. 端口冲突: 检查 8080, 3306, 6379, 11434 端口
  2. 权限问题: 确保有写入权限
  3. 网络问题: 检查防火墙和代理设置
  4. 依赖缺失: 按提示安装缺失的工具
  5. 配置备份: 脚本会自动备份现有配置

EOF
}

# 主函数
main() {
    local skip_build=false
    local backup_only=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --ollama-host)
                OLLAMA_HOST="$2"
                shift 2
                ;;
            --ollama-port)
                OLLAMA_PORT="$2"
                shift 2
                ;;
            --remote-access)
                REMOTE_ACCESS="true"
                shift
                ;;
            --skip-build)
                skip_build=true
                shift
                ;;
            --backup-only)
                backup_only=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "=== Coze Studio 本地部署脚本 (增强版) ==="
    echo
    
    # 仅备份模式
    if [ "$backup_only" = true ]; then
        if [ -d "$INSTALL_DIR" ]; then
            cd "$INSTALL_DIR"
            backup_and_reinitialize
            log_success "备份完成，退出"
            exit 0
        else
            log_error "未找到现有安装"
            exit 1
        fi
    fi
    
    # 检查系统要求
    check_system_requirements
    
    # 检查现有安装
    local need_clone=true
    if check_existing_installation; then
        need_clone=true
    else
        need_clone=false
    fi
    
    # 克隆项目（如果需要）
    if [ "$need_clone" = true ]; then
        log_info "克隆 Coze Studio 项目..."
        git clone "$GIT_REPO" "$PROJECT_NAME"
        cd "$INSTALL_DIR"
        log_success "项目克隆完成"
    fi
    
    # 安装依赖
    install_nodejs
    install_go
    install_rush
    
    # 设置数据库服务
    setup_database_services
    
    # 配置环境
    setup_environment
    
    # 发现并配置 Ollama 模型
    discover_ollama_models
    
    # 构建项目（如果不跳过）
    if [ "$skip_build" = false ]; then
        build_frontend
        build_backend
    else
        log_info "跳过构建步骤"
    fi
    
    # 检查服务
    check_services
    
    # 启动服务
    start_services
}

# 错误处理
trap 'log_error "脚本执行失败，请检查错误信息"' ERR

# 运行主函数
main "$@"