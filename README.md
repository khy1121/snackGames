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

### 🏆 진행 시스템
- **레벨 시스템**: 게임을 플레이하며 경험치 획득 및 레벨업
- **랭크 시스템**: 누적 포인트에 따른 등급 상승
- **데일리 미션**: 매일 새로운 미션 도전
- **도전 과제**: 다양한 업적 달성

### 🎨 UI/UX
- **글래스모피즘 디자인**: 투명하고 모던한 카드 효과
- **부드러운 애니메이션**: 
  - 주사위 elasticOut 애니메이션
  - 페이지 전환 페이드 효과
  - 숫자 카운팅 애니메이션
- **3색 그라데이션 배경**: 시각적 깊이감
- **반응형 인터랙션**: 터치 피드백 및 스케일 애니메이션

## 🛠️ 기술 스택

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: StatefulWidget
- **Storage**: SharedPreferences
- **Architecture**: Service Pattern

## 📂 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── home/                     # 홈 화면
│   └── home_page.dart
├── dice/                     # Dice Merge 게임
│   ├── dice_game_page.dart
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
│   ├── achievement_service.dart
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
flutter build ios

# 릴리즈 빌드
flutter build apk --release
```

## 🎯 게임 플레이 팁

### Dice Merge
1. 같은 숫자 3개를 모으면 다음 숫자로 합쳐집니다
2. ⭐(별) 3개를 합치면 3x3 영역이 폭발합니다
3. 보드를 꽉 채우지 않도록 공간 관리가 중요합니다
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

프로젝트 링크: [GitHub Repository URL]

---

**즐거운 게임 되세요! 🎮✨**
