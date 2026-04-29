package com.example.radio_sathi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        RadioSathiSourceBridge(flutterEngine.dartExecutor.binaryMessenger).register()
    }
}