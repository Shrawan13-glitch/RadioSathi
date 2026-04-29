package com.example.radio_sathi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.radio_sathi/newpipe"
    private var newPipeService: NewPipeExtractorService? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        newPipeService = NewPipeExtractorService(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "search" -> {
                    val query = call.argument<String>("query") ?: ""
                    newPipeService?.search(query) { status, items ->
                        if (status == "success") {
                            result.success(items)
                        } else {
                            result.error("SEARCH_ERROR", status, null)
                        }
                    }
                }
                "getStreamUrl" -> {
                    val videoId = call.argument<String>("videoId") ?: ""
                    newPipeService?.getStreamUrl(videoId) { status, streamData ->
                        if (status == "success" && streamData != null) {
                            result.success(streamData)
                        } else {
                            result.error("STREAM_ERROR", status, null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        newPipeService?.dispose()
        super.onDestroy()
    }
}