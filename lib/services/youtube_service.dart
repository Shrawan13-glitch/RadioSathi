import 'package:youtube_explode_dart/youtube_explode_dart.dart';
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
  static final YouTubeService _instance = YouTubeService._internal();
  final YoutubeExplode _yt = YoutubeExplode();

  factory YouTubeService() => _instance;

  YouTubeService._internal();

  Future<List<YouTubeResult>> search(String query) async {
    try {
      AppLog.log('Searching YouTube for: $query');
      
      final searchResults = await _yt.search(query);
      
      return searchResults.take(10).map((result) {
        return YouTubeResult(
          id: result.id.value,
          title: result.title,
          thumbnail: result.thumbnails.highResUrl.isNotEmpty 
            ? result.thumbnails.highResUrl 
            : result.thumbnails.mediumResUrl,
          url: 'https://www.youtube.com/watch?v=${result.id.value}',
          duration: 0,
        );
      }).toList();
    } catch (e) {
      AppLog.log('YouTube search error: $e');
      return [];
    }
  }

  Future<StreamInfo?> getStreamUrl(String videoId) async {
    try {
      AppLog.log('Getting stream URL for video: $videoId');
      
      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streams.getManifest(videoId);
      
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        AppLog.log('No audio streams found');
        return null;
      }
      
      final audioStream = audioStreams.withHighestBitrate();
      
      return StreamInfo(
        url: audioStream.url.toString(),
        title: video.title,
        thumbnail: video.thumbnails.highResUrl.isNotEmpty 
            ? video.thumbnails.highResUrl 
            : video.thumbnails.mediumResUrl,
      );
    } catch (e) {
      AppLog.log('Get stream URL error: $e');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}