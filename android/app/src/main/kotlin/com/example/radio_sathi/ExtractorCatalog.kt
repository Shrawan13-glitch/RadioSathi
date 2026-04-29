package com.example.radio_sathi

import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.search.SearchInfo
import org.schabi.newpipe.extractor.stream.StreamInfo

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

    fun getStreamUrl(videoId: String): String? {
        val url = "https://www.youtube.com/watch?v=$videoId"
        val info = StreamInfo.getInfo(service, url)
        
        // First try direct audio streams (not HLS)
        val directAudioStream = info.audioStreams
            .filter { it.isUrl && it.deliveryMethod != org.schabi.newpipe.extractor.stream.DeliveryMethod.HLS }
            .maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }
        
        if (directAudioStream != null) {
            return directAudioStream.url
        }
        
        // Fallback to any audio stream
        val anyAudioStream = info.audioStreams.maxByOrNull { maxOf(it.bitrate, it.averageBitrate) }
        if (anyAudioStream != null) {
            return anyAudioStream.url
        }
        
        // Last fallback: try HLS URL
        return info.hlsUrl
    }
}