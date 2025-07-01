#!/usr/bin/env python3
"""
GPT-SoVITS API启动脚本
确保依赖安装并启动GPT-SoVITS API服务
"""

import os
import sys
import subprocess
import importlib.util

# 获取路径
current_dir = os.path.dirname(os.path.abspath(__file__))
gpt_sovits_dir = os.path.join(current_dir, 'GPT-SoVITS')

# 检查GPT-SoVITS目录
if not os.path.exists(gpt_sovits_dir):
    print(f"错误: GPT-SoVITS目录不存在: {gpt_sovits_dir}")
    print("请先运行 gpt_sovits_setup.sh 安装GPT-SoVITS")
    sys.exit(1)

# 切换到GPT-SoVITS目录
os.chdir(gpt_sovits_dir)

# 检查并安装必要的依赖
required_modules = ['jieba', 'gradio', 'librosa', 'soundfile', 'fastapi', 'uvicorn']
missing_modules = []

for module in required_modules:
    if importlib.util.find_spec(module) is None:
        missing_modules.append(module)

if missing_modules:
    print(f"安装缺失的依赖: {', '.join(missing_modules)}")
    subprocess.check_call([sys.executable, '-m', 'pip', 'install'] + missing_modules)

# 设置环境变量
os.environ['PYTHONPATH'] = f"{gpt_sovits_dir}:{os.path.join(gpt_sovits_dir, 'GPT_SoVITS')}:{os.environ.get('PYTHONPATH', '')}"

# 启动GPT-SoVITS API
print("启动GPT-SoVITS API服务...")
print(f"工作目录: {os.getcwd()}")

# 使用subprocess启动api.py
api_script = os.path.join(gpt_sovits_dir, 'api.py')
if os.path.exists(api_script):
    cmd = [
        sys.executable,
        api_script,
        '-a', '0.0.0.0',  # 监听所有地址
        '-p', '9880',     # 端口
        '-d', 'cuda',     # 设备，如果没有GPU会自动降级到CPU
    ]
    
    print(f"执行命令: {' '.join(cmd)}")
    subprocess.run(cmd)
else:
    print(f"错误: 找不到 {api_script}")
    sys.exit(1)