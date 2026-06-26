package com.example.loveinloop

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "loveinloop/media_picker"
    private val shareChannelName = "loveinloop/share"
    private val requestPhotos = 4101
    private val requestMusic = 4102
    private var pendingResult: MethodChannel.Result? = null
    private var pendingProjectId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            val projectId = call.argument<String>("projectId")
            if (projectId.isNullOrBlank()) {
                result.error("missing_project", "projectId is required.", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "pickPhotos" -> openPicker(
                    result = result,
                    projectId = projectId,
                    mimeType = "image/*",
                    allowMultiple = true,
                    requestCode = requestPhotos,
                )

                "pickMusic" -> openPicker(
                    result = result,
                    projectId = projectId,
                    mimeType = "audio/*",
                    allowMultiple = false,
                    requestCode = requestMusic,
                )

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shareChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareFile" -> {
                    val path = call.argument<String>("path")
                    val subject = call.argument<String>("subject") ?: "LoveinLoop"
                    val text = call.argument<String>("text") ?: ""
                    if (path.isNullOrBlank()) {
                        result.error("missing_path", "path is required.", null)
                        return@setMethodCallHandler
                    }
                    shareFile(path, subject, text)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openPicker(
        result: MethodChannel.Result,
        projectId: String,
        mimeType: String,
        allowMultiple: Boolean,
        requestCode: Int,
    ) {
        if (pendingResult != null) {
            result.error("picker_busy", "A media picker is already open.", null)
            return
        }

        pendingResult = result
        pendingProjectId = projectId

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
        }
        startActivityForResult(intent, requestCode)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        val result = pendingResult ?: return
        val projectId = pendingProjectId
        pendingResult = null
        pendingProjectId = null

        if (resultCode != Activity.RESULT_OK || data == null || projectId == null) {
            if (requestCode == requestPhotos) {
                result.success(emptyList<String>())
            } else {
                result.success(null)
            }
            return
        }

        try {
            when (requestCode) {
                requestPhotos -> {
                    val paths = collectUris(data).map { uri ->
                        copyUriToProject(uri, projectId, "photos")
                    }
                    result.success(paths)
                }

                requestMusic -> {
                    val uri = data.data
                    if (uri == null) {
                        result.success(null)
                    } else {
                        val path = copyUriToProject(uri, projectId, "music")
                        result.success(
                            mapOf(
                                "path" to path,
                                "name" to displayName(uri),
                            ),
                        )
                    }
                }

                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("copy_failed", error.message, null)
        }
    }

    private fun collectUris(data: Intent): List<Uri> {
        val clipData = data.clipData
        if (clipData != null) {
            return (0 until clipData.itemCount).map { index ->
                clipData.getItemAt(index).uri
            }
        }

        return data.data?.let { listOf(it) } ?: emptyList()
    }

    private fun copyUriToProject(uri: Uri, projectId: String, folderName: String): String {
        val folder = File(filesDir, "loveinloop/$projectId/$folderName")
        folder.mkdirs()

        val sourceName = displayName(uri)
        val extension = sourceName.substringAfterLast('.', "")
            .takeIf { it.isNotBlank() }
            ?.let { ".$it" }
            ?: ""
        val baseName = sourceName.substringBeforeLast('.', sourceName)
        val target = File(folder, "${System.currentTimeMillis()}-$baseName$extension")

        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Could not open selected media." }
            target.outputStream().use { output -> input.copyTo(output) }
        }

        return target.absolutePath
    }

    private fun displayName(uri: Uri): String {
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(uri, null, null, null, null)
            val nameIndex = cursor?.getColumnIndex(OpenableColumns.DISPLAY_NAME) ?: -1
            if (cursor != null && cursor.moveToFirst() && nameIndex >= 0) {
                cursor.getString(nameIndex)
            } else {
                "media-${System.currentTimeMillis()}"
            }
        } finally {
            cursor?.close()
        }
    }

    private fun shareFile(path: String, subject: String, text: String) {
        val file = File(path)
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file,
        )

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        startActivity(Intent.createChooser(intent, subject))
    }
}
