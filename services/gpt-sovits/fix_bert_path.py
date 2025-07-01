#!/usr/bin/env python3
"""
修复GPT-SoVITS的BERT路径问题
"""

import os
import sys

# 获取路径
current_dir = os.path.dirname(os.path.abspath(__file__))
gpt_sovits_dir = os.path.join(current_dir, 'GPT-SoVITS')

# 设置环境变量，使用在线模型
os.environ['bert_path'] = 'hfl/chinese-roberta-wwm-ext-large'

# 切换到GPT-SoVITS目录
os.chdir(gpt_sovits_dir)

# 设置Python路径
sys.path.insert(0, gpt_sovits_dir)
sys.path.insert(0, os.path.join(gpt_sovits_dir, 'GPT_SoVITS'))

# 启动API
api_script = os.path.join(gpt_sovits_dir, 'api.py')
if os.path.exists(api_script):
    # 使用exec运行api.py
    with open(api_script, 'r', encoding='utf-8') as f:
        api_code = f.read()
    
    # 修改代码中的bert_path
    api_code = api_code.replace(
        'bert_path = "GPT_SoVITS/pretrained_models/chinese-roberta-wwm-ext-large"',
        'bert_path = "hfl/chinese-roberta-wwm-ext-large"'
    )
    
    # 执行修改后的代码
    exec(api_code)
else:
    print("错误: 找不到api.py")
    sys.exit(1)