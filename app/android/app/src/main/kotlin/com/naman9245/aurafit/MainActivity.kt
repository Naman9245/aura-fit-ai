package com.naman9245.aurafit

import android.Manifest
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null

    private fun canCountSteps(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACTIVITY_RECOGNITION,
            ) == PackageManager.PERMISSION_GRANTED

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == STEPS_PERMISSION) {
            permissionResult?.success(canCountSteps())
            permissionResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The phone's step sensor: whether it's there and allowed, asking to
        // use it, readings every 15 minutes, and a day's steps.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.naman9245.aurafit/steps",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(
                    mapOf(
                        "available" to StepCounter.available(this),
                        "allowed" to canCountSteps(),
                    ),
                )
                "requestPermission" -> {
                    if (canCountSteps()) {
                        result.success(true)
                    } else {
                        permissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.ACTIVITY_RECOGNITION),
                            STEPS_PERMISSION,
                        )
                    }
                }
                "start" -> {
                    StepCounter.schedule(this)
                    result.success(true)
                }
                "stepsBetween" -> {
                    val start = call.argument<Number>("start")!!.toLong()
                    val end = call.argument<Number>("end")!!.toLong()
                    val main = Handler(Looper.getMainLooper())
                    // The sensor can take a moment to answer: off the main
                    // thread, with the answer sent back on it.
                    Thread {
                        val steps = try {
                            StepCounter.readNow(this)
                            StepCounter.stepsBetween(this, start, end)
                        } catch (e: Exception) {
                            null
                        }
                        main.post { result.success(steps) }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.naman9245.aurafit/share",
        ).setMethodCallHandler { call, result ->
            if (call.method != "shareFiles") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val files = call.argument<List<Map<String, String>>>("files").orEmpty()
                val dir = File(cacheDir, "exports").apply { mkdirs() }
                val uris = ArrayList(
                    files.map { item ->
                        val name = File(item["name"] ?: "export.txt").name
                        val out = File(dir, name).apply {
                            writeText(item["content"] ?: "", Charsets.UTF_8)
                        }
                        FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            out,
                        )
                    },
                )
                val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                    type = "*/*"
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                    putExtra(Intent.EXTRA_SUBJECT, "AURA FIT AI data export")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    if (uris.isNotEmpty()) {
                        val clip = ClipData.newRawUri("export", uris.first())
                        uris.drop(1).forEach { clip.addItem(ClipData.Item(it)) }
                        clipData = clip
                    }
                }
                startActivity(Intent.createChooser(intent, "Export my data"))
                result.success(true)
            } catch (e: Exception) {
                result.error("share_failed", e.javaClass.simpleName, null)
            }
        }
    }

    private companion object {
        const val STEPS_PERMISSION = 42
    }
}
