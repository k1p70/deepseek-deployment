# 多阶段构建：第一阶段-依赖构建层，优化镜像体积
FROM python:3.12-slim AS builder

# 设置工作目录
WORKDIR /app

# 安装系统编译依赖（仅构建阶段需要）
RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖清单，提前安装，利用Docker缓存
COPY requirements.txt .

# 安装Python依赖到虚拟环境，隔离系统环境
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip \
    && pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ \
    && pip install -r requirements.txt \
    && pip install uvicorn python-multipart pymysql redis python-dotenv

# 多阶段构建：第二阶段-运行时层，精简镜像
FROM python:3.12-slim AS runtime

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装运行时必备系统依赖
RUN apt update && apt install -y --no-install-recommends \
    curl \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# 从构建层复制虚拟环境，无需重新安装依赖
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 设置工作目录
WORKDIR /app

# 复制项目全量代码
COPY . .

# 创建非root用户，提升容器安全性
RUN groupadd -r deepseek && useradd -r -g deepseek deepseek \
    && chown -R deepseek:deepseek /app
USER deepseek

# 容器健康检查，验证服务可用性
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 暴露服务端口
EXPOSE 8000

# 容器启动命令，启动DeepSeek推理服务
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--loop", "uvloop"]
