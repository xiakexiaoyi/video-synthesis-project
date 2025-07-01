#!/usr/bin/env python3
"""
GPT-SoVITS API启动脚本
启动GPT-SoVITS自带的API服务
"""

import os
import sys
import subprocess

# 获取路径
current_dir = os.path.dirname(os.path.abspath(__file__))
gpt_sovits_dir = os.path.join(current_dir, 'GPT-SoVITS')

# 检查GPT-SoVITS目录
if not os.path.exists(gpt_sovits_dir):
    print(f"错误: GPT-SoVITS目录不存在: {gpt_sovits_dir}")
    sys.exit(1)

# 检查api.py是否存在
api_path = os.path.join(gpt_sovits_dir, 'api.py')
if not os.path.exists(api_path):
    print(f"错误: api.py不存在: {api_path}")
    sys.exit(1)

# 设置环境变量
env = os.environ.copy()
env['PYTHONPATH'] = gpt_sovits_dir

# 启动参数
args = [
    sys.executable,
    api_path,
    '-a', '0.0.0.0',  # 监听所有地址
    '-p', '9880',     # 端口
    '-c', 'GPT_SoVITS/configs/tts_infer.yaml'  # 配置文件
]

print(f"启动GPT-SoVITS API服务...")
print(f"命令: {' '.join(args)}")
print(f"工作目录: {gpt_sovits_dir}")

# 切换到GPT-SoVITS目录并启动
os.chdir(gpt_sovits_dir)
subprocess.run(args, env=env)