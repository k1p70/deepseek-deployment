import torch
import transformers
import pymysql
import redis

print("===== DeepSeek环境验证报告 =====")
print(f"✅ Python版本: {__import__('sys').version.split()[0]}")
print(f"✅ PyTorch版本: {torch.__version__}")
print(f"✅ CUDA是否可用: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"✅ GPU数量: {torch.cuda.device_count()}")
    print(f"✅ GPU名称: {torch.cuda.get_device_name(0)}")
print(f"✅ Transformers版本: {transformers.__version__}")
print(f"✅ MySQL驱动正常")
print(f"✅ Redis驱动正常")
print("===== 所有核心依赖全部正常！可以继续下一步 =====")
