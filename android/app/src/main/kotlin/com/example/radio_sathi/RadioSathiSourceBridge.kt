package com.example.radio_sathi

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class RadioSathiSourceBridge(
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.example.radio_sathi/newpipe")
    private val executor = Executors.newSingleThreadExecutor()
    private val extractorCatalog = ExtractorCatalog()

    fun register() {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        executor.execute {
            try {
                when (call.method) {
                    "search" -> {
                        val query = call.argument<String>("query").orEmpty()
                        val searchResults = extractorCatalog.search(query)
                        result.success(searchResults)
                    }
                    "getStreamUrl" -> {
                        val videoId = call.argument<String>("videoId").orEmpty()
                        val streamUrl = extractorCatalog.getStreamUrl(videoId)
                        if (streamUrl != null) {
                            result.success(streamUrl)
                        } else {
                            result.error("STREAM_ERROR", "Could not get stream URL", null)
                        }
                    }
                    "getStreamUrlWithMeta" -> {
                        val videoId = call.argument<String>("videoId").orEmpty()
                        val streamResult = extractorCatalog.getStreamUrlWithMeta(videoId)
                        result.success(mapOf(
                            "url" to streamResult.url,
                            "isLive" to streamResult.isLive,
                            "method" to streamResult.method
                        ))
                    }
                    "getChannelLatestLive" -> {
                        val channelInput = call.argument<String>("channelInput").orEmpty()
                        val results = extractorCatalog.getChannelLatestLive(channelInput)
                        result.success(results)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Throwable) {
                result.error("SOURCE_ERROR", error.message, null)
            }
        }
    }
}