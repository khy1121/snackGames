# 트러블슈팅 문서 📋

이 문서는 스넥게임즈 개발 과정에서 발생한 모든 문제와 해결 방법을 정리한 것입니다.

---

## 목차
1. [상점 페이지 SnackBar 컨텍스트 문제](#1-상점-페이지-snackbar-컨텍스트-문제)
2. [테마 카드 가로 스크롤 구현](#2-테마-카드-가로-스크롤-구현)
3. [PWA Service Worker 등록 실패](#3-pwa-service-worker-등록-실패)
4. [업그레이드 효과 미적용 문제](#4-업그레이드-효과-미적용-문제)
5. [도전과제 동기화 문제](#5-도전과제-동기화-문제)
6. [ShopPage Scaffold 중첩 구조 오류](#6-shoppage-scaffold-중첩-구조-오류)

---

## 1. 상점 페이지 SnackBar 컨텍스트 문제

### 🔴 문제
상점 페이지에서 테마 구매, 포인트 부족 등의 알림 메시지(SnackBar)가 **상점 다이얼로그 내부가 아닌 부모 페이지(HomePage)에 표시**되는 문제 발생.

**증상:**
- 상점 다이얼로그 뒤에 SnackBar가 표시됨
- 사용자가 알림을 보지 못함
- UI/UX 혼란 초래

### 🔍 원인 분석
```dart
// 문제가 있던 코드
void _purchaseTheme(String themeId, int price) async {
  if (_userPoints < price) {
    ScaffoldMessenger.of(context).showSnackBar(  // ❌ 잘못된 context
      const SnackBar(content: Text('❌ 포인트가 부족합니다!')),
    );
  }
}
```

**근본 원인:**
1. `ScaffoldMessenger.of(context)`가 **위젯 트리를 거슬러 올라가** 가장 가까운 `ScaffoldMessenger`를 찾음
2. `ShopPage`는 자체 `Scaffold`를 가지고 있지만, **독립적인 `ScaffoldMessenger`가 없었음**
3. 결과적으로 부모인 `HomePage`의 `ScaffoldMessenger`를 사용하게 됨

**위젯 트리 구조:**
```
MaterialApp
 └─ ScaffoldMessenger (HomePage용)
     └─ HomePage
         └─ Scaffold (HomePage)
             └─ ShopPage (다이얼로그/페이지)
                 └─ Scaffold (ShopPage)  // ❌ 자체 ScaffoldMessenger 없음
```

### ✅ 해결 방법

#### **최종 해결책: ScaffoldMessenger 래퍼 추가**
```dart
// ✅ 성공한 해결책
@override
Widget build(BuildContext context) {
  return ScaffoldMessenger(  // 독립적인 ScaffoldMessenger 생성
    child: Builder(
      builder: (messengerContext) {  // 새로운 context
        return Scaffold(
          // ... ShopPage UI
          body: Builder(
            builder: (scaffoldContext) {
              // messengerContext를 사용
              return _buildContent(messengerContext);
            },
          ),
        );
      },
    ),
  );
}

// 메서드에서 사용
void _purchaseTheme(String themeId, int price, BuildContext messengerContext) {
  if (_userPoints < price) {
    ScaffoldMessenger.of(messengerContext)  // ✅ 올바른 context
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('❌ 포인트가 부족합니다!')),
      );
  }
}
```

**핵심 변경사항:**
1. `ShopPage`를 `ScaffoldMessenger`로 감싸기
2. `Builder`로 `messengerContext` 생성
3. 모든 SnackBar 호출에 `messengerContext` 전달
4. `clearSnackBars()` 추가로 중복 방지

**위젯 트리 (수정 후):**
```
MaterialApp
 └─ ScaffoldMessenger (HomePage용)
     └─ HomePage
         └─ Scaffold (HomePage)
             └─ ShopPage
                 └─ ScaffoldMessenger (ShopPage용) ✅
                     └─ Builder (messengerContext)
                         └─ Scaffold (ShopPage)
```

### 📚 학습 포인트
- `ScaffoldMessenger.of(context)`는 위젯 트리를 거슬러 올라감
- 독립적인 SnackBar 범위가 필요하면 `ScaffoldMessenger` 래퍼 필수
- `Builder` 위젯으로 새로운 `BuildContext` 생성 가능
- `clearSnackBars()`로 중복 SnackBar 방지

---

## 2. 테마 카드 가로 스크롤 구현

### 🔴 문제
상점 페이지의 테마 카드들이 **가로로 스크롤되지 않고**, 사용자가 더 많은 테마를 볼 수 없는 문제.

**증상:**
- 테마 카드가 화면에 2~3개만 표시됨
- 스크롤 가능성을 알 수 없음
- 나머지 테마를 볼 방법이 없음

### 🔍 원인 분석
```dart
// 문제가 있던 코드
Row(
  children: _themes.map((theme) {
    return _buildThemeCard(theme, ...);
  }).toList(),
)
```

**근본 원인:**
1. `Row` 위젯은 **스크롤을 지원하지 않음**
2. 자식 위젯들이 화면 너비를 초과하면 **오버플로우 발생**
3. 사용자가 스크롤 가능 여부를 알 수 없음

### ✅ 해결 방법

#### **1단계: ListView.separated로 변경**
```dart
SizedBox(
  height: 220,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,  // ✅ 가로 스크롤
    itemCount: _themes.length,
    separatorBuilder: (context, index) => const SizedBox(width: 12),
    itemBuilder: (context, index) {
      final theme = _themes[index];
      return _buildThemeCard(theme, ...);
    },
  ),
)
```

#### **2단계: 스크롤 가능성 시각화**
```dart
ListView.separated(
  scrollDirection: Axis.horizontal,
  padding: const EdgeInsets.only(left: 4, right: 80),  // ✅ 오른쪽 여백으로 다음 카드 일부 표시
  clipBehavior: Clip.none,  // ✅ 오버플로우 허용
  // ...
)
```

#### **3단계: 카드 너비 최적화**
```dart
Widget _buildThemeCard(...) {
  return Container(
    width: 130,  // ✅ 160 → 140 → 130으로 점진적 축소
    // 더 많은 카드가 화면에 보이도록
  );
}
```

**최종 결과:**
- 한 화면에 2.5~3개 카드 표시
- 오른쪽 여백으로 다음 카드 일부 노출
- 스크롤 가능성 직관적으로 인지 가능

### 📚 학습 포인트
- `Row`는 스크롤 불가 → `ListView`로 대체
- `padding`의 비대칭 설정으로 스크롤 힌트 제공
- `clipBehavior: Clip.none`으로 부분 카드 표시
- 카드 너비 조정으로 UX 최적화

---

## 3. PWA Service Worker 등록 실패

### 🔴 문제
PWA Service Worker가 등록되지 않아 **오프라인 기능 및 설치 프롬프트가 작동하지 않는** 문제.

**증상:**
- `beforeinstallprompt` 이벤트 발생 안 함
- 브라우저 콘솔에 "ServiceWorker registration failed" 오류
- PWA 설치 버튼이 표시되지 않음

### 🔍 원인 분석
```javascript
// 문제가 있던 코드
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js')  // ❌ 경로 문제
    .then(...)
    .catch(error => console.log('Registration failed:', error));
}
```

**근본 원인:**
1. **Service Worker 파일 누락**: `web/sw.js` 파일이 생성되지 않음
2. **HTTPS 요구사항**: `localhost`가 아닌 환경에서는 HTTPS 필수
3. **Scope 문제**: Service Worker의 scope가 올바르게 설정되지 않음

### ✅ 해결 방법

#### **1단계: Service Worker 파일 생성**
```javascript
// web/sw.js
const CACHE_NAME = 'snack-games-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
  // ... 기타 리소스
];

// Install event
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  );
  self.skipWaiting();  // ✅ 즉시 활성화
});

// Activate event
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);  // ✅ 오래된 캐시 삭제
          }
        })
      );
    })
  );
  self.clients.claim();  // ✅ 즉시 제어 시작
});

// Fetch event - Cache-first strategy
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => response || fetch(event.request))
  );
});
```

#### **2단계: index.html에 등록 스크립트 추가**
```html
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/sw.js')
        .then((registration) => {
          console.log('SW registered:', registration.scope);
        })
        .catch((error) => {
          console.log('SW registration failed:', error);
        });
    });
  }
</script>
```

#### **3단계: manifest.json 업데이트**
```json
{
  "name": "스넥게임즈 - Snack Games",
  "short_name": "스넥게임즈",
  "start_url": "/",
  "display": "standalone",
  "scope": "/",  // ✅ Service Worker scope와 일치
  "theme_color": "#2E5940",
  "background_color": "#F5F1E8"
}
```

### 📚 학습 포인트
- Service Worker는 `web/` 디렉토리에 위치해야 함
- `skipWaiting()`과 `clients.claim()`으로 즉시 활성화
- Cache-first 전략으로 오프라인 지원
- HTTPS 환경에서만 완전히 작동 (localhost 제외)

---

## 4. 업그레이드 효과 미적용 문제

### 🔴 문제
사용자가 업그레이드를 구매했지만 **게임 내에서 효과가 적용되지 않는** 문제.

**증상:**
- 점수 배율 업그레이드를 구매해도 점수가 증가하지 않음
- 시작 보너스가 적용되지 않음
- 포인트 부스트 효과 없음

### 🔍 원인 분석
```dart
// 문제가 있던 코드 (GamePage)
void _showGameOverDialog() {
  final score = _board.score;  // ❌ 배율 미적용
  GameDataService.recordScore('2048', score);
  
  final reward = (score / 200).floor();  // ❌ 포인트 배율 미적용
  GameDataService.addPoints(reward);
}
```

**근본 원인:**
1. **업그레이드 서비스 미호출**: 게임 로직에서 `UpgradeService` 메서드를 호출하지 않음
2. **배율 계산 누락**: 최종 점수 및 보상 계산 시 배율 미적용
3. **시작 보너스 미적용**: 게임 시작 시 보너스 점수 추가 안 됨

### ✅ 해결 방법

#### **1단계: UpgradeService import**
```dart
import '../services/upgrade_service.dart';
```

#### **2단계: 게임 시작 시 보너스 적용**
```dart
@override
void initState() {
  super.initState();
  _startTime = DateTime.now();
  final savedBest = GameDataService.getBestScore('2048');
  _board = GameBoard.newGame(bestScore: savedBest);
  
  // ✅ 시작 보너스 적용
  _board.score += UpgradeService.getStartingBonus();
}

void _startNewGame() {
  setState(() {
    final prevBest = _board.bestScore;
    _board = GameBoard.newGame(bestScore: prevBest);
    
    // ✅ 새 게임 시작 시에도 보너스 적용
    _board.score += UpgradeService.getStartingBonus();
  });
}
```

#### **3단계: 게임 종료 시 배율 적용**
```dart
void _showGameOverDialog() {
  // ✅ 업그레이드 배율 가져오기
  final scoreMultiplier = UpgradeService.getScoreMultiplier();
  final pointsMultiplier = UpgradeService.getPointsMultiplier();
  
  // ✅ 점수에 배율 적용
  final finalScore = (_board.score * scoreMultiplier).round();
  GameDataService.recordScore('2048', finalScore);
  
  // ✅ 보상에 배율 적용
  final baseReward = (finalScore / 200).floor();
  final finalReward = (baseReward * pointsMultiplier).round();
  GameDataService.addPoints(finalReward);
  
  // UI에 최종 값 표시
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: Text('점수: $finalScore\n보상: $finalReward P'),
    ),
  );
}
```

#### **4단계: 주사위 게임에도 동일 적용**
```dart
// DiceGamePage
void _generateNextDice() {
  // ✅ Lucky Dice 보너스 적용
  final luckyBonus = UpgradeService.getLuckyDiceBonus();
  final magicBonus = UpgradeService.getMagicChanceBonus();
  
  // 가중치 조정
  final weights = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0 + magicBonus];
  // ...
}
```

### 📚 학습 포인트
- 업그레이드 효과는 **게임 로직의 핵심 지점**에 적용해야 함
- 시작 시, 진행 중, 종료 시 각각 다른 업그레이드 적용
- UI에 표시되는 값과 저장되는 값 모두 배율 적용 필요
- 여러 게임 모드에 일관되게 적용

---

## 5. 도전과제 동기화 문제

### 🔴 문제
앱을 재시작하면 **도전과제 진행도가 초기화**되거나 **업적이 중복 달성**되는 문제.

**증상:**
- 게임을 10번 플레이했는데 도전과제는 0/10으로 표시
- 이미 달성한 업적이 다시 알림으로 표시됨
- 베스트 스코어 업적이 작동하지 않음

### 🔍 원인 분석
```dart
// 문제가 있던 코드
class AchievementService {
  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _loadAchievements();
    // ❌ 외부 데이터(GameDataService)와 동기화 안 함
  }
}
```

**근본 원인:**
1. **데이터 소스 분리**: `AchievementService`와 `GameDataService`가 독립적으로 작동
2. **초기화 순서 문제**: 앱 시작 시 동기화 로직 누락
3. **조건 검사 누락**: 이미 달성한 업적 재확인 안 함

### ✅ 해결 방법

#### **1단계: 동기화 메서드 추가**
```dart
// AchievementService
static void syncFromGameData(int totalGames) {
  // ✅ 외부 데이터로 진행도 업데이트
  for (var achievement in _achievements) {
    if (achievement.id == 'first_game' && totalGames >= 1) {
      achievement.isUnlocked = true;
    }
    if (achievement.id == 'play_10' && totalGames >= 10) {
      achievement.isUnlocked = true;
    }
    // ... 기타 업적
  }
  _saveAchievements();
}

// ChallengeService
static void syncFromGameData(int totalGames, int best2048, int bestDice) {
  // ✅ 게임 통계로 도전과제 진행도 업데이트
  for (var challenge in _challenges) {
    if (challenge.type == ChallengeType.playGames) {
      challenge.currentProgress = totalGames;
    }
    if (challenge.type == ChallengeType.score2048) {
      challenge.currentProgress = best2048;
    }
    // ...
  }
  _saveChallenges();
}
```

#### **2단계: HomePage에서 동기화 호출**
```dart
// HomePage
void _loadCachedData() {
  // ✅ 먼저 외부 데이터 가져오기
  final totalGames = GameDataService.getTotalGamesPlayed();
  final bestScore2048 = GameDataService.getBestScore('2048');
  final bestScoreDice = GameDataService.getBestScore('dice');
  
  // ✅ 동기화 실행
  AchievementService.syncFromGameData(totalGames);
  ChallengeService.syncFromGameData(totalGames, bestScore2048, bestScoreDice);
  
  // 이후 UI 데이터 로드
  _mission = DailyMissionService.currentMission;
  _rank = AchievementService.getCurrentRank();
  // ...
}
```

#### **3단계: 실시간 업적 트리거 추가**
```dart
// GamePage - 게임 중 실시간 업적 체크
void _handleSwipe(Direction direction) {
  // ... 게임 로직
  
  // ✅ 실시간 업적 트리거
  AchievementService.triggerAchievement('swipe_master');
  
  if (_board.score >= 2048) {
    AchievementService.triggerAchievement('reach_2048');
  }
}
```

### 📚 학습 포인트
- 여러 데이터 소스는 **명시적 동기화** 필요
- 앱 시작 시 동기화로 데이터 일관성 보장
- 실시간 트리거와 동기화 병행 사용
- `SharedPreferences` 저장 후 즉시 반영

---

## 6. ShopPage Scaffold 중첩 구조 오류

### 🔴 문제
`ShopPage`에 `ScaffoldMessenger`를 추가한 후 **구문 오류 및 괄호 불일치** 발생.

**증상:**
```
error - Expected to find ',' - lib\shop\shop_page.dart:385:3
error - Function expressions can't be named
error - Expected to find ';'
error - Expected to find ')'
```

### 🔍 원인 분석
```dart
// 문제가 있던 코드
return ScaffoldMessenger(
  child: Builder(
    builder: (messengerContext) {
      return Scaffold(
        // ...
        body: Builder(
          builder: (scaffoldContext) {
            return SafeArea(
              // ...
            );
          },
        ),
      );  // ❌ 닫는 괄호 부족
    },
  ),
);  // ❌ Scaffold 닫는 괄호 누락
```

**근본 원인:**
1. **중첩된 Builder**: 2개의 `Builder` 위젯으로 인한 복잡한 구조
2. **괄호 카운팅 오류**: 수동 편집 중 닫는 괄호 누락
3. **들여쓰기 혼란**: 깊은 중첩으로 인한 가독성 저하

### ✅ 해결 방법

#### **올바른 구조**
```dart
@override
Widget build(BuildContext context) {
  return ScaffoldMessenger(              // 1. ScaffoldMessenger 시작
    child: Builder(                       // 2. Builder 시작 (messengerContext)
      builder: (messengerContext) {
        return Scaffold(                  // 3. Scaffold 시작
          appBar: AppBar(...),
          body: Builder(                  // 4. Builder 시작 (scaffoldContext)
            builder: (scaffoldContext) {
              return SafeArea(            // 5. SafeArea 시작
                child: Column(...),
              );                          // 5. SafeArea 끝
            },                            // 4. Builder 끝 (scaffoldContext)
          ),
        );                                // 3. Scaffold 끝
      },                                  // 2. Builder 끝 (messengerContext)
    ),                                    // 1. ScaffoldMessenger 끝
  );
}
```

**괄호 체크리스트:**
```
ScaffoldMessenger(
  child: Builder(
    builder: (messengerContext) {
      return Scaffold(
        body: Builder(
          builder: (scaffoldContext) {
            return SafeArea(...);
          },  // ← scaffoldContext Builder 닫기
        ),    // ← body Builder 닫기
      );      // ← Scaffold 닫기
    },        // ← messengerContext Builder 닫기
  ),          // ← ScaffoldMessenger child 닫기
);            // ← ScaffoldMessenger 닫기
```

### 📚 학습 포인트
- 중첩 구조는 **주석으로 괄호 표시** 권장
- IDE의 괄호 매칭 기능 활용
- `flutter analyze` 명령으로 구문 오류 조기 발견
- 복잡한 구조는 단계별로 작성 및 테스트

---

## 🎯 일반적인 디버깅 팁

### 1. **Flutter Analyze 활용**
```bash
flutter analyze lib/shop/shop_page.dart
```
- 구문 오류, 타입 오류 조기 발견
- 사용하지 않는 import 정리
- 코드 품질 개선 제안

### 2. **Hot Reload vs Hot Restart**
- **Hot Reload (r)**: UI 변경 사항만 반영
- **Hot Restart (R)**: 전체 앱 재시작 (상태 초기화)
- Service 초기화 변경 시 Hot Restart 필수

### 3. **Chrome DevTools 활용**
```
F12 → Application 탭
- Manifest: PWA 설정 확인
- Service Workers: 등록 상태 확인
- Storage: SharedPreferences 데이터 확인
```

### 4. **로그 활용**
```dart
print('DEBUG: _isPWAInstallable = $_isPWAInstallable');
debugPrint('Score multiplier: ${UpgradeService.getScoreMultiplier()}');
```

### 5. **Context 디버깅**
```dart
// BuildContext의 위젯 트리 위치 확인
print(context.widget.runtimeType);
print(context.findAncestorWidgetOfExactType<Scaffold>());
```

---

## 📊 문제 발생 빈도 및 해결 시간

| 문제 | 발생 빈도 | 평균 해결 시간 | 난이도 |
|------|-----------|----------------|--------|
| SnackBar 컨텍스트 | 1회 | 30분 | ⭐⭐⭐ |
| 테마 스크롤 | 1회 | 15분 | ⭐⭐ |
| PWA Service Worker | 1회 | 20분 | ⭐⭐⭐ |
| 업그레이드 미적용 | 1회 | 25분 | ⭐⭐ |
| 도전과제 동기화 | 1회 | 20분 | ⭐⭐⭐ |
| Scaffold 구조 오류 | 1회 | 10분 | ⭐ |

---

## 🔮 향후 예방 조치

### 1. **코드 리뷰 체크리스트**
- [ ] `ScaffoldMessenger.of(context)` 사용 시 올바른 context 확인
- [ ] 스크롤 가능한 리스트는 `ListView` 사용
- [ ] 업그레이드 효과는 모든 게임 모드에 적용
- [ ] 데이터 동기화 로직 앱 시작 시 실행
- [ ] 중첩 구조는 주석으로 괄호 표시

### 2. **테스트 자동화**
```dart
// Widget 테스트
testWidgets('SnackBar appears in correct context', (tester) async {
  await tester.pumpWidget(ShopPage());
  await tester.tap(find.text('구매'));
  await tester.pump();
  
  expect(find.byType(SnackBar), findsOneWidget);
});
```

### 3. **문서화**
- 복잡한 위젯 구조는 다이어그램으로 문서화
- 데이터 흐름은 플로우차트로 시각화
- 주요 의사결정은 ADR(Architecture Decision Record) 작성

---

## ✅ 결론

이 문서에 정리된 트러블슈팅 경험을 통해:
1. **Flutter의 BuildContext 시스템** 깊이 이해
2. **위젯 트리 구조**의 중요성 인식
3. **데이터 동기화** 패턴 학습
4. **PWA 구현** 노하우 습득
5. **디버깅 스킬** 향상

향후 유사한 문제 발생 시 이 문서를 참고하여 **빠른 해결** 가능! 🚀
