package com.example.radio_sathi

import android.util.Log
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.search.SearchInfo
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.stream.StreamType

class ExtractorCatalog(
    private val downloader: OkHttpDownloader = OkHttpDownloader(),
) {
    private val service = ServiceList.YouTube
    private val TAG = "ExtractorCatalog"

    init {
        org.schabi.newpipe.extractor.NewPipe.init(downloader)
    }

    fun search(query: String): List<Map<String, Any?>> {
        if (query.isBlank()) {
            return emptyList()
        }

        val handler = service.searchQHFactory.fromQuery(query)
        val info = SearchInfo.getInfo(service, handler)
        
        return info.relatedItems
            .filterIsInstance<org.schabi.newpipe.extractor.stream.StreamInfoItem>()
            .map { item ->
                val videoId = item.url.substringAfter("v=").substringBefore("&")
                mapOf(
                    "id" to videoId,
                    "title" to item.name,
                    "thumbnail" to (item.thumbnails.firstOrNull()?.url ?: ""),
                    "url" to item.url,
                    "duration" to (item.duration ?: 0)
                )
            }
    }

    fun getStreamUrl(videoId: String): String? {
        try {
            val url = "https://www.youtube.com/watch?v=$videoId"
            val info = StreamInfo.getInfo(service, url)
            
            Log.d(TAG, "Stream type: ${info.streamType}")
            Log.d(TAG, "Has HLS: ${info.hlsUrl != null}")
            Log.d(TAG, "Audio streams count: ${info.audioStreams.size}")
            
            // Check if it's a live stream - use HLS directly
            if (info.streamType == StreamType.LIVE_STREAM || info.streamType == StreamType.AUDIO_LIVE_STREAM) {
                Log.d(TAG, "Detected live stream, using HLS")
                return info.hlsUrl
            }
            
            // First try direct audio streams (not HLS)
            val directAudioStream = info.audioStreams
                .filter { it.isUrl && it.deliveryMethod != org.schabi.newpipe.extractor.stream.DeliveryMethod.HLS }
                .maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }
            
            if (directAudioStream != null) {
                Log.d(TAG, "Using direct audio stream")
                return directAudioStream.url
            }
            
            // Fallback to any audio stream
            val anyAudioStream = info.audioStreams.maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }
            if (anyAudioStream != null) {
                Log.d(TAG, "Using any audio stream")
                return anyAudioStream.url
            }
            
            // Last fallback: try HLS URL
            if (info.hlsUrl != null) {
                Log.d(TAG, "Using HLS fallback")
                return info.hlsUrl
            }
            
            Log.d(TAG, "No stream URL found")
            return null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting stream URL: ${e.message}")
            return null
        }
    }
}