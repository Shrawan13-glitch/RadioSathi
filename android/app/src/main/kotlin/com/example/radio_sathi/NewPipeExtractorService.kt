package com.example.radio_sathi

import android.content.Context
import android.util.Log
import org.schabi.newpipe.NewPipe
import org.schabi.newpipe.extractor.Info
import org.schabi.newpipe.extractor.SearchEngine
import org.schabi.newpipe.extractor.StreamingService
import org.schabi.newpipe.extractor.services.youtube.YoutubeService
import org.schabi.newpipe.extractor.services.youtube.linkHandler.YoutubeSearchQueryHandlerFactory
import org.schabi.newpipe.extractor.stream.Stream
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.stream.StreamType
import org.schabi.newpipe.extractor.*
import kotlinx.coroutines.*
import java.util.concurrent.Executors

class NewPipeExtractorService(private val context: Context) {
    private val TAG = "NewPipeExtractor"
    private var youtubeService: YoutubeService? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    init {
        try {
            NewPipe.init(context)
            youtubeService = YoutubeService()
            Log.d(TAG, "NewPipe initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize NewPipe: ${e.message}")
        }
    }

    fun search(query: String, callback: (String, List<Map<String, Any>>) -> Unit) {
        scope.launch {
            try {
                val service = youtubeService ?: run {
                    callback("Error: Service not initialized", emptyList())
                    return@launch
                }

                val searchFactory = service.searchQueueFactory
                val searchQuery = searchFactory.fromQuery(query, arrayOf(YoutubeSearchQueryHandlerFactory.ITEMS))
                
                val handler = service.searchHandler
                val results = handler.getSearchResult(searchQuery)
                
                val items = mutableListOf<Map<String, Any>>()
                
                for (item in results.relatedItems) {
                    try {
                        if (item is StreamingService.LocalItem) {
                            val streamItem = item as? org.schabi.newpipe.extractor.stream.StreamSummary
                            if (streamItem != null) {
                                val thumbnail = if (streamItem.thumbnails != null && streamItem.thumbnails!!.isNotEmpty()) {
                                    streamItem.thumbnails!![0].url
                                } else ""
                                
                                items.add(mapOf(
                                    "id" to streamItem.id,
                                    "title" to (streamItem.name ?: ""),
                                    "thumbnail" to thumbnail,
                                    "url" to streamItem.url,
                                    "duration" to (streamItem.duration ?: 0)
                                ))
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error processing item: ${e.message}")
                    }
                }
                
                callback("success", items)
            } catch (e: Exception) {
                Log.e(TAG, "Search error: ${e.message}")
                callback("Error: ${e.message}", emptyList())
            }
        }
    }

    fun getStreamUrl(videoId: String, callback: (String, String?) -> Unit) {
        scope.launch {
            try {
                val service = youtubeService ?: run {
                    callback("Error: Service not initialized", null)
                    return@launch
                }

                val extractor = service.getStreamExtractor("https://www.youtube.com/watch?v=$videoId")
                extractor.fetchPage()
                val streamInfo = extractor.apply {
                    StreamInfo.getInfo(this)
                }

                val audioStream = streamInfo.audioStreams
                    .filter { it.format == Stream.Format.MPEG }
                    .minByOrNull { it.bitrate }

                val bestStream = streamInfo.streams
                    .filter { it.streamType == StreamType.AUDIO }
                    .maxByOrNull { it.bitrate }

                val streamUrl = audioStream?.url ?: bestStream?.url
                
                if (streamUrl != null) {
                    val title = streamInfo.title
                    val thumbnail = if (streamInfo.thumbnails.isNotEmpty()) streamInfo.thumbnails[0].url else ""
                    val result = "$streamUrl|$title|$thumbnail"
                    callback("success", result)
                } else {
                    callback("Error: No audio stream found", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Get stream URL error: ${e.message}")
                callback("Error: ${e.message}", null)
            }
        }
    }

    fun dispose() {
        scope.cancel()
        executor.shutdown()
    }
}