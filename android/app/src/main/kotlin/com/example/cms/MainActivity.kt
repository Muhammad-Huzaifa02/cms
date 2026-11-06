package com.example.cms

import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "cms/device_integrity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Sensitive screen privacy shield: prevents screenshots and blanks out
        // the app's preview in the recent apps / task switcher carousel to protect
        // banking customer CNIC, phone, and account numbers.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRooted" -> result.success(isDeviceRooted())
                "isDevMode" -> result.success(isDevMode())
                else -> result.notImplemented()
            }
        }
    }

    private fun isDevMode(): Boolean {
        return try {
            Settings.Secure.getInt(
                contentResolver,
                Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
            ) != 0
        } catch (_: Throwable) {
            false
        }
    }

    private fun isDeviceRooted(): Boolean {
        return checkBuildTags() ||
                checkSuBinaryExistence() ||
                checkWhichSu() ||
                checkReadWriteMounts()
    }

    private fun checkBuildTags(): Boolean {
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkSuBinaryExistence(): Boolean {
        val commonPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su",
            "/system/xbin/busybox",
            "/system/bin/busybox"
        )
        for (path in commonPaths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkWhichSu(): Boolean {
        var process: Process? = null
        return try {
            process = Runtime.getRuntime().exec(arrayOf("which", "su"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            reader.readLine() != null
        } catch (_: Throwable) {
            false
        } finally {
            process?.destroy()
        }
    }

    private fun checkReadWriteMounts(): Boolean {
        return try {
            val file = File("/proc/mounts")
            if (!file.exists()) return false

            file.bufferedReader().useLines { lines ->
                lines.any { line ->
                    val columns = line.split(" ")
                    if (columns.size >= 4) {
                        val mountPoint = columns[1]
                        val mountOptions = columns[3].split(",")
                        (mountPoint == "/system" || mountPoint == "/system_root" || mountPoint == "/vendor") &&
                                mountOptions.contains("rw")
                    } else {
                        false
                    }
                }
            }
        } catch (_: Throwable) {
            false
        }
    }
}

