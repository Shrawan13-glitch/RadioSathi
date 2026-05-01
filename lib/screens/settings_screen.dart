import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/caregiver_settings_service.dart';
import 'commands_screen.dart';
import 'logs_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late CaregiverSettings _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final svc = CaregiverSettingsService();
    final settings = await svc.load();
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ttsService = TtsService();
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Settings / सेटिंग्ज',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Caregiver Settings / काळजीदार सेटिंग्ज'),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'भाषा / Language',
            subtitle: _settings.language == 'marathi' ? 'मराठी' : _settings.language,
            onTap: () => _showLanguageDialog(context),
          ),
          _buildSwitchTile(
            icon: Icons.mic,
            title: 'सुरूवातीला ऐका / Auto-listen',
            value: _settings.autoStartListening,
            onChanged: (v) => _updateSetting(_settings.copyWith(autoStartListening: v)),
          ),
          _buildSwitchTile(
            icon: Icons.record_voice_over,
            title: 'स्वागत संदेश / Welcome msg',
            value: _settings.speakWelcome,
            onChanged: (v) => _updateSetting(_settings.copyWith(speakWelcome: v)),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.speed,
            title: 'बोलण्याचा वेग / Speech rate',
            subtitle: _settings.speechRate == SpeechRate.slow ? 'मंद / Slow' : 'सामान्य / Normal',
            onTap: () => _showSpeechRateDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.category,
            title: 'रेडिओ श्रेणी / Default category',
            subtitle: _getCategoryLabel(_settings.defaultCategory),
            onTap: () => _showCategoryDialog(context),
          ),
          _buildSwitchTile(
            icon: Icons.child_care,
            title: 'सुरक्षित शोध / Safe search',
            value: _settings.safeSearchMode,
            onChanged: (v) => _updateSetting(_settings.copyWith(safeSearchMode: v)),
          ),
          Card(
            color: const Color(0xFF16213E),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vibration, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shake to speak / हलवून बोला',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              'Sensitivity: ${_settings.shakeThreshold.toInt()}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.shakeThreshold,
                    min: 5,
                    max: 30,
                    divisions: 25,
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.deepPurple.withValues(alpha: 0.3),
                    onChanged: (v) => _updateSetting(_settings.copyWith(shakeThreshold: v)),
                  ),
                ],
              ),
            ),
          ),
          Card(
            color: const Color(0xFF16213E),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mic on duration / मायक चालू वेळ',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              '${_settings.minListeningSeconds} seconds',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.minListeningSeconds.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.deepPurple.withValues(alpha: 0.3),
                    onChanged: (v) => _updateSetting(_settings.copyWith(minListeningSeconds: v.toInt())),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Data / डेटा'),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.star,
            title: 'फेवरेट्स हटवा / Clear favorites',
            subtitle: 'सर्व favourite हटवा',
            onTap: () => _showClearFavoritesDialog(context),
            isDestructive: true,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.history,
            title: 'इतिहास हटवा / Clear history',
            subtitle: 'अलीकडे ऐकलेले हटवा',
            onTap: () => _showClearHistoryDialog(context),
            isDestructive: true,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('General / सामान्य'),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.keyboard_voice,
            title: 'Commands',
            subtitle: 'Manage voice commands',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommandsScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.bug_report,
            title: 'Debug Logs',
            subtitle: 'View app debug logs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.deepPurple,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.white, size: 28),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        value: value,
        activeColor: Colors.deepPurple,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _updateSetting(CaregiverSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    await CaregiverSettingsService().save(newSettings);
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Select Language / भाषा निवडा',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TtsService.availableLanguages.map((lang) {
            return ListTile(
              title: Text(
                lang['display']!,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                final langName = lang['display']!.toLowerCase();
                await _updateSetting(_settings.copyWith(language: langName));
                final tts = TtsService();
                await tts.setLanguage(TtsLanguage.values.firstWhere(
                  (e) => e.name == langName,
                  orElse: () => TtsLanguage.marathi,
                ));
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSpeechRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Speech Rate / बोलण्याचा वेग',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('मंद / Slow', style: TextStyle(color: Colors.white)),
              onTap: () {
                _updateSetting(_settings.copyWith(speechRate: SpeechRate.slow));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('सामान्य / Normal', style: TextStyle(color: Colors.white)),
              onTap: () {
                _updateSetting(_settings.copyWith(speechRate: SpeechRate.normal));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Default Category / श्रेणी',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingCategory.values.map((cat) {
            return ListTile(
              title: Text(
                _getCategoryLabel(cat),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                _updateSetting(_settings.copyWith(defaultCategory: cat));
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getCategoryLabel(SettingCategory cat) {
    switch (cat) {
      case SettingCategory.none:
        return 'None';
      case SettingCategory.bhakti:
        return 'Bhakti Geet';
      case SettingCategory.news:
        return 'News';
      case SettingCategory.bhav:
        return 'Bhav Geet';
    }
  }

  void _showClearFavoritesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Clear Favorites?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'सर्व favourites हटवणार? हे परत करता येणार नाही.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('नाही / Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await CaregiverSettingsService().clearFavorites();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('होय / Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Clear Recently Played?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'इतिहास हटवणार? हे परत करता येणार नाही.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('नाही / Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await CaregiverSettingsService().clearRecentlyPlayed();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('होय / Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: onTap,
      ),
    );
  }
}