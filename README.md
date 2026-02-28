# 🍿 스넥게임즈 (SnackGames)

> **기다림을 게임으로 바꾸다 ✨**

짧은 시간에 즐기는 중독성 있는 퍼즐 게임들의 모음입니다.

**🌐 라이브 데모**: [https://snack-games.vercel.app](https://snack-games.vercel.app)

---

## 📱 게임 소개

### 🎲 합쳐라! 주사위 (Dice Merge)
주사위를 합쳐서 높은 점수를 획득하세요!
- 같은 숫자 3개를 인접하게 배치하면 합체
- ⭐ 3개를 합치면 💥 3x3 대폭발!
- 점수가 높아질수록 난이도 증가

### 🔢 배수의 법칙 (2048)
클래식 2048 게임
- 스와이프로 타일 이동
- 같은 숫자끼리 합치기
- 2048 타일 만들기 도전!

---

## ✨ 주요 기능

### 🎵 음악 플레이어 시스템 (v2.5.4 NEW!)
- **멜론/플로 스타일 플레이어**: 우상단 🎵 버튼으로 접근
- **프로그레스 바**: 재생 위치 표시 (00:00 ~ 03:30 형식)
- **플레이리스트 관리**: 토글 스위치로 곡 추가/제거
- **재생 컨트롤**: 재생, 일시정지, 이전곡, 다음곡
- **반복 모드**: 전체 반복, 한곡 반복, 반복 없음
- **셔플 모드**: 랜덤 재생
- **볼륨 조절**: 슬라이더로 세밀한 볼륨 조절
- **웹/PWA 지원**: HTML5 Audio API 사용

### 🎮 게임 시스템
- **일일 출석**: 매일 출석하고 보상 획득 (7일 연속 시 특별 보상!)
- **럭키 휠**: 포인트를 사용해 행운의 룰렛 돌리기
- **연속 플레이 보너스**: 게임을 연속으로 플레이하면 최대 3배 배율
- **업그레이드 시스템**: 6가지 타입으로 게임 능력 강화
  - 🎯 점수 배율
  - 💰 포인트 획득량
  - ⭐ 경험치 배율
  - 🎪 특수 타일 확률
  - ❤️ 생존 능력
  - 🍀 행운 확률

### 🎬 애니메이션 시스템
- **주사위 숫자별 고유 애니메이션**
  - 1: 부드러운 페이드인 (easeOutQuad)
  - 2: 좌우 흔들림 (wobble)
  - 3: 180도 회전 + 탄력 효과
  - 4: 바운스 효과
  - 5: 파동 효과 + 발광
  - 6: 540도 강력한 스핀 + 발광 (별 전조!)
  - ⭐: 720도 회전 + 무지개 펄스
- **병합 애니메이션**: 주사위가 목표 위치로 빨려들어가는 효과
- **점수 팝업**: 획득 점수가 위로 떠오르며 커지는 효과
- **콤보 표시**: 2개 이상 병합 시 "Nx COMBO!" 배지
- **시각 효과**: 폭발 파티클, 충격파, 번개 (10콤보)


### 🏆 진행 시스템
- **레벨 시스템**: 게임을 플레이하며 경험치 획득 및 레벨업
- **랭크 시스템**: 누적 포인트에 따른 등급 상승
- **데일리 미션**: 매일 새로운 미션 도전
- **도전 과제**: 다양한 업적 달성

### 🎨 UI/UX
- **글래스모피즘 디자인**: 투명하고 모던한 카드 효과
- **부드러운 애니메이션**: 페이지 전환 페이드 효과
- **3색 그라데이션 배경**: 시각적 깊이감
- **반응형 인터랙션**: 터치 피드백 및 스케일 애니메이션
- **PWA 지원**: 모바일 앱처럼 설치 가능
  - 오프라인 플레이 지원
  - 자동 업데이트 알림
  - 홈 화면 추가 기능

---

## 🛠️ 기술 스택

| 분류 | 기술 |
|------|------|
| **Framework** | Flutter 3.38.8 |
| **Language** | Dart 3.10.7 |
| **State Management** | StatefulWidget, ChangeNotifier |
| **Storage** | SharedPreferences |
| **Audio** | HTML5 Audio API (Web), audioplayers (Mobile) |
| **Architecture** | Service Pattern |
| **PWA** | Service Worker v2.5.4 |
| **Deployment** | Vercel (Auto Deploy) |
| **Version Control** | Git/GitHub |

---

## 📂 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── home/
│   └── home_page.dart           # 홈 화면 + 네비게이션
├── dice/                        # 합쳐라! 주사위
│   ├── dice_game_page.dart      # 게임 로직
│   ├── dice_board.dart          # 게임 보드
│   ├── dice_widget.dart         # 주사위 위젯 + 애니메이션
│   ├── dice_effects.dart        # VFX 시스템
│   └── dice_theme.dart          # 테마 설정
├── game/                        # 2048 게임
│   ├── game_page.dart
│   ├── game_board.dart
│   ├── tile_widget.dart
│   └── game_theme.dart
├── lucky_wheel/                 # 럭키 휠
│   └── lucky_wheel_page.dart
├── shop/                        # 상점 및 업그레이드
│   ├── shop_page.dart
│   └── upgrade_page.dart
├── profile/                     # 프로필
│   └── profile_page.dart
├── challenge/                   # 도전 과제
│   └── challenge_page.dart
├── settings/                    # 설정
│   └── settings_page.dart
├── services/                    # 비즈니스 로직
│   ├── game_data_service.dart
│   ├── daily_mission_service.dart
│   ├── daily_attendance_service.dart
│   ├── lucky_wheel_service.dart
│   ├── upgrade_service.dart
│   ├── challenge_service.dart
│   ├── achievement_service.dart
│   ├── vibration_service.dart       # 진동 피드백
│   ├── pwa_install_service.dart     # PWA 설치
│   ├── background_music_service.dart # 배경음악 서비스
│   ├── music_player_service.dart    # 음악 플레이어 상태 관리
│   ├── web_audio_service.dart       # 웹 오디오 (HTML5)
│   └── web_audio_stub.dart          # 네이티브 스텁
└── widgets/                     # 공통 위젯
    ├── glassmorphism_card.dart
    ├── animated_counter.dart
    ├── particle_effect.dart
    ├── music_player_popup.dart      # 음악 플레이어 팝업
    └── theme_shop_dialog.dart

web/
├── index.html                   # PWA 메인 페이지
├── manifest.json                # PWA 매니페스트
├── sw.js                        # Service Worker
├── vercel.json                  # Vercel 배포 설정
└── audio/                       # 배경음악 파일들
    ├── mainLogo.mp3
    ├── Breaktime Hush Duo.mp3
    ├── Pocket Groove Snack.mp3
    └── ...

assets/
├── audio/                       # 원본 오디오 파일
└── images/                      # 이미지 리소스
```

---

## 🚀 시작하기

### 필수 요구사항
- Flutter SDK 3.0 이상
- Dart 3.0 이상
- Android Studio / VS Code

### 설치 및 실행

```bash
# 저장소 클론
git clone https://github.com/khy1121/snackGames.git

# 디렉토리 이동
cd game2048

# 의존성 설치
flutter pub get

# 앱 실행 (디버그 모드)
flutter run

# 웹에서 실행
flutter run -d chrome
```

---

## 📦 빌드 및 배포

### 웹 빌드 (PWA)

```bash
# 릴리즈 빌드
flutter build web --release

# 오디오 파일 복사 (중요!)
# build/web/audio/ 폴더에 음악 파일들이 포함되어야 함
cp -r assets/audio/* build/web/audio/

# 또는 PowerShell에서
Copy-Item -Recurse assets/audio/* build/web/audio/
```

### Android APK 빌드

```bash
# 디버그 APK
flutter build apk

# 릴리즈 APK
flutter build apk --release

# App Bundle (Play Store용)
flutter build appbundle --release
```

### iOS 빌드 (macOS only)

```bash
flutter build ios --release
```

### Vercel 자동 배포

1. GitHub에 푸시하면 Vercel에서 자동 배포
2. `vercel.json` 설정:
   - Build Command: `flutter build web --release --web-renderer canvaskit`
   - Output Directory: `build/web`

---

## 📝 릴리즈 노트
현재 버전은 2.7.4 입니다

### v2.5.1 (2026-02-05) 🔗 음악 동기화 업데이트
**새로운 기능**
- 🔗 **플레이리스트와 배경음악 완전 동기화**
  - MusicPlayerService를 중앙 컨트롤러로 통합
  - 음소거 버튼과 플레이리스트 상태 실시간 동기화
- 💾 **플레이리스트 저장 기능**
  - SharedPreferences로 플레이리스트 영구 저장
  - 앱 재시작 시 이전 플레이리스트 복원
  - 현재 재생 중인 트랙 위치도 저장
- ▶️ **자동 다음 곡 재생**
  - 트랙 종료 시 자동으로 다음 곡 재생
  - 반복 모드에 따른 재생 로직 적용
- 🔁 **반복 모드 개선**
  - 한곡 반복: 같은 곡 무한 재생
  - 전체 반복: 플레이리스트 순환
  - 반복 없음: 마지막 곡 후 정지
- 🔀 **셔플 기능**: 랜덤으로 다음 곡 선택

---

### v2.4.3 (2026-02-04) 🎵 음악 플레이어 대규모 업데이트
**새로운 기능**
- 🎵 **멜론/플로 스타일 음악 플레이어** 추가
  - 우상단 헤더에 플레이리스트 버튼 (🎵)
  - 상점처럼 팝업으로 열리고 배경 터치 시 닫힘
- 🎼 **플레이리스트 관리**
  - 8개 트랙 지원 (mainLogo, Breaktime Hush Duo, Pocket Groove Snack 등)
  - 곡별 추가/제거 기능
  - 현재 재생 중인 곡 하이라이트
- ▶️ **재생 컨트롤**
  - 재생/일시정지
  - 이전곡/다음곡
  - 프로그레스 바 (현재 위치/전체 길이)
- 🔁 **반복 모드**
  - 전체 반복 (🔁)
  - 한곡 반복 (🔂)
  - 반복 없음 (➡️)
- 🔀 **셔플 모드**: 랜덤 재생
- 🔊 **볼륨 조절**: 슬라이더로 0~100% 조절

**수정사항**
- 웹/PWA에서 HTML5 Audio API 사용으로 안정적인 재생
- 오디오 파일 경로 문제 해결

---

### v2.4.2 (2026-02-04)
**수정사항**
- 🔊 오디오 파일을 `build/web/audio/`에 정적 파일로 배치
- 📁 `.gitignore` 무시 규칙 우회하여 오디오 파일 강제 추가
- 🛠️ Vercel 배포 시 오디오 파일 누락 문제 해결

---

### v2.4.1 (2026-02-04)
**수정사항**
- 🔄 Vercel rewrite 규칙에서 `assets/` 및 `audio/` 경로 제외
- 🎵 오디오 파일 직접 접근 허용
- 🌐 SPA 라우팅 복원

---

### v2.4.0 (2026-02-04)
**수정사항**
- 📋 `vercel.json`에 오디오 MIME 타입 헤더 추가 (`audio/mpeg`)
- 🔊 `Accept-Ranges` 헤더 추가로 스트리밍 지원
- ❌ rewrite 규칙 임시 제거 (오디오 파일 접근 문제)

---

### v2.3.9 (2026-02-04)
**수정사항**
- 🔍 웹 오디오 에러 디버깅 정보 추가
- 📊 `Audio src`, `readyState`, `error code` 로깅
- 🔄 오디오 로드 상태 확인 후 재생 시도

---

### v2.3.8 (2026-02-04)
**수정사항**
- 🛠️ `AudioPlayer` lazy initialization 적용
- 🌐 웹에서 `AudioPlayer` 인스턴스 생성 방지
- ❌ `MissingPluginException` 에러 해결

---

### v2.3.7 (2026-02-04)
**새로운 기능**
- 🌐 **웹/PWA 배경음악 지원** (`WebAudioService`)
- 📱 HTML5 `AudioElement` 사용
- 🔄 조건부 import로 플랫폼별 처리
- 👆 사용자 상호작용 시 음악 자동 재생 (브라우저 정책 준수)
- 🎵 음악 토글 버튼 웹에서도 표시

---

### v2.3.6 (2026-02-04)
**수정사항**
- 🔇 웹에서 `audioplayers` 미지원으로 음악 기능 임시 비활성화
- 🛡️ `BackgroundMusicService.initialize()`에 `kIsWeb` 체크 추가
- 🙈 웹에서 음악 토글 버튼 숨김
- 🗑️ 불필요한 `audioplayers_web` CDN 스크립트 제거

---

### v2.3.5 (2026-02-04)
**새로운 기능**
- 🎵 **배경음악 시스템** 추가 (`BackgroundMusicService`)
- 🎧 `audioplayers` 패키지 연동
- 🔘 헤더에 음악 토글 버튼 추가
- 📱 Android `VIBRATE`, `INTERNET` 권한 추가

**수정사항**
- ♾️ Service Worker 무한 새로고침 루프 수정
- 🔧 `GestureDetector` → `Listener` 변경 (이벤트 캡처 개선)
- 🐛 컴파일 에러 다수 수정 (unused imports, duplicate else 등)

---

### v2.3.4 (2026-02-04)
**수정사항**
- 📳 `VibrationService` null 안전성 강화
- 🔧 `dice_board.dart` unused variable 제거
- 🐛 `lucky_wheel_page.dart` 빌드 에러 수정

---

### v2.3.0 ~ v2.3.3 (2026-02-03 ~ 04)
**수정사항**
- 🔄 PWA Service Worker 캐시 버전 관리 개선
- 🎨 UI 미세 조정
- 🐛 다양한 버그 수정

---

### v2.2.0 (2026-02-03)
**새로운 기능**
- 📳 **진동 피드백 시스템** (6가지 패턴)
- 🌐 **PWA 업데이트 알림** 토스트
- 🔔 Service Worker 자동 업데이트

---

### v2.1.0 (2026-02-02)
**새로운 기능**
- 🎨 주사위 숫자별 고유 애니메이션 (7종)
- 🌀 병합 시 빨려들어가는 애니메이션
- 💰 점수 팝업 효과 (위로 떠오름)
- 🔥 콤보 표시 시스템
- ⚡ 폭발 파티클, 충격파, 번개 효과

---

### v2.0.0 (2026-02-01)
**새로운 기능**
- 🎮 일일 출석 시스템
- 🎰 럭키 휠 기능
- 🔄 연속 플레이 보너스 시스템
- ⬆️ 업그레이드 시스템 (6가지 타입)
- ✨ 글래스모피즘 UI 디자인

---

### v1.0.0 (2026-01-15) 🎉 최초 릴리즈
**새로운 기능**
- 🎲 Dice Merge 게임 출시
- 🔢 2048 게임 출시
- 🏆 레벨 및 랭크 시스템
- 📋 데일리 미션
- 🛍️ 상점 기능

---

## 🎯 게임 플레이 팁

### 합쳐라! 주사위
1. 같은 숫자 3개가 인접하면 **마지막 드롭 위치**에서 합쳐집니다
2. ⭐(별) 3개를 합치면 3x3 영역이 폭발합니다
3. 보드를 꽉 채우지 않도록 공간 관리가 중요합니다
4. 높은 숫자일수록 더 많은 점수를 획득합니다
5. **주사위 6**은 별이 될 수 있는 특별한 주사위입니다!
6. 각 숫자마다 고유한 등장 애니메이션이 있습니다

### 배수의 법칙 (2048)
1. 스와이프로 모든 타일을 한 방향으로 이동
2. 같은 숫자끼리 합쳐져 두 배가 됩니다
3. 큰 숫자는 한쪽 모서리에 고정하는 전략 추천
4. 항상 다음 타일이 생길 공간을 확보하세요

---

## 🔧 성능 최적화

- **Fire-and-Forget 패턴**: 데이터 저장 시 블로킹 제거
- **캐시된 데이터**: 불필요한 서비스 호출 감소
- **RepaintBoundary**: 렌더링 최적화
- **Lazy Loading**: 필요할 때만 위젯 로드
- **애니메이션 최적화**: Canvas 기반 커스텀 애니메이션, 30fps 제한
- **Service Worker 캐싱**: 오프라인 지원 및 빠른 로딩

---

## 🤝 기여하기

버그 리포트, 기능 제안, Pull Request는 언제나 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 라이선스

This project is licensed under the MIT License.

---

## 📧 연락처

- **GitHub**: [https://github.com/khy1121](https://github.com/khy1121)
- **프로젝트 링크**: [https://github.com/khy1121/snackGames](https://github.com/khy1121/snackGames)
- **라이브 데모**: [https://snack-games.vercel.app](https://snack-games.vercel.app)

---

**즐거운 게임 되세요! 🎮🍿✨**
