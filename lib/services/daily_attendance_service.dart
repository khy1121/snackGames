import 'package:shared_preferences/shared_preferences.dart';

class DailyAttendanceService {
  static const String _lastAttendanceDateKey = 'last_attendance_date';
  static const String _streakDaysKey = 'attendance_streak_days';
  static const String _totalAttendanceKey = 'total_attendance_days';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('DailyAttendanceService not initialized');
    }
    return _prefs!;
  }

  // 오늘 출석 체크
  static Future<AttendanceReward?> checkAttendance() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastDateStr = prefs.getString(_lastAttendanceDateKey);
    
    // 이미 오늘 출석한 경우
    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      if (lastDate.year == today.year && 
          lastDate.month == today.month && 
          lastDate.day == today.day) {
        return null; // 이미 출석함
      }
    }

    // 연속 출석 계산
    int streakDays = prefs.getInt(_streakDaysKey) ?? 0;
    
    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (lastDate.year == yesterday.year && 
          lastDate.month == yesterday.month && 
          lastDate.day == yesterday.day) {
        // 연속 출석
        streakDays++;
      } else {
        // 연속 끊김
        streakDays = 1;
      }
    } else {
      streakDays = 1;
    }

    // 출석 기록 저장
    _saveAttendance(today.toIso8601String(), streakDays);

    // 보상 계산
    return _calculateReward(streakDays);
  }

  static void _saveAttendance(String dateStr, int streakDays) {
    prefs.setString(_lastAttendanceDateKey, dateStr);
    prefs.setInt(_streakDaysKey, streakDays);
    
    final totalDays = (prefs.getInt(_totalAttendanceKey) ?? 0) + 1;
    prefs.setInt(_totalAttendanceKey, totalDays);
  }

  static AttendanceReward _calculateReward(int streakDays) {
    int points = 50; // 기본 보상
    int exp = 20;
    bool isSpecial = false;

    // 연속 출석 보너스
    if (streakDays >= 7) {
      points = 500; // 7일 연속 특별 보상
      exp = 200;
      isSpecial = true;
    } else if (streakDays >= 5) {
      points = 200;
      exp = 80;
    } else if (streakDays >= 3) {
      points = 100;
      exp = 40;
    }

    return AttendanceReward(
      points: points,
      exp: exp,
      streakDays: streakDays,
      isSpecial: isSpecial,
    );
  }

  // 오늘 출석했는지 확인
  static bool hasAttendedToday() {
    final lastDateStr = prefs.getString(_lastAttendanceDateKey);
    if (lastDateStr == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime.parse(lastDateStr);

    return lastDate.year == today.year && 
           lastDate.month == today.month && 
           lastDate.day == today.day;
  }

  // 현재 연속 출석 일수
  static int getStreakDays() {
    return prefs.getInt(_streakDaysKey) ?? 0;
  }

  // 총 출석 일수
  static int getTotalAttendanceDays() {
    return prefs.getInt(_totalAttendanceKey) ?? 0;
  }
}

class AttendanceReward {
  final int points;
  final int exp;
  final int streakDays;
  final bool isSpecial;

  AttendanceReward({
    required this.points,
    required this.exp,
    required this.streakDays,
    required this.isSpecial,
  });
}
