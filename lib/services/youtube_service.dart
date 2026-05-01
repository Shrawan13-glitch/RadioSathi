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

  Future<String?> getStreamUrl(String videoId) async {
    try {
      AppLog.log('Getting stream URL for video: $videoId');
      final result = await _channel.invokeMethod('getStreamUrlWithMeta', {'videoId': videoId});
      
      if (result != null && result is Map) {
        final url = result['url'] as String?;
        final isLive = result['isLive'] as bool? ?? false;
        final method = result['method'] as String? ?? 'unknown';
        
        AppLog.log('Stream result: method=$method, isLive=$isLive, url=${url?.substring(0, 50)}...');
        
        return url;
      }
      return null;
    } on PlatformException catch (e) {
      AppLog.log('Get stream URL error: ${e.message}');
      return null;
    }
  }

  Future<List<YouTubeResult>> getChannelLatestLive(String channelInput) async {
    try {
      AppLog.log('Getting latest live from channel: $channelInput');
      final result = await _channel.invokeMethod('getChannelLatestLive', {'channelInput': channelInput});
      
      if (result is List) {
        final items = result.map((item) {
          final map = Map<String, dynamic>.from(item);
          return YouTubeResult(
            id: map['id'] ?? '',
            title: map['title'] ?? '',
            thumbnail: map['thumbnail'] ?? '',
            url: map['url'] ?? '',
            duration: map['duration'] ?? 0,
          );
        }).toList();
        
        AppLog.log('Found ${items.length} videos from channel');
        return items;
      }
      return [];
    } on PlatformException catch (e) {
      AppLog.log('Get channel latest live error: ${e.message}');
      return [];
    }
  }

  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;
    
    final patterns = [
      RegExp(r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'v=([a-zA-Z0-9_-]{11})'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  static String? extractPlaylistId(String url) {
    if (url.isEmpty) return null;
    
    final patterns = [
      RegExp(r'(?:youtube\.com/playlist\?list=|youtube\.com/watch\?.*list=)([a-zA-Z0-9_-]+)'),
      RegExp(r'list=([a-zA-Z0-9_-]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final listId = match.group(1);
        if (listId != null && !listId.contains('v=')) {
          return listId;
        }
      }
    }
    return null;
  }

  Future<List<YouTubeResult>> getPlaylistVideos(String playlistId) async {
    try {
      AppLog.log('Getting playlist videos: $playlistId');
      final result = await _channel.invokeMethod('getPlaylist', {'playlistId': playlistId});
      
      if (result is List) {
        return result.map((item) {
          final map = Map<String, dynamic>.from(item);
          return YouTubeResult.fromMap(map);
        }).toList();
      }
      return [];
    } on PlatformException catch (e) {
      AppLog.log('Get playlist error: ${e.message}');
      return [];
    }
  }

  Future<List<YouTubeResult>> getVideosFromLink(String url) async {
    final videoId = extractVideoId(url);
    if (videoId != null) {
      final streamUrl = await getStreamUrl(videoId);
      if (streamUrl != null) {
        return [
          YouTubeResult(
            id: videoId,
            title: 'Direct Video',
            thumbnail: 'https://img.youtube.com/vi/$videoId/0.jpg',
            url: streamUrl,
            duration: 0,
          ),
        ];
      }
    }

    final playlistId = extractPlaylistId(url);
    if (playlistId != null) {
      return getPlaylistVideos(playlistId);
    }

    return [];
  }
}