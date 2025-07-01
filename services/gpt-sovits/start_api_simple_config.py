#!/usr/bin/env python3
"""
GPT-SoVITS API启动脚本 - 简化配置版本
使用更简单的配置，避免BERT模型依赖
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

# 切换到GPT-SoVITS目录
os.chdir(gpt_sovits_dir)

# 设置环境变量，使用英文模式避免BERT依赖
os.environ['PYTHONPATH'] = f"{gpt_sovits_dir}:{os.path.join(gpt_sovits_dir, 'GPT_SoVITS')}:{os.environ.get('PYTHONPATH', '')}"
os.environ['is_half'] = "True"  # 使用半精度

# 启动GPT-SoVITS API
print("启动GPT-SoVITS API服务（简化配置）...")
print(f"工作目录: {os.getcwd()}")

# 检查模型文件
sovits_model = os.path.join(gpt_sovits_dir, "GPT_SoVITS/pretrained_models/s2G488k.pth")
gpt_model = os.path.join(gpt_sovits_dir, "GPT_SoVITS/pretrained_models/s1bert25hz-2kh-longer-epoch=68e-step=50232.ckpt")

# 如果默认模型不存在，尝试使用下载的模型
if not os.path.exists(sovits_model):
    alt_sovits = os.path.join(current_dir, "../models/gpt-sovits/s2G2333k.pth")
    if os.path.exists(alt_sovits):
        sovits_model = alt_sovits

if not os.path.exists(gpt_model):
    alt_gpt = os.path.join(current_dir, "../models/gpt-sovits/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt")
    if os.path.exists(alt_gpt):
        gpt_model = alt_gpt

# 使用subprocess启动api_v2.py（可能更稳定）
api_script = os.path.join(gpt_sovits_dir, 'api_v2.py')
if not os.path.exists(api_script):
    api_script = os.path.join(gpt_sovits_dir, 'api.py')

if os.path.exists(api_script):
    cmd = [
        sys.executable,
        api_script,
        '-a', '0.0.0.0',  # 监听所有地址
        '-p', '9880',     # 端口
        '-d', 'cpu',      # 使用CPU避免GPU问题
        '-dr', 'False',   # 禁用参考音频
    ]
    
    # 如果找到模型文件，添加到参数
    if os.path.exists(sovits_model):
        cmd.extend(['-s', sovits_model])
    if os.path.exists(gpt_model):
        cmd.extend(['-g', gpt_model])
    
    print(f"执行命令: {' '.join(cmd)}")
    
    # 设置环境变量避免BERT错误
    env = os.environ.copy()
    env['TOKENIZERS_PARALLELISM'] = 'false'
    
    subprocess.run(cmd, env=env)
else:
    print(f"错误: 找不到API脚本")
    sys.exit(1)