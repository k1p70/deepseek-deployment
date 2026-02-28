from huggingface_hub import snapshot_download
import os

# DeepSeek官方开源1.3B轻量对话模型，CPU环境8G内存可流畅运行
repo_id = "deepseek-ai/deepseek-coder-1.3b-instruct"
save_dir = "./models/deepseek-coder-1.3b-instruct"

# 配置国内镜像，解决下载慢、超时问题
os.environ['HF_ENDPOINT'] = 'https://hf-mirror.com'

if not os.path.exists(save_dir):
    os.makedirs(save_dir)

print(f"开始下载模型: {repo_id}，请耐心等待...")
model_path = snapshot_download(
    repo_id=repo_id,
    local_dir=save_dir,
    local_dir_use_symlinks=False
)

print(f"✅ 模型下载完成！")
print(f"⚠️  模型绝对路径（复制到.env的MODEL_PATH参数）：{os.path.abspath(model_path)}")
