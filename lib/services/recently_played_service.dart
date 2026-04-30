import 'package:hive/hive.dart';

class RecentlyPlayedItem {
  final String id;
  final String title;
  final String query;
  final DateTime playedAt;
  final bool isYouTube;

  RecentlyPlayedItem({
    required this.id,
    required this.title,
    required this.query,
    required this.playedAt,
    required this.isYouTube,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'query': query,
        'playedAt': playedAt.toIso8601String(),
        'isYouTube': isYouTube,
      };

  factory RecentlyPlayedItem.fromMap(Map<dynamic, dynamic> map) => RecentlyPlayedItem(
        id: map['id'] as String,
        title: map['title'] as String,
        query: map['query'] as String,
        playedAt: DateTime.parse(map['playedAt'] as String),
        isYouTube: map['isYouTube'] as bool,
      );
}

class RecentlyPlayedService {
  static const String _boxName = 'recently_played';
  static const int _maxItems = 20;

  static final RecentlyPlayedService _instance = RecentlyPlayedService._internal();
  factory RecentlyPlayedService() => _instance;
  RecentlyPlayedService._internal();

  Box<Map>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<void> addItem({
    required String id,
    required String title,
    required String query,
    required bool isYouTube,
  }) async {
    await init();

    final items = _getAllItems();
    if (items.isNotEmpty && items.first.id == id) {
      return;
    }

    final newItem = RecentlyPlayedItem(
      id: id,
      title: title,
      query: query,
      playedAt: DateTime.now(),
      isYouTube: isYouTube,
    );

    await _box!.add(newItem.toMap());

    if (_box!.length > _maxItems) {
      final keysToRemove = _box!.keys.toList().take(_box!.length - _maxItems).toList();
      for (final key in keysToRemove) {
        await _box!.delete(key);
      }
    }
  }

  List<RecentlyPlayedItem> _getAllItems() {
    if (_box == null || _box!.isEmpty) return [];
    return _box!.values
        .map((v) => RecentlyPlayedItem.fromMap(v))
        .toList()
        .reversed
        .toList();
  }

  List<RecentlyPlayedItem> getRecentItems() {
    return _getAllItems();
  }

  RecentlyPlayedItem? getLastItem() {
    final items = _getAllItems();
    return items.isNotEmpty ? items.first : null;
  }

  bool hasRecentItems() {
    return _getAllItems().isNotEmpty;
  }

  Future<void> clear() async {
    await init();
    await _box!.clear();
  }
}