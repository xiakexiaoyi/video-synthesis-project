#!/bin/bash
cd "$(dirname "$0")"

# 检查是否有虚拟环境
if [ -d "GPT-SoVITS/venv" ]; then
    echo "激活虚拟环境..."
    source GPT-SoVITS/venv/bin/activate
fi

# 检查是否需要下载BERT模型
if [ ! -d "GPT-SoVITS/GPT_SoVITS/pretrained_models/chinese-roberta-wwm-ext-large" ]; then
    echo "BERT模型不存在，尝试下载..."
    if [ -f "download_bert_model.sh" ]; then
        bash download_bert_model.sh
    fi
fi

# 尝试不同的启动方式
echo "启动GPT-SoVITS API..."

# 方式1: 尝试完整API
if python3 start_api.py; then
    echo "API启动成功"
else
    echo "完整API启动失败，尝试包装器模式..."
    # 方式2: 使用包装器
    if [ -f "gpt_sovits_api_wrapper.py" ]; then
        python3 gpt_sovits_api_wrapper.py
    else
        echo "错误: 无法启动GPT-SoVITS服务"
        exit 1
    fi
fi