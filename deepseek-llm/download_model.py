from modelscope import snapshot_download
import os

# 确认可正常下载的DeepSeek官方轻量对话模型，1.5B参数，CPU环境8G内存可流畅运行
model_name = "deepseek-ai/DeepSeek-R-Distill-Qwen-1.5B-Chat"
# 模型固定存放在项目根目录的models文件夹，和之前部署流程路径统一
save_dir = "./models"

# 提前创建存放目录
if not os.path.exists(save_dir):
    os.makedirs(save_dir)

# 配置国内下载节点，解决访问异常
os.environ['MODELSCOPE_API_BASE_URL'] = 'https://modelscope.cn/api/v1'
os.environ['MODELSCOPE_DOWNLOAD_ENDPOINT'] = 'https://modelscope.cn'

print(f"开始下载模型: {model_name}，请耐心等待...")
# 移除不兼容的endpoint参数，用环境变量配置下载节点
model_path = snapshot_download(
    model_id=model_name,
    cache_dir=save_dir
)

# 输出关键信息，直接用于后续.env配置
print(f"✅ 模型下载完成！")
print(f"⚠️  模型绝对路径（复制到.env的MODEL_PATH参数）：{os.path.abspath(model_path)}")
