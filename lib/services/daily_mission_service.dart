import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// 데일리 미션 모델
class DailyMission {
  final String id;
  final String gameId;
  final String description;
  final int targetValue;
  int currentValue;
  final int reward;
  bool isCompleted;

  DailyMission({
    required this.id,
    required this.gameId,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    required this.reward,
    this.isCompleted = false,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'description': description,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'reward': reward,
        'isCompleted': isCompleted,
      };

  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
        id: json['id'],
        gameId: json['gameId'],
        description: json['description'],
        targetValue: json['targetValue'],
        currentValue: json['currentValue'] ?? 0,
        reward: json['reward'],
        isCompleted: json['isCompleted'] ?? false,
      );
}

/// 미션 템플릿
class MissionTemplate {
  final String gameId;
  final String Function(int) descBuilder;
  final int minTarget;
  final int maxTarget;
  final int reward;

  const MissionTemplate({
    required this.gameId,
    required this.descBuilder,
    required this.minTarget,
    required this.maxTarget,
    required this.reward,
  });
}

/// 데일리 미션 서비스
class DailyMissionService {
  static const String _keyMissionDate = 'mission_date';
  static const String _keyMissionData = 'mission_data';
  static const String _keyTotalRewards = 'total_rewards';

  static SharedPreferences? _prefs;
  static DailyMission? _currentMission;

  // 미션 템플릿들
  static final List<MissionTemplate> _templates = [
    // 2048 미션
    MissionTemplate(
      gameId: '2048',
      descBuilder: (v) => '2048에서 $v점 달성하기',
      minTarget: 500,
      maxTarget: 2000,
      reward: 50,
    ),
    MissionTemplate(
      gameId: '2048',
      descBuilder: (v) => '2048에서 $v타일 만들기',
      minTarget: 128,
      maxTarget: 512,
      reward: 100,
    ),
    // Dice 미션
    MissionTemplate(
      gameId: 'dice',
      descBuilder: (v) => 'Dice Merge에서 $v점 달성하기',
      minTarget: 300,
      maxTarget: 1500,
      reward: 50,
    ),
    MissionTemplate(
      gameId: 'dice',
      descBuilder: (v) => 'Dice Merge에서 주사위 $v개 합치기',
      minTarget: 10,
      maxTarget: 30,
      reward: 80,
    ),

  ];

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await _loadOrGenerateMission();
  }

  static SharedPreferences get prefs => _prefs!;

  static DailyMission? get currentMission => _currentMission;

  /// 미션 로드 또는 새로 생성
  static Future<void> _loadOrGenerateMission() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString(_keyMissionDate);

    if (savedDate == today) {
      // 오늘 미션 로드
      final data = prefs.getString(_keyMissionData);
      if (data != null) {
        try {
          final json = _parseJson(data);
          _currentMission = DailyMission.fromJson(json);
          return;
        } catch (_) {}
      }
    }

    // 새 미션 생성
    await _generateNewMission();
    await prefs.setString(_keyMissionDate, today);
  }

  /// 새 미션 생성
  static Future<void> _generateNewMission() async {
    final random = Random();
    final template = _templates[random.nextInt(_templates.length)];

    final target = template.minTarget +
        random.nextInt(template.maxTarget - template.minTarget + 1);

    // 타겟을 깔끔한 숫자로
    final roundedTarget = (target ~/ 10) * 10;

    _currentMission = DailyMission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      gameId: template.gameId,
      description: template.descBuilder(roundedTarget),
      targetValue: roundedTarget,
      reward: template.reward,
    );

    _saveMission();
  }

  /// 미션 저장 (non-blocking)
  static void _saveMission() {
    if (_currentMission != null) {
      prefs.setString(_keyMissionData, _toJsonString(_currentMission!.toJson()));
    }
  }

  /// 미션 진행도 업데이트 (non-blocking)
  static void updateProgress(String gameId, int value) {
    if (_currentMission == null) return;
    if (_currentMission!.gameId != gameId) return;
    if (_currentMission!.isCompleted) return;

    _currentMission!.currentValue = value;

    if (_currentMission!.currentValue >= _currentMission!.targetValue) {
      _currentMission!.isCompleted = true;
      _addReward(_currentMission!.reward);
    }

    _saveMission();
  }

  /// 보상 추가 (non-blocking)
  static void _addReward(int amount) {
    final current = prefs.getInt(_keyTotalRewards) ?? 0;
    prefs.setInt(_keyTotalRewards, current + amount);
  }

  /// 총 획득 보상
  static int getTotalRewards() {
    return _prefs?.getInt(_keyTotalRewards) ?? 0;
  }

  // 간단한 JSON 파싱
  static Map<String, dynamic> _parseJson(String json) {
    // 간단한 구현 - 실제로는 dart:convert 사용
    final map = <String, dynamic>{};
    final content = json.substring(1, json.length - 1);
    final pairs = content.split(',');
    
    for (final pair in pairs) {
      final kv = pair.split(':');
      if (kv.length == 2) {
        var key = kv[0].trim().replaceAll('"', '');
        var value = kv[1].trim();
        
        if (value.startsWith('"') && value.endsWith('"')) {
          map[key] = value.substring(1, value.length - 1);
        } else if (value == 'true') {
          map[key] = true;
        } else if (value == 'false') {
          map[key] = false;
        } else {
          map[key] = int.tryParse(value) ?? value;
        }
      }
    }
    return map;
  }

  static String _toJsonString(Map<String, dynamic> map) {
    final pairs = map.entries.map((e) {
      final value = e.value;
      if (value is String) {
        return '"${e.key}":"$value"';
      } else {
        return '"${e.key}":$value';
      }
    });
    return '{${pairs.join(',')}}';
  }
}
