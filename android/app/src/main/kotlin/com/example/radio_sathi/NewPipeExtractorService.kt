package com.example.radio_sathi

import android.content.Context
import android.util.Log
import org.schabi.newpipe.NewPipe
import org.schabi.newpipe.extractor.Downloader
import org.schabi.newpipe.extractor.StreamingService
import org.schabi.newpipe.extractor.services.youtube.YoutubeService
import org.schabi.newpipe.extractor.search.SearchExtractor
import org.schabi.newpipe.extractor.search.SearchQueryHandler
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.ListExtractor
import org.schabi.newpipe.extractor.InfoItem
import org.schabi.newpipe.extractor.NewPipeException
import org.schabi.newpipe.extractor.localization.Localization
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.*
import java.util.concurrent.Executors

class SimpleDownloader : Downloader {
    override fun download(url: String): String {
        Log.d("Downloader", "Downloading: $url")
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = "GET"
        conn.setRequestProperty("User-Agent", "Mozilla/5.0")
        return conn.inputStream.bufferedReader().readText()
    }

    override fun downloadWithHeaders(url: String, headers: Map<String, String>): String {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = "GET"
        headers.forEach { (k, v) -> conn.setRequestProperty(k, v) }
        return conn.inputStream.bufferedReader().readText()
    }

    override fun getProgressData(request: Downloader?): InputStream? = null

    override fun deleteCookies(url: String) {}
    override fun setCookies(url: String, cookies: List<String>) {}
    override fun getCookies(url: String): List<String> = emptyList()
}

class NewPipeExtractorService(private val context: Context) {
    private val TAG = "NewPipeExtractor"
    private val executor = Executors.newSingleThreadExecutor()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var youtubeService: YoutubeService? = null

    init {
        try {
            NewPipe.init(SimpleDownloader(), Localization.fromCountryCode("US"))
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

                val searchQH = service.searchQHFactory.fromQuery(query)
                val extractor = SearchExtractor(service, searchQH)
                
                extractor.fetchPage()
                
                val page = extractor.initialPage
                val items = page.items
                
                val results = mutableListOf<Map<String, Any>>()
                
                for (item in items) {
                    when (item) {
                        is org.schabi.newpipe.extractor.stream.StreamInfoItem -> {
                            results.add(mapOf(
                                "id" to (item.id ?: ""),
                                "title" to (item.name ?: ""),
                                "thumbnail" to (item.thumbnailUrl ?: ""),
                                "url" to (item.url ?: ""),
                                "duration" to (item.duration ?: 0)
                            ))
                        }
                    }
                }
                
                callback("success", results)
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
                
                val streamInfo = extractor
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