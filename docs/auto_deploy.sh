# DeepSeek LLM服务 全流程自动化部署脚本
# 适用环境：Ubuntu 20.04/22.04/24.04 LTS
# 执行方式：sudo bash auto_deploy.sh

# ===================== 配置项（可根据实际情况修改）=====================
PROJECT_DIR="/opt/deepseek-llm"
GITHUB_REPO="https://github.com/k1p70/my-learning-git.git"
DOCKER_VERSION="26.0.2"
MYSQL_PASSWORD="DeepSeek@123"
REDIS_PASSWORD="DeepSeekRedis@123"
# ======================================================================

# 日志输出函数
log_info() {
    echo -e "\033[32m[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1\033[0m"
}

log_error() {
    echo -e "\033[31m[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1\033[0m"
    exit 1
}

# 前置检查：必须用root权限执行
if [ "$(id -u)" -ne 0 ]; then
    log_error "请使用sudo或root权限执行此脚本"
fi

log_info "===================== DeepSeek LLM 自动化部署开始 ====================="

# 步骤1：系统环境初始化与更新
log_info "1. 系统环境初始化，更新软件源..."
apt update && apt upgrade -y
apt install -y ca-certificates curl gnupg lsb-release git tree vim ufw
log_info "系统基础工具安装完成"

# 步骤2：防火墙配置
log_info "2. 配置防火墙，放行所需端口..."
ufw allow 22/tcp
ufw allow 8000/tcp
ufw allow 3000/tcp
ufw --force enable
log_info "防火墙配置完成，已放行SSH、服务、监控端口"

# 步骤3：安装Docker与docker-compose
log_info "3. 安装Docker与docker-compose..."
# 卸载旧版本Docker
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt remove -y $pkg || true
done

# 添加Docker官方GPG密钥
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 添加Docker软件源
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 验证安装
if ! docker --version; then
    log_error "Docker安装失败"
fi
if ! docker compose version; then
    log_error "docker-compose安装失败"
fi

# 配置Docker开机自启
systemctl enable --now docker
log_info "Docker安装完成，已设置开机自启"

# 步骤4：拉取项目代码
log_info "4. 拉取项目代码到 $PROJECT_DIR..."
if [ -d "$PROJECT_DIR" ]; then
    log_info "项目目录已存在，备份原有代码并拉取最新版本"
    mv $PROJECT_DIR ${PROJECT_DIR}_bak_$(date +%Y%m%d%H%M%S)
fi

git clone $GITHUB_REPO $PROJECT_DIR
cd $PROJECT_DIR
log_info "项目代码拉取完成，当前分支：$(git rev-parse --abbrev-ref HEAD)"

# 步骤5：生成环境配置文件
log_info "5. 生成.env环境配置文件..."
cat > .env << EOF
# 模型配置
MODEL_PATH=/models
DEVICE=cpu
# MySQL配置
MYSQL_HOST=deepseek-mysql
MYSQL_PORT=3306
MYSQL_USER=deepseek_user
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_DATABASE=deepseek_db
# Redis配置
REDIS_HOST=deepseek-redis
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_DB=0
# 服务配置
DEBUG=False
WORKERS=2
EOF
log_info "环境配置文件生成完成"

# 步骤6：构建并启动容器服务
log_info "6. 构建Docker镜像，启动全栈服务..."
docker compose build --no-cache
docker compose up -d

# 步骤7：服务健康检查
log_info "7. 执行服务健康检查，等待服务启动..."
sleep 30

# 检查容器运行状态
if [ $(docker compose ps -q --filter "status=running" | wc -l) -ne 3 ]; then
    log_error "部分容器启动失败，请执行 docker compose ps 查看详情"
fi

# 检查服务接口可用性
if ! curl -f http://127.0.0.1:8000/health; then
    log_error "DeepSeek服务健康检查失败，请查看容器日志：docker compose logs deepseek-app"
fi

log_info "===================== 部署完成！所有服务正常运行 ====================="
log_info "服务访问地址：http://$(hostname -I | awk '{print $1}'):8000/docs"
log_info "服务管理命令："
log_info "  查看服务状态：cd $PROJECT_DIR && docker compose ps"
log_info "  查看服务日志：cd $PROJECT_DIR && docker compose logs -f deepseek-app"
log_info "  停止服务：cd $PROJECT_DIR && docker compose down"
log_info "  重启服务：cd $PROJECT_DIR && docker compose restart"
