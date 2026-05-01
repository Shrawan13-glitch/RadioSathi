package com.example.radio_sathi

import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.search.SearchInfo
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.stream.StreamType

class ExtractorCatalog(
    private val downloader: OkHttpDownloader = OkHttpDownloader(),
) {
    private val service = ServiceList.YouTube

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

    data class StreamResult(val url: String?, val isLive: Boolean, val method: String)

    fun getStreamUrlWithMeta(videoId: String): StreamResult {
        try {
            val url = "https://www.youtube.com/watch?v=$videoId"
            val info = StreamInfo.getInfo(service, url)
            
            val isLive = info.streamType == StreamType.LIVE_STREAM || info.streamType == StreamType.AUDIO_LIVE_STREAM
            
            // Check if it's a live stream - use HLS directly
            if (isLive) {
                return StreamResult(info.hlsUrl, true, "live_hls")
            }
            
            // First try direct audio streams (not HLS)
            val directAudioStream = info.audioStreams
                .filter { it.isUrl && it.deliveryMethod != org.schabi.newpipe.extractor.stream.DeliveryMethod.HLS }
                .maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }
            
            if (directAudioStream != null) {
                return StreamResult(directAudioStream.url, false, "direct_audio")
            }
            
            // Fallback to any audio stream
            val anyAudioStream = info.audioStreams.maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }
            if (anyAudioStream != null) {
                return StreamResult(anyAudioStream.url, false, "any_audio")
            }
            
            // Last fallback: try HLS URL (usually not live at this point)
            if (info.hlsUrl != null) {
                return StreamResult(info.hlsUrl, false, "hls_fallback")
            }
            
            return StreamResult(null, false, "none")
        } catch (e: Exception) {
            return StreamResult(null, false, "error: ${e.message}")
        }
    }

    fun getStreamUrl(videoId: String): String? {
        return getStreamUrlWithMeta(videoId).url
    }

    fun getChannelLatestLive(channelInput: String): List<Map<String, Any?>> {
        try {
            // Search for the channel's latest videos using search
            val query = channelInput.removePrefix("@")
            val handler = service.searchQHFactory.fromQuery(query)
            val searchInfo = SearchInfo.getInfo(service, handler)
            
            // Get items and filter for this channel
            val items = searchInfo.relatedItems
                .filterIsInstance<org.schabi.newpipe.extractor.stream.StreamInfoItem>()
                .take(20)
            
            return items.take(10).map { item ->
                val videoId = item.url.substringAfter("v=").substringBefore("&")
                mapOf(
                    "id" to videoId,
                    "title" to item.name,
                    "thumbnail" to (item.thumbnails.firstOrNull()?.url ?: ""),
                    "url" to item.url,
                    "duration" to (item.duration ?: 0),
                    "isLive" to false
                )
            }
        } catch (e: Exception) {
            return emptyList()
        }
    }
}