#!/bin/bash

# 下载BERT模型脚本

echo "下载BERT模型..."

# 设置路径
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRETRAINED_DIR="$SCRIPT_DIR/GPT-SoVITS/GPT_SoVITS/pretrained_models"

# 创建目录
mkdir -p "$PRETRAINED_DIR"
cd "$PRETRAINED_DIR"

# 检查是否已存在
if [ -d "chinese-roberta-wwm-ext-large" ]; then
    echo "BERT模型已存在，跳过下载"
    exit 0
fi

# 使用git克隆模型
echo "从Hugging Face下载chinese-roberta-wwm-ext-large模型..."
git clone https://huggingface.co/hfl/chinese-roberta-wwm-ext-large

if [ $? -eq 0 ]; then
    echo "BERT模型下载完成"
else
    echo "下载失败，尝试使用wget下载关键文件..."
    
    # 创建目录
    mkdir -p chinese-roberta-wwm-ext-large
    cd chinese-roberta-wwm-ext-large
    
    # 下载必要的文件
    files=(
        "config.json"
        "pytorch_model.bin"
        "tokenizer_config.json"
        "vocab.txt"
    )
    
    base_url="https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/resolve/main"
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "下载 $file..."
            wget -c "$base_url/$file" -O "$file"
        fi
    done
fi

echo "BERT模型准备完成"