# 📱 SnapGames (스낵게임즈) — 프로젝트 분석 문서

> 작성일: 2026-03-03  
> 패키지명: `dice_merge_master`  
> 버전: `2.7.4+1`  
> 플랫폼: Flutter (Web, Android, iOS, Windows, Linux, macOS)

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 앱 이름 | 스낵게임즈 (SnapGames) |
| 슬로건 | "기다림을 게임으로 바꾸다 — 짧게, 가볍게, 계속하게" |
| 패키지 | `dice_merge_master` |
| 버전 | 2.7.4+1 |
| Flutter SDK | ^3.10.7 |
| 빌드 대상 | Web (Vercel), Android, iOS |

스낵게임즈는 짧은 시간 동안 즐길 수 있는 캐주얼 미니게임 컬렉션 앱으로, **주사위 합치기**를 메인 게임으로 하고 여러 미니게임을 서브 콘텐츠로 제공합니다.

---

## 2. 아키텍처 구조

```
lib/
├── main.dart               # 앱 진입점, 서비스 초기화
├── home/                   # 홈 화면 (게임 허브)
├── game/                   # 2048 게임
├── dice/                   # 주사위 합치기 게임 (메인)
├── slot_ball/              # 슬롯 볼 게임
├── block_puzzle/           # 블록 블리츠 게임
├── microgames/             # 마이크로게임 러시 (12종)
├── challenge/              # 도전과제 페이지
├── leaderboard/            # 리더보드 페이지
├── lucky_wheel/            # 럭키 휠 (룰렛)
├── profile/                # 유저 프로필
├── shop/                   # 상점 & 업그레이드
├── settings/               # 설정 페이지
├── services/               # 비즈니스 로직 서비스 레이어
└── widgets/                # 공통 위젯
```

### 서비스 레이어 (초기화 구조)

`main()` 에서 `Future.wait()`로 서비스들을 **병렬 초기화**하여 앱 실행 속도를 최적화합니다.

```
병렬 초기화:
  ├── GameDataService        — 점수/플레이 기록
  ├── DailyMissionService    — 일일 미션
  ├── AchievementService     — 업적
  ├── ChallengeService       — 도전과제/레벨링
  ├── SettingsService        — 앱 설정
  ├── VibrationService       — 진동 피드백
  └── LeaderboardService     — 리더보드

순차 초기화:
  └── BackgroundMusicService — 배경음악 (Settings 의존)
```

---

## 3. 게임 목록

### 3.1 🎲 합쳐라! 주사위 (메인 게임)
- **경로**: `lib/dice/`
- **규칙**: 빈 칸에 주사위 배치 → 같은 숫자 3개 인접 시 합체 → ⭐×3 = 💥 3×3 대폭발
- **주요 컴포넌트**:
  - `DiceMergeBoard` — 게임 보드 로직
  - `Dice` 모델 — 일반(normal) / 매직(magic) 타입
  - `DiceGamePage` — UI 및 VFX (StreamController 기반 이벤트)
  - `DiceTutorialPage` — 신규 유저 튜토리얼
- **특징**:
  - 콤보 연속 합체 시 Lightning 이펙트
  - ScreenShake 진동 피드백
  - 업그레이드 시스템 연동 (럭키 다이스, 매직 찬스 등)
  - 이어하기(Resume) 기능

### 3.2 🔢 배수의 법칙 (2048)
- **경로**: `lib/game/`
- **규칙**: 스와이프로 타일 이동 → 같은 숫자 합치기 → 2048 타일 달성
- **주요 컴포넌트**:
  - `GameBoard` — 4×4 보드, 이동/합치기 로직, Undo 지원
  - `GamePage` — 스와이프 감지 UI
  - `TileWidget` — 타일 애니메이션
  - `GameTheme` — 테마 색상
- **특징**:
  - 이어하기(Resume JSON 직렬화)
  - Undo 기능 (업그레이드로 해금)

### 3.3 🎱 슬롯 볼
- **경로**: `lib/slot_ball/`
- **규칙**: 아래서 위로 드래그해 공 발사 → 점수 구역에 정지
- **주요 컴포넌트**:
  - `SlotBall` — 공 물리(위치, 속도, 반경)
  - `ScoreZone` — Y축 비율 기반 점수 구역
  - `Peg` — 범퍼/핀 장애물
  - `SlotBallEngine` — 물리 엔진
- **특징**: 10개의 공, 공끼리 충돌 물리, 전략적 배치

### 3.4 🧩 블록 블리츠
- **경로**: `lib/block_puzzle/`
- **규칙**: 3개의 블록을 그리드에 배치 → 가로/세로 줄 완성 시 클리어
- **주요 컴포넌트**:
  - `BlockPuzzleEngine` — 블록 생성 및 배치 로직
  - `BlockPuzzleGamePage` — UI
- **특징**: 연속 클리어 콤보 점수, 공간 관리 전략

### 3.5 ⚡ 마이크로게임 러시 (WarioWare 오마주)
- **경로**: `lib/microgames/`
- **규칙**: 빠르게 전환되는 12종 초단시간 미니게임 연속 클리어
- **게임 목록** (12종):

| 게임 | 파일 | 설명 |
|------|------|------|
| 파리 잡기 | `fly_catcher_game.dart` | 날아다니는 파리 탭 |
| 풍선 터뜨리기 | `balloon_pop_game.dart` | 풍선 탭해서 터뜨리기 |
| 버블 랩 | `bubble_wrap_game.dart` | 버블 포장지 터뜨리기 |
| 신호등 | `traffic_light_game.dart` | 초록불에 멈추기/출발 |
| 노크 | `door_knock_game.dart` | 문 두드리기 리듬 |
| 커피 붓기 | `coffee_pour_game.dart` | 컵에 정확히 붓기 |
| 공 굴리기 | `ball_roll_game.dart` | 기울기로 공 굴리기 |
| 주사위 흔들기 | `dice_shake_game.dart` | 기기 흔들어 주사위 |
| 색깔 맞추기 | `color_match_game.dart` | 색상 매칭 |
| 카운트다운 탭 | `countdown_tap_game.dart` | 타이밍 맞춰 탭 |
| 이상한 거 찾기 | `odd_one_out_game.dart` | 다른 것 찾기 |
| 건드리지 마 | `dont_touch_game.dart` | 장애물 회피 |

- **게임 상태**: `intro → countdown → speedUp → transition → playing → result → gameOver`
- **특징**: 점수 상승 시 속도 증가, 컨페티/쉐이크 이펙트

---

## 4. 서비스 레이어 상세

### 4.1 GameDataService
- SharedPreferences 기반 영구 저장
- 관리 데이터: 최고 점수, 오늘 점수, 총 플레이 시간, 포인트, 소유 테마, 총 게임 수
- 2048/주사위 이어하기 JSON 직렬화

### 4.2 AchievementService (업적)
- 랭크 시스템: Bronze → Silver → Gold → Platinum → Diamond
- Achievement 모델: id, icon, title, description, targetValue, currentValue, progress
- 포인트 기반 랭크 승급

### 4.3 ChallengeService (도전과제/레벨링)
- 15레벨 진행 시스템 (레벨명 예: 초보자, 입문자 ...)
- XP 기반 레벨업
- 레벨별 챌린지 및 포인트 보상

### 4.4 UpgradeService (업그레이드 상점)
업그레이드 타입 6종:

| 타입 | 설명 |
|------|------|
| `scoreMultiplier` | 점수 배율 증가 |
| `luckyDice` | 높은 숫자 주사위 출현율 증가 |
| `magicChance` | 매직 다이스 생성 확률 증가 |
| `pointsBoost` | 포인트 획득 배율 증가 |
| `startingBonus` | 시작 보너스 점수 |
| `extraLives` | 추가 생명 (실수 1회 되돌리기) |

- 레벨별 비용: `baseCost × (costMultiplier × level)` 공식
- `requiredLevel`로 업그레이드 해금 조건 관리

### 4.5 DailyMissionService (일일 미션)
- 게임별 일일 미션 템플릿
- 매일 자동 갱신
- 미션 완료 시 포인트 보상

### 4.6 BackgroundMusicService / SfxService
- `audioplayers` 패키지 기반
- Web/Mobile 분기 처리 (stub 패턴)
- 배경음악 8트랙, 효과음(SFX) 별도 관리

### 4.7 VibrationService
- `vibration` 패키지 기반
- Web/Mobile/Stub 플랫폼별 분기 (`vibration_service_web.dart`, `vibration_service_mobile.dart`, `vibration_service_stub.dart`)
- `sensors_plus`를 통한 기기 흔들기 감지

### 4.8 기타 서비스
| 서비스 | 역할 |
|--------|------|
| `LeaderboardService` | 로컬 리더보드 점수 관리 |
| `LuckyWheelService` | 룰렛 추첨 로직 |
| `MascotService` | 마스코트 캐릭터 상태 |
| `SessionComboService` | 연속 플레이 콤보 보너스 |
| `RewardDropService` | 랜덤 보상 드롭 |
| `DailyAttendanceService` | 출석 체크 |
| `PwaInstallService` | PWA 설치 프롬프트 (Web) |
| `SettingsService` | 텍스트 스케일, 사운드 on/off 등 |
| `MusicPlayerService` | 인게임 음악 재생 팝업 |

---

## 5. 공통 위젯

| 위젯 | 설명 |
|------|------|
| `GlassmorphismCard` | 반투명 글래스모피즘 카드 |
| `AnimatedCounter` | 숫자 증가 애니메이션 카운터 |
| `ChallengeToast` | 도전과제 달성 토스트 알림 |
| `ParticleEffect` | 파티클 이펙트 |
| `ThemeShopDialog` | 테마 구매 다이얼로그 |
| `MusicPlayerPopup` | 음악 플레이어 팝업 |

---

## 6. 디자인 시스템 (테마)

| 색상 역할 | 색상값 | 설명 |
|-----------|--------|------|
| Primary | `#2E5940` | Forest Green |
| Secondary | `#8DA399` | Sage Green |
| Surface / Background | `#F7F5EC` | Warm Beige |

- Material 3 (`useMaterial3: true`) 기반
- 시스템 폰트 폴백 사용
- `SettingsService.textScale` ValueListenable로 텍스트 크기 동적 조절

---

## 7. 의존성 패키지

### 런타임 의존성
| 패키지 | 버전 | 용도 |
|--------|------|------|
| `shared_preferences` | ^2.2.2 | 로컬 데이터 영구 저장 |
| `audioplayers` | ^6.1.0 | 배경음악 / 효과음 재생 |
| `vibration` | ^2.0.0 | 햅틱 피드백 |
| `sensors_plus` | ^5.0.1 | 가속도계(흔들기 감지) |
| `cupertino_icons` | ^1.0.8 | iOS 스타일 아이콘 |

### 개발 의존성
| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter_lints` | ^6.0.0 | 코드 린트 규칙 |

---

## 8. 에셋 구조

```
assets/
├── audio/                          # 배경음악 (8트랙)
│   ├── main_logo.mp3
│   ├── breaktime_hush_duo.mp3
│   ├── breaktime_hush_duov2.mp3
│   ├── pocket_groove_snack.mp3
│   ├── soft_breaktime_glow.mp3
│   ├── subway_home_one_breath.mp3
│   ├── one_more_round.mp3
│   └── one_more_round_2.mp3
└── sfx/
    └── dicemerge/
        └── dice_pop/               # 주사위 효과음
```

---

## 9. 빌드 & 배포

### Web (Vercel)
- `vercel.json` 설정 파일 포함
- `build_web_optimized.ps1` / `build_web_optimized.sh` 빌드 스크립트 제공
- PWA 지원 (`sw.js`, `manifest.json`, `flutter_bootstrap.js`)
- `PwaInstallService`로 설치 프롬프트 관리

### Android
- `build.gradle.kts` (Kotlin DSL)
- `codemagic.yaml` — CI/CD 설정 (Codemagic)

### 배포 설정
| 파일 | 역할 |
|------|------|
| `vercel.json` | Vercel Web 배포 라우팅 설정 |
| `codemagic.yaml` | 앱 자동 빌드/배포 파이프라인 |
| `build_web_optimized.ps1` | Windows용 최적화 웹 빌드 |

---

## 10. 주요 패턴 & 설계 특징

1. **플랫폼 분기 패턴**: `sfx_service_stub.dart` + 조건부 import로 Web/Mobile 코드 분기
2. **병렬 서비스 초기화**: `Future.wait()` 사용으로 앱 시작 속도 최적화
3. **이벤트 기반 VFX**: `StreamController.broadcast()`로 이펙트 이벤트 분리
4. **ValueListenable 패턴**: `SettingsService.textScale` 실시간 반응형 UI
5. **JSON 직렬화**: 모든 게임 상태를 JSON으로 직렬화해 이어하기 구현
6. **서비스 싱글턴**: `static SharedPreferences? _prefs` 패턴으로 공유 저장소 관리

---

## 11. 파일 수 요약

| 디렉토리 | 파일 수 | 역할 |
|----------|---------|------|
| `lib/services/` | 21개 | 비즈니스 로직 |
| `lib/microgames/games/` | 12개 | 마이크로게임 |
| `lib/dice/` | 6개 | 주사위 게임 |
| `lib/game/` | 4개 | 2048 게임 |
| `lib/widgets/` | 6개 | 공통 UI 컴포넌트 |
| `lib/block_puzzle/` | 2개 | 블록 퍼즐 |
| `lib/slot_ball/` | 2개 | 슬롯 볼 |

---

*이 문서는 `game2048` 프로젝트 코드베이스를 자동 분석하여 생성되었습니다.*

