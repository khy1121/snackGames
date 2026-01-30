import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SettingsService {
  static SharedPreferences? _prefs;
  
  static const String _keySoundEnabled = 'setting_sound_enabled';
  static const String _keyVibrationEnabled = 'setting_vibration_enabled';
  static const String _keyTextScale = 'setting_text_scale';
  
  // ValueNotifiers for reactive updates
  static final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  static final ValueNotifier<bool> vibrationEnabled = ValueNotifier(true);
  static final ValueNotifier<double> textScale = ValueNotifier(1.0);
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    soundEnabled.value = _prefs?.getBool(_keySoundEnabled) ?? true;
    vibrationEnabled.value = _prefs?.getBool(_keyVibrationEnabled) ?? true;
    textScale.value = _prefs?.getDouble(_keyTextScale) ?? 1.0;
  }
  
  static Future<void> setSoundEnabled(bool value) async {
    soundEnabled.value = value;
    await _prefs?.setBool(_keySoundEnabled, value);
  }
  
  static Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled.value = value;
    await _prefs?.setBool(_keyVibrationEnabled, value);
  }
  
  static Future<void> setTextScale(double value) async {
    textScale.value = value;
    await _prefs?.setDouble(_keyTextScale, value);
  }
}
