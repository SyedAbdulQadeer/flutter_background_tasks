package com.example.android_background_task_manager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.android_background_task_manager.AndroidBackgroundTaskManagerPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AndroidBackgroundTaskManagerPlugin())
    }
}