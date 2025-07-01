#!/bin/bash
cd "$(dirname "$0")"
source MuseTalk/venv/bin/activate
export PYTHONPATH="$PWD/MuseTalk:$PYTHONPATH"
python start_api_simple.py