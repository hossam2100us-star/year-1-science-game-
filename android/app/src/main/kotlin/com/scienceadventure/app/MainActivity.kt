package com.scienceadventure.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /** The sound that is playing or preparing, and the reply still owed for it. */
    private var sciencePlayer: MediaPlayer? = null
    private var pendingReply: ((Boolean) -> Unit)? = null

    /** Only these bundled files can be opened: blocks path traversal. */
    private val allowedSounds = setOf(
        "triangle", "maracas", "trumpet", "sitar", "drum", "stone",
        "feather", "sticks", "cat_steps", "whisper", "door", "thunder",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "science_adventure/sounds").setMethodCallHandler { call, result ->
            when (call.method) {
                "stop" -> {
                    releasePlayer()
                    result.success(null)
                }
                "play" -> {
                    val name = call.argument<String>("name")
                    if (name !in allowedSounds) {
                        result.error("invalid_sound", "Unknown sound", null)
                    } else {
                        play(name!!, call.argument<Double>("volume") ?: 0.3, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
        // The update check (ADR-0020): this app's version, and the family
        // server's download page opened in the browser (https only).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "science_adventure/app").setMethodCallHandler { call, result ->
            when (call.method) {
                "version" -> {
                    val info = packageManager.getPackageInfo(packageName, 0)
                    val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        info.longVersionCode
                    } else {
                        @Suppress("DEPRECATION") info.versionCode.toLong()
                    }
                    result.success(mapOf("code" to code, "name" to (info.versionName ?: "")))
                }
                "openUrl" -> {
                    val uri = Uri.parse(call.argument<String>("url") ?: "")
                    if (uri.scheme != "https" || uri.host.isNullOrEmpty()) {
                        result.error("invalid_url", "Only https pages can be opened", null)
                    } else {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            result.success(true)
                        } catch (e: ActivityNotFoundException) {
                            result.success(false)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Prepares off the main thread with prepareAsync (AUD-020) and answers
     * the Dart call exactly once: when playback starts, when preparation
     * fails, or when a newer sound or a stop supersedes this one.
     */
    private fun play(name: String, requestedVolume: Double, result: MethodChannel.Result) {
        releasePlayer()
        val player = MediaPlayer()
        var replied = false
        val reply: (Boolean) -> Unit = { ok ->
            if (!replied) {
                replied = true
                if (ok) result.success(null) else result.error("sound_failed", "Could not play local sound", null)
            }
        }
        sciencePlayer = player
        pendingReply = reply
        try {
            assets.openFd("flutter_assets/assets/audio/$name.wav").use { file ->
                player.setDataSource(file.fileDescriptor, file.startOffset, file.length)
            }
            val volume = requestedVolume.coerceIn(0.0, 0.5).toFloat()
            player.setVolume(volume, volume)
            player.setOnPreparedListener { prepared ->
                if (sciencePlayer === prepared) {
                    prepared.start()
                    pendingReply = null
                }
                reply(true)
            }
            player.setOnErrorListener { failed, _, _ ->
                if (sciencePlayer === failed) {
                    sciencePlayer = null
                    pendingReply = null
                }
                failed.release()
                reply(false)
                true
            }
            player.setOnCompletionListener { finished ->
                if (sciencePlayer === finished) sciencePlayer = null
                finished.release()
            }
            player.prepareAsync()
        } catch (e: Exception) {
            if (sciencePlayer === player) {
                sciencePlayer = null
                pendingReply = null
            }
            player.release()
            reply(false)
        }
    }

    /** Releases the current sound; a superseded call is answered as done. */
    private fun releasePlayer() {
        sciencePlayer?.release()
        sciencePlayer = null
        pendingReply?.invoke(true)
        pendingReply = null
    }

    override fun onStop() {
        releasePlayer()
        super.onStop()
    }
}
