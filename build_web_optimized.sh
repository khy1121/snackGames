#!/bin/bash
# build_web_optimized.sh - 최적화된 웹 빌드 스크립트
# 사용법: bash build_web_optimized.sh

set -e

echo "=== 스넥게임즈 최적화 웹 빌드 ==="

# 1. 이전 빌드 정리
echo "[1/5] 이전 빌드 정리..."
rm -rf build/web

# 2. Flutter 웹 빌드 (최적화 옵션)
echo "[2/5] Flutter 웹 빌드 (--pwa-strategy=none)..."
flutter build web \
  --release \
  --pwa-strategy=none \
  --dart2js-optimization=O4 \
  --no-source-maps

# 3. 불필요한 canvaskit 변형 제거 (iOS Safari는 기본 canvaskit만 사용)
echo "[3/5] 불필요한 canvaskit 변형 제거..."
# chromium 전용 canvaskit 제거 (Safari에서 불필요)
rm -rf build/web/canvaskit/chromium
# skwasm 제거 (dart2js 빌드에서 불필요)
rm -f build/web/canvaskit/skwasm*

echo "  -> chromium canvaskit 제거 완료"
echo "  -> skwasm 제거 완료"

# 4. flutter_service_worker.js 제거 확인 (--pwa-strategy=none이면 생성 안됨)
if [ -f "build/web/flutter_service_worker.js" ]; then
  echo "[4/5] flutter_service_worker.js 제거..."
  rm -f build/web/flutter_service_worker.js
else
  echo "[4/5] flutter_service_worker.js 없음 (정상)"
fi

# 5. 빌드 결과 분석
echo "[5/5] 빌드 결과 분석..."
echo ""
echo "=== 핵심 파일 크기 ==="
if [ -f "build/web/main.dart.js" ]; then
  echo "  main.dart.js: $(du -h build/web/main.dart.js | cut -f1)"
fi
if [ -f "build/web/canvaskit/canvaskit.wasm" ]; then
  echo "  canvaskit.wasm: $(du -h build/web/canvaskit/canvaskit.wasm | cut -f1)"
fi

echo ""
echo "=== 폴더별 크기 ==="
echo "  전체: $(du -sh build/web | cut -f1)"
echo "  assets: $(du -sh build/web/assets 2>/dev/null | cut -f1 || echo '0')"
echo "  canvaskit: $(du -sh build/web/canvaskit 2>/dev/null | cut -f1 || echo '0')"

echo ""
echo "=== 빌드 완료! ==="
echo "root-level audio/ 폴더 없음 (중복 제거됨)"
echo "flutter_service_worker.js 없음 (커스텀 sw.js 사용)"
echo ""
echo "배포: vercel --prod"
