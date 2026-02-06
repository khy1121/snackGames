import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SettingsService {
  static SharedPreferences? _prefs;
  
  static const String _keySoundEnabled = 'setting_sound_enabled';
  static const String _keyVibrationEnabled = 'setting_vibration_enabled';
  static const String _keyTextScale = 'setting_text_scale';
  static const String _keySfxVolume = 'setting_sfx_volume';
  static const String _keyMusicVolume = 'setting_music_volume';
  
  // ValueNotifiers for reactive updates
  static final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  static final ValueNotifier<bool> vibrationEnabled = ValueNotifier(true);
  static final ValueNotifier<double> textScale = ValueNotifier(1.0);
  static final ValueNotifier<double> sfxVolume = ValueNotifier(0.5);
  static final ValueNotifier<double> musicVolume = ValueNotifier(0.3);
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    soundEnabled.value = _prefs?.getBool(_keySoundEnabled) ?? true;
    vibrationEnabled.value = _prefs?.getBool(_keyVibrationEnabled) ?? true;
    textScale.value = _prefs?.getDouble(_keyTextScale) ?? 1.0;
    sfxVolume.value = _prefs?.getDouble(_keySfxVolume) ?? 0.5;
    musicVolume.value = _prefs?.getDouble(_keyMusicVolume) ?? 0.3;
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
  
  static Future<void> setSfxVolume(double value) async {
    sfxVolume.value = value;
    await _prefs?.setDouble(_keySfxVolume, value);
  }
  
  static Future<void> setMusicVolume(double value) async {
    musicVolume.value = value;
    await _prefs?.setDouble(_keyMusicVolume, value);
  }
}
