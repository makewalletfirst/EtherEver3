#!/bin/bash

# ================= [설정] =================
TARGET_BLOCK=1920000
GETH_BIN="./build/bin/geth"
IPC_PATH="/root/my-fork-data/geth.ipc"
# ==========================================

echo "=================================================="
echo "모니터링 시작 (식별자 방식): 목표 $TARGET_BLOCK"
echo "IPC 경로: $IPC_PATH"
echo "=================================================="

while true; do
    # 1. IPC 파일 확인
    if [ ! -S "$IPC_PATH" ]; then
        echo "Waiting for Geth IPC..."
        sleep 3
        continue
    fi

    # 2. 자바스크립트로 "CheckBlock:블록번호" 형태로 출력하게 시킴
    # 이렇게 하면 다른 잡다한 로그(Welcome 메시지 등)와 구별 가능
    CMD="console.log('CheckBlock:' + eth.blockNumber)"
    
    # 명령어 실행 및 결과 파싱 (CheckBlock: 뒤의 숫자만 가져옴)
    CURRENT_BLOCK=$(echo "$CMD" | $GETH_BIN attach "$IPC_PATH" 2>/dev/null | grep "CheckBlock:" | awk -F: '{print $2}' | tr -d ' ')

    # 3. 숫자가 잘 받아졌는지 확인
    if [[ "$CURRENT_BLOCK" =~ ^[0-9]+$ ]]; then
        echo "✅ 현재: $CURRENT_BLOCK  /  목표: $TARGET_BLOCK"

        if [ "$CURRENT_BLOCK" -ge "$TARGET_BLOCK" ]; then
            echo ""
            echo "🛑 목표 도달! ($CURRENT_BLOCK) -> 종료합니다."
            pkill -SIGINT -f "geth"
            break
        fi
    else
        # 로딩 중이거나 엉뚱한 값이 왔을 때
        echo "⏳ 동기화 값 대기 중... (응답없음)"
    fi

    sleep 3
done

