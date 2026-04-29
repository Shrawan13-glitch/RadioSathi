import 'package:flutter/services.dart';
import 'app_log.dart';

class YouTubeResult {
  final String id;
  final String title;
  final String thumbnail;
  final String url;
  final int duration;

  YouTubeResult({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.url,
    required this.duration,
  });

  factory YouTubeResult.fromMap(Map<String, dynamic> map) {
    return YouTubeResult(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      url: map['url'] ?? '',
      duration: map['duration'] ?? 0,
    );
  }
}

class StreamInfo {
  final String url;
  final String title;
  final String thumbnail;

  StreamInfo({
    required this.url,
    required this.title,
    required this.thumbnail,
  });

  factory StreamInfo.fromString(String data) {
    final parts = data.split('|');
    return StreamInfo(
      url: parts.isNotEmpty ? parts[0] : '',
      title: parts.length > 1 ? parts[1] : '',
      thumbnail: parts.length > 2 ? parts[2] : '',
    );
  }
}

class YouTubeService {
  static const _channel = MethodChannel('com.example.radio_sathi/newpipe');
  static final YouTubeService _instance = YouTubeService._internal();

  factory YouTubeService() => _instance;

  YouTubeService._internal();

  Future<List<YouTubeResult>> search(String query) async {
    try {
      AppLog.log('Searching YouTube for: $query');
      final result = await _channel.invokeMethod('search', {'query': query});
      
      if (result is List) {
        return result.map((item) {
          final map = Map<String, dynamic>.from(item);
          return YouTubeResult.fromMap(map);
        }).toList();
      }
      return [];
    } on PlatformException catch (e) {
      AppLog.log('YouTube search error: ${e.message}');
      return [];
    }
  }

  Future<StreamInfo?> getStreamUrl(String videoId) async {
    try {
      AppLog.log('Getting stream URL for video: $videoId');
      final result = await _channel.invokeMethod('getStreamUrl', {'videoId': videoId});
      
      if (result != null && result is String) {
        return StreamInfo.fromString(result);
      }
      return null;
    } on PlatformException catch (e) {
      AppLog.log('Get stream URL error: ${e.message}');
      return null;
    }
  }
}