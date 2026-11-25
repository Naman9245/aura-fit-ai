package com.naman9245.aurafit

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
}
