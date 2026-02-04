# 🍿 스낵게임즈 (SnapBox Games)

> **기다림을 게임으로 바꾸다 ✨**

짧은 시간에 즐기는 중독성 있는 퍼즐 게임들의 모음입니다.

## 📱 게임 소개

### 🎲 Dice Merge
주사위를 합쳐서 높은 점수를 획득하세요!
- 같은 숫자 3개를 인접하게 배치하면 합체
- ⭐ 3개를 합치면 💥 3x3 대폭발!
- 점수가 높아질수록 난이도 증가

### 🔢 2048
클래식 2048 게임
- 스와이프로 타일 이동
- 같은 숫자끼리 합치기
- 2048 타일 만들기 도전!

## ✨ 주요 기능

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

### � 애니메이션 시스템
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

### 📳 진동 피드백 시스템
- **매직 폭발**: 강력한 explosion 패턴
- **콤보 병합**: 리듬감 있는 combo 패턴
- **별 생성**: 중간 강도의 heavy 패턴
- **일반 병합**: 부드러운 medium 패턴
- **빈 칸 탭**: 가벼운 light 패턴
- **게임 오버**: 경고 error 패턴

### �🏆 진행 시스템
- **레벨 시스템**: 게임을 플레이하며 경험치 획득 및 레벨업
- **랭크 시스템**: 누적 포인트에 따른 등급 상승
- **데일리 미션**: 매일 새로운 미션 도전
- **도전 과제**: 다양한 업적 달성

### 🎨 UI/UX
- **글래스모피즘 디자인**: 투명하고 모던한 카드 효과
- **부드러운 애니메이션**: 
  - 주사위 숫자별 고유 애니메이션 (800ms)
  - 병합 애니메이션 (1000ms)
  - 페이지 전환 페이드 효과
  - 숫자 카운팅 애니메이션
- **3색 그라데이션 배경**: 시각적 깊이감
- **반응형 인터랙션**: 터치 피드백 및 스케일 애니메이션
- **PWA 지원**: 모바일 앱처럼 설치 가능
  - 오프라인 플레이 지원
  - 자동 업데이트 알림
  - 홈 화면 추가 기능

## 🛠️ 기술 스택

- **Framework**: Flutter 3.38.8
- **Language**: Dart 3.10.7
- **State Management**: StatefulWidget
- **Storage**: SharedPreferences
- **Architecture**: Service Pattern
- **PWA**: Service Worker v2.1.0
- **Deployment**: Vercel
- **Version Control**: Git/GitHub

## 📂 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── home/                     # 홈 화면
│   └── home_page.dart       # 게임 로직 + 마지막 드롭 위치 병합
│   ├── dice_widget.dart      # 숫자별 고유 애니메이션
│   ├── dice_effects.dart     # VFX 시스템
│   └── dice_themege.dart
│   ├── dice_board.dart
│   ├── dice_widget.dart
│   └── dice_effects.dart
├── game/                     # 2048 게임
│   └── game_page.dart
├── lucky_wheel/              # 럭키 휠
│   └── lucky_wheel_page.dart
├── shop/                     # 상점 및 업그레이드
│   ├── shop_page.dart
│   └── upgrade_page.dart
├── profile/                  # 프로필
│   └── profile_page.dart
├── challenge/                # 도전 과제
│   └── challenge_page.dart
├── settings/                 # 설정
│   └── settings_page.dart
├── services/                 # 비즈니스 로직
│   ├── game_data_service.dart
│   ├── daily_mission_service.dart
│   ├── daily_attendance_service.dart
│   ├── lucky_wheel_service.dart
│   ├── upgrade_service.dart
│   ├── challenge_service.dart
│   ├── vibration_service.dart   # 진동 피드백
│   └── pwa_install_service.dart # PWA 설치rt
│   └── challenge_service.dart
└── widgets/                  # 공통 위젯
    ├── glassmorphism_card.dart
    ├── animated_counter.dart
    ├── particle_effect.dart
    └── theme_shop_dialog.dart
```

## 🚀 시작하기

### 필수 요구사항
- Flutter SDK 3.0 이상
- Dart 3.0 이상
- Android Studio / VS Code

### 설치 및 실행

```bash
# 저장소 클론
git clone [repository-url]

# 디렉토리 이동
cd game2048

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 빌드

```bash
# Android APK 빌드
flutter build apk

# iOS 빌드 (macOS only)
fl웹 빌드 (PWA)
flutter build web --release

# 릴리즈 빌드
flutter build apk --release
```

### 배포 (Vercel)**마지막 드롭 위치**에서 합쳐집니다
2. ⭐(별) 3개를 합치면 3x3 영역이 폭발합니다
3. 보드를 꽉 채우지 않도록 공간 관리가 중요합니다
4. 높은 숫자일수록 더 많은 점수를 획득합니다
5. **주사위 6**은 별이 될 수 있는 특별한 주사위입니다!
6. 각 숫자마다 고유한 등장 애니메이션이 있습
Root Directory: build/web
Output Directory: (비워둠)

# 자동 배포
git push origin main
# 릴리즈 빌드
flutter build apk --release
```

## 🎯 게임 플레이 팁

### Dice Merge (주사위 위젯)
- **Lazy Loading**: 필요할 때만 위젯 로드
- **애니메이션 최적화**: 
  - Canvas 기반 커스텀 애니메이션
  - 30fps 제한으로 CPU 사용량 절감
  - 이펙트 개수 제한 (최대 4개)
- **Service Worker 캐싱**: 오프라인 지원 및 빠른 로딩

## 📝 업데이트 내역

### v2.1.0 (2026-02-04)
- 🎨 주사위 숫자별 고유 애니메이션 추가
- 🌀 병합 시 빨려들어가는 애니메이션
- 💰 점수 팝업 효과 (위로 떠오름)
- 🔥 콤보 표시 시스템
- 📳 상황별 진동 피드백 (6가지 패턴)
- 🎯 마지막 드롭 위치 기준 병합 로직
- ⏱️ 애니메이션 지속 시간 증가 (800-1200ms)
- ⚡ 폭발 파티클, 충격파, 번개 효과
- 🌐 PWA 업데이트 알림 시스템
- 🐛 Service Worker 캐시 버전 관리않도록 공간 관리가 중요합니다
4. 높은 숫자일수록 더 많은 점수를 획득합니다

### 2048
1. 스와이프로 모든 타일을 한 방향으로 이동
2. 같은 숫자끼리 합쳐져 두 배가 됩니다
3. 큰 숫자는 한쪽 모서리에 고정하는 전략 추천
4. 항상 다음 타일이 생길 공간을 확보하세요

## 🔧 성능 최적화

- **Fire-and-Forget 패턴**: 데이터 저장 시 블로킹 제거
- **캐시된 데이터**: 불필요한 서비스 호출 감소
- **RepaintBoundary**: 렌더링 최적화
- **Lazy Loading**: 필요할 때만 위젯 로드

## 📝 업데이트 내역

### v2.0.0 (2026-02-02)
- 🎮 일일 출석 시스템 추가
- 🎰 럭키 휠 기능 구현
- 🔄 연속 플레이 보너스 시스템
- ⬆️ 업그레이드 시스템 (6가지 타입)
- ✨ 글래스모피즘 UI 디자인 적용
- 🎨 애니메이션 대폭 개선
- 🐛 버그 수정 및 성능 최적화

### v1.0.0 (2026-01-15)
- 🎲 Dice Merge 게임 출시
- 🔢 2048 게임 출시
- 🏆 레벨 및 랭크 시스템
- 📋 데일리 미션
- 🛍️ 상점 기능

## 🤝 기여하기

버그 리포트, 기능 제안, Pull Request는 언제나 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

This project is licensed under the MIT License.

## 📧 연락처

프로젝트 링크: [https://github.com/khy1121]

---

**즐거운 게임 되세요! 🎮✨**
