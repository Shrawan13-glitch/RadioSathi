import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingCategory { none, bhakti, news, bhav }

enum SpeechRate { slow, normal }

class CaregiverSettings {
  final String language;
  final bool autoStartListening;
  final bool speakWelcome;
  final SpeechRate speechRate;
  final SettingCategory defaultCategory;
  final bool safeSearchMode;
  final double shakeThreshold;
  final int minListeningSeconds;

  const CaregiverSettings({
    this.language = 'marathi',
    this.autoStartListening = true,
    this.speakWelcome = true,
    this.speechRate = SpeechRate.slow,
    this.defaultCategory = SettingCategory.none,
    this.safeSearchMode = true,
    this.shakeThreshold = 15.0,
    this.minListeningSeconds = 5,
  });

  CaregiverSettings copyWith({
    String? language,
    bool? autoStartListening,
    bool? speakWelcome,
    SpeechRate? speechRate,
    SettingCategory? defaultCategory,
    bool? safeSearchMode,
    double? shakeThreshold,
    int? minListeningSeconds,
  }) {
    return CaregiverSettings(
      language: language ?? this.language,
      autoStartListening: autoStartListening ?? this.autoStartListening,
      speakWelcome: speakWelcome ?? this.speakWelcome,
      speechRate: speechRate ?? this.speechRate,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      safeSearchMode: safeSearchMode ?? this.safeSearchMode,
      shakeThreshold: shakeThreshold ?? this.shakeThreshold,
      minListeningSeconds: minListeningSeconds ?? this.minListeningSeconds,
    );
  }
}

class CaregiverSettingsService {
  static const String _languageKey = 'cg_language';
  static const String _autoListenKey = 'cg_auto_listen';
  static const String _speakWelcomeKey = 'cg_speak_welcome';
  static const String _speechRateKey = 'cg_speech_rate';
  static const String _defaultCategoryKey = 'cg_default_category';
  static const String _safeSearchKey = 'cg_safe_search';
  static const String _shakeThresholdKey = 'cg_shake_threshold';
  static const String _minListeningSecondsKey = 'cg_min_listening_seconds';

  static final CaregiverSettingsService _instance = CaregiverSettingsService._internal();
  factory CaregiverSettingsService() => _instance;
  CaregiverSettingsService._internal();

  CaregiverSettings? _cached;

  Future<CaregiverSettings> load() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    _cached = CaregiverSettings(
      language: prefs.getString(_languageKey) ?? 'marathi',
      autoStartListening: prefs.getBool(_autoListenKey) ?? true,
      speakWelcome: prefs.getBool(_speakWelcomeKey) ?? true,
      speechRate: SpeechRate.values[prefs.getInt(_speechRateKey) ?? 0],
      defaultCategory: SettingCategory.values[prefs.getInt(_defaultCategoryKey) ?? 0],
      safeSearchMode: prefs.getBool(_safeSearchKey) ?? true,
      shakeThreshold: prefs.getDouble(_shakeThresholdKey) ?? 15.0,
      minListeningSeconds: prefs.getInt(_minListeningSecondsKey) ?? 5,
    );
    return _cached!;
  }

  Future<void> save(CaregiverSettings settings) async {
    _cached = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, settings.language);
    await prefs.setBool(_autoListenKey, settings.autoStartListening);
    await prefs.setBool(_speakWelcomeKey, settings.speakWelcome);
    await prefs.setInt(_speechRateKey, settings.speechRate.index);
    await prefs.setInt(_defaultCategoryKey, settings.defaultCategory.index);
    await prefs.setBool(_safeSearchKey, settings.safeSearchMode);
    await prefs.setDouble(_shakeThresholdKey, settings.shakeThreshold);
    await prefs.setInt(_minListeningSecondsKey, settings.minListeningSeconds);
  }

  Future<void> clearFavorites() async {
    final hiveBox = await Hive.openBox('commands');
    await hiveBox.clear();
  }

  Future<void> clearRecentlyPlayed() async {
    final hiveBox = await Hive.openBox('recently_played');
    await hiveBox.clear();
  }

  double getSpeechRateValue(SpeechRate rate) {
    return rate == SpeechRate.slow ? 0.3 : 0.5;
  }
}