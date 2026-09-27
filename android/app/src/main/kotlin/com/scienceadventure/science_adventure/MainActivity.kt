package com.scienceadventure.app

import android.media.MediaPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var sciencePlayer: MediaPlayer? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "science_adventure/sounds").setMethodCallHandler { call, result ->
            if (call.method == "stop") {
                sciencePlayer?.release(); sciencePlayer = null; result.success(null)
            } else if (call.method == "play") {
                val name = call.argument<String>("name")
                if (name !in setOf("triangle", "maracas", "trumpet", "sitar", "drum", "stone", "feather")) {
                    result.error("invalid_sound", "Unknown sound", null)
                } else {
                    try {
                        sciencePlayer?.release()
                        val player = MediaPlayer()
                        sciencePlayer = player
                        assets.openFd("flutter_assets/assets/audio/$name.wav").use { file ->
                            player.setDataSource(file.fileDescriptor, file.startOffset, file.length)
                        }
                        val volume = (call.argument<Double>("volume") ?: 0.3).coerceIn(0.0, 0.5).toFloat()
                        player.setVolume(volume, volume)
                        player.setOnCompletionListener { finished ->
                            if (sciencePlayer === finished) sciencePlayer = null
                            finished.release()
                        }
                        player.prepare(); player.start(); result.success(null)
                    } catch (e: Exception) {
                        sciencePlayer?.release(); sciencePlayer = null
                        result.error("sound_failed", "Could not play local sound", null)
                    }
                }
            } else result.notImplemented()
        }
    }
    override fun onStop() {
        sciencePlayer?.release(); sciencePlayer = null
        super.onStop()
    }
}
