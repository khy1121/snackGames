# build_web_optimized.ps1 - 최적화된 웹 빌드 스크립트 (Windows)
# 사용법: .\build_web_optimized.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== 스넥게임즈 최적화 웹 빌드 ===" -ForegroundColor Cyan

# 1. 이전 빌드 정리
Write-Host "[1/5] 이전 빌드 정리..." -ForegroundColor Yellow
if (Test-Path "build\web") {
    Remove-Item -Path "build\web" -Recurse -Force
}

# 2. Flutter 웹 빌드 (최적화 옵션)
Write-Host "[2/5] Flutter 웹 빌드 (--pwa-strategy=none)..." -ForegroundColor Yellow
flutter build web --release --pwa-strategy=none --dart2js-optimization=O4 --no-source-maps

if ($LASTEXITCODE -ne 0) {
    Write-Host "빌드 실패!" -ForegroundColor Red
    exit 1
}

# 3. 불필요한 canvaskit 변형 제거
Write-Host "[3/6] 불필요한 canvaskit 변형 제거..." -ForegroundColor Yellow

# chromium 전용 canvaskit 제거 (Safari에서 불필요)
if (Test-Path "build\web\canvaskit\chromium") {
    Remove-Item -Path "build\web\canvaskit\chromium" -Recurse -Force
    Write-Host "  -> chromium canvaskit 제거 완료" -ForegroundColor Gray
}

# skwasm 제거 (dart2js 빌드에서 불필요)
Get-ChildItem -Path "build\web\canvaskit" -Filter "skwasm*" -ErrorAction SilentlyContinue | Remove-Item -Force
Write-Host "  -> skwasm 파일 제거 완료" -ForegroundColor Gray

# 4. 중복 오디오 파일 제거 (web/audio, web/sfx가 build/web에 자동복사된 것)
# Dart 코드는 assets/assets/audio/ 경로 사용하므로 root-level은 불필요
Write-Host "[4/6] 중복 root-level audio/sfx 제거..." -ForegroundColor Yellow
if (Test-Path "build\web\audio") {
    $audioSize = (Get-ChildItem -Path "build\web\audio" -Recurse -File | Measure-Object -Property Length -Sum).Sum
    Remove-Item -Path "build\web\audio" -Recurse -Force
    Write-Host ("  -> audio/ 제거 완료 ({0:N2} MB 절약)" -f ($audioSize / 1MB)) -ForegroundColor Gray
}
if (Test-Path "build\web\sfx") {
    $sfxSize = (Get-ChildItem -Path "build\web\sfx" -Recurse -File | Measure-Object -Property Length -Sum).Sum
    Remove-Item -Path "build\web\sfx" -Recurse -Force
    Write-Host ("  -> sfx/ 제거 완료 ({0:N2} MB 절약)" -f ($sfxSize / 1MB)) -ForegroundColor Gray
}

# 5. flutter_service_worker.js 제거 확인
if (Test-Path "build\web\flutter_service_worker.js") {
    Write-Host "[5/6] flutter_service_worker.js 제거..." -ForegroundColor Yellow
    Remove-Item -Path "build\web\flutter_service_worker.js" -Force
} else {
    Write-Host "[5/6] flutter_service_worker.js 없음 (정상)" -ForegroundColor Green
}

# 5. 빌드 결과 분석
Write-Host "[6/6] 빌드 결과 분석..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=== 핵심 파일 크기 ===" -ForegroundColor Cyan

$mainJs = Get-Item "build\web\main.dart.js" -ErrorAction SilentlyContinue
if ($mainJs) {
    Write-Host ("  main.dart.js: {0:N2} MB" -f ($mainJs.Length / 1MB))
}

$canvaskit = Get-Item "build\web\canvaskit\canvaskit.wasm" -ErrorAction SilentlyContinue
if ($canvaskit) {
    Write-Host ("  canvaskit.wasm: {0:N2} MB" -f ($canvaskit.Length / 1MB))
}

Write-Host ""
Write-Host "=== 폴더별 크기 ===" -ForegroundColor Cyan

$totalSize = (Get-ChildItem -Path "build\web" -Recurse -File | Measure-Object -Property Length -Sum).Sum
Write-Host ("  전체: {0:N2} MB" -f ($totalSize / 1MB))

$assetsSize = (Get-ChildItem -Path "build\web\assets" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host ("  assets: {0:N2} MB" -f ($assetsSize / 1MB))

$canvaskitSize = (Get-ChildItem -Path "build\web\canvaskit" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host ("  canvaskit: {0:N2} MB" -f ($canvaskitSize / 1MB))

# root-level audio 확인
if (Test-Path "build\web\audio") {
    Write-Host "  [경고] root-level audio/ 폴더가 존재합니다!" -ForegroundColor Red
} else {
    Write-Host "  root-level audio/ 없음 (중복 제거됨)" -ForegroundColor Green
}

if (Test-Path "build\web\sfx") {
    Write-Host "  [경고] root-level sfx/ 폴더가 존재합니다!" -ForegroundColor Red
} else {
    Write-Host "  root-level sfx/ 없음 (중복 제거됨)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== 빌드 완료! ===" -ForegroundColor Green
Write-Host "flutter_service_worker.js 없음 (커스텀 sw.js 사용)"
Write-Host "배포: vercel --prod"
