package com.example.radio_sathi

import android.content.Context
import android.util.Log
import org.schabi.newpipe.NewPipe
import org.schabi.newpipe.extractor.NewPipeExtractor
import org.schabi.newpipe.extractor.StreamingService
import org.schabi.newpipe.extractor.services.youtube.YoutubeService
import org.schabi.newpipe.extractor.search.SearchExtractor
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.stream.AudioStream
import org.schabi.newpipe.extractor.exceptions.ExtractionException
import org.schabi.newpipe.extractor.LinkHandler
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

                val searchFactory = service.searchLinkHandlerFactory
                val linkHandler = searchFactory.getIdFromQuery(query)
                
                val extractor = service.getSearchExtractor(linkHandler)
                extractor.fetchPage()
                extractor.page = extractor.getPage(extractor.url)
                
                val items = mutableListOf<Map<String, Any>>()
                
                val relatedItems = extractor.relatedItems
                for (item in relatedItems) {
                    try {
                        val streamInfoItem = item
                        items.add(mapOf(
                            "id" to streamInfoItem.id,
                            "title" to (streamInfoItem.name ?: ""),
                            "thumbnail" to (streamInfoItem.thumbnailUrl ?: ""),
                            "url" to (streamInfoItem.url ?: ""),
                            "duration" to 0
                        ))
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

                val linkHandlerFactory = service.linkHandlerFactory
                val linkHandler = linkHandlerFactory.fromId(videoId)
                
                val extractor = service.getStreamExtractor(linkHandler)
                extractor.fetchPage()
                
                val streamInfo = extractor.initialInformation ?: extractor as StreamInfo

                val audioStreams = streamInfo.audioStreams
                val audioStream = audioStreams.firstOrNull()

                if (audioStream != null) {
                    val title = streamInfo.name
                    val thumbnail = streamInfo.thumbnailUrl ?: ""
                    val result = "${audioStream.url}|$title|$thumbnail"
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