package com.hafezeh.hafezeh

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.hafezeh.app/vocabulary"
    private val preferencesName = "hafezeh_vocabulary"
    private val vocabularyKey = "cards_json"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val preferences = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                when (call.method) {
                    "load" -> result.success(preferences.getString(vocabularyKey, null))
                    "save" -> {
                        val data = call.argument<String>("data")
                        if (data == null) {
                            result.error("invalid_data", "Vocabulary data is missing.", null)
                        } else {
                            preferences.edit().putString(vocabularyKey, data).apply()
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
