package com.example.loveinloop

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer

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
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    if (path.isNullOrBlank()) {
                        result.error("missing_path", "path is required.", null)
                        return@setMethodCallHandler
                    }
                    shareFile(path, subject, text, mimeType)
                    result.success(null)
                }

                "createShareVideo" -> {
                    try {
                        @Suppress("UNCHECKED_CAST")
                        val project = call.arguments as? Map<String, Any?>
                        if (project == null) {
                            result.error("missing_project", "project data is required.", null)
                            return@setMethodCallHandler
                        }
                        result.success(createShareVideo(project))
                    } catch (error: Exception) {
                        result.error("video_export_failed", error.message, null)
                    }
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

    private fun shareFile(path: String, subject: String, text: String, mimeType: String) {
        val file = File(path)
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file,
        )

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        startActivity(Intent.createChooser(intent, subject))
    }

    private fun createShareVideo(project: Map<String, Any?>): String {
        val exports = File(filesDir, "loveinloop/exports")
        exports.mkdirs()

        val title = (project["title"] as? String).orEmpty().ifBlank { "Surpresa LoveinLoop" }
        val safeTitle = title
            .lowercase()
            .replace(Regex("[^a-z0-9]+"), "-")
            .trim('-')
            .ifBlank { "surpresa" }
        val exportId = System.currentTimeMillis()
        val videoOnlyOutput = File(exports, "$safeTitle-video-$exportId.mp4")
        val output = File(exports, "$safeTitle-$exportId.mp4")

        @Suppress("UNCHECKED_CAST")
        val photos = (project["photos"] as? List<Map<String, Any?>>).orEmpty()
            .filter { it["isAsset"] != true }
            .mapNotNull { it["path"] as? String }
            .filter { File(it).exists() }
            .take(8)

        val opening = (project["openingMessage"] as? String).orEmpty()
            .ifBlank { "Preparei uma surpresa para você." }
        val closingCall = (project["questionText"] as? String).orEmpty()
            .ifBlank { "Posso te mostrar o quanto você é especial para mim?" }
        val finalMessage = (project["yesMessage"] as? String).orEmpty()
            .ifBlank { "Obrigado por fazer parte da minha vida." }
        val recipient = (project["recipientName"] as? String).orEmpty().ifBlank { "Pessoa especial" }
        @Suppress("UNCHECKED_CAST")
        val music = project["music"] as? Map<String, Any?>
        val musicType = music?.get("type") as? String
        val musicPath = music?.get("path") as? String
        val audioFile = musicPath
            ?.takeIf { musicType != "asset" && musicType != "none" }
            ?.let { File(it) }
            ?.takeIf { it.exists() }

        val renderer = ShareVideoRenderer(videoOnlyOutput)
        renderer.addTextScene(title, "Para $recipient", opening, 2)

        if (photos.isEmpty()) {
            renderer.addTextScene("Nossas memórias", "Adicione suas fotos no LoveinLoop", closingCall, 2)
        } else {
            photos.forEachIndexed { index, path ->
                renderer.addPhotoScene(path, "Momento ${index + 1} de ${photos.size}", 2)
            }
        }

        renderer.addTextScene("Fechamento", closingCall, "Uma última mensagem para você.", 3)
        renderer.addFinalMessageScene(finalMessage, 3)
        renderer.finish()

        if (audioFile != null && muxVideoWithAudio(videoOnlyOutput, audioFile, output, renderer.durationUs())) {
            videoOnlyOutput.delete()
            return output.absolutePath
        }

        return videoOnlyOutput.absolutePath
    }

    private fun muxVideoWithAudio(
        videoFile: File,
        audioFile: File,
        outputFile: File,
        videoDurationUs: Long,
    ): Boolean {
        val videoExtractor = MediaExtractor()
        val audioExtractor = MediaExtractor()
        var muxer: MediaMuxer? = null

        return try {
            videoExtractor.setDataSource(videoFile.absolutePath)
            audioExtractor.setDataSource(audioFile.absolutePath)

            val videoTrack = findTrack(videoExtractor, "video/")
            val audioTrack = findTrack(audioExtractor, "audio/")
            if (videoTrack < 0 || audioTrack < 0) {
                return false
            }

            videoExtractor.selectTrack(videoTrack)
            audioExtractor.selectTrack(audioTrack)
            val videoFormat = videoExtractor.getTrackFormat(videoTrack)
            val audioFormat = audioExtractor.getTrackFormat(audioTrack)
            val audioMime = audioFormat.getString(MediaFormat.KEY_MIME).orEmpty()
            if (audioMime != "audio/mp4a-latm" && audioMime != "audio/mpeg") {
                return false
            }

            muxer = MediaMuxer(outputFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val muxerVideoTrack = muxer.addTrack(videoFormat)
            val muxerAudioTrack = muxer.addTrack(audioFormat)
            muxer.start()

            writeTrack(videoExtractor, muxer, muxerVideoTrack, Long.MAX_VALUE)
            writeTrack(audioExtractor, muxer, muxerAudioTrack, videoDurationUs)
            true
        } catch (_: Exception) {
            outputFile.delete()
            false
        } finally {
            try {
                muxer?.stop()
            } catch (_: Exception) {
            }
            try {
                muxer?.release()
            } catch (_: Exception) {
            }
            videoExtractor.release()
            audioExtractor.release()
        }
    }

    private fun findTrack(extractor: MediaExtractor, mimePrefix: String): Int {
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME).orEmpty()
            if (mime.startsWith(mimePrefix)) {
                return index
            }
        }
        return -1
    }

    private fun writeTrack(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        muxerTrack: Int,
        maxDurationUs: Long,
    ) {
        val buffer = ByteBuffer.allocate(1024 * 1024)
        val info = MediaCodec.BufferInfo()
        val firstSampleTime = extractor.sampleTime.takeIf { it >= 0 } ?: 0L

        while (true) {
            val sampleTime = extractor.sampleTime
            if (sampleTime < 0) {
                break
            }

            val presentationTimeUs = sampleTime - firstSampleTime
            if (presentationTimeUs > maxDurationUs) {
                break
            }

            val sampleSize = extractor.readSampleData(buffer, 0)
            if (sampleSize < 0) {
                break
            }

            info.set(
                0,
                sampleSize,
                presentationTimeUs,
                extractor.sampleFlags,
            )
            muxer.writeSampleData(muxerTrack, buffer, info)
            buffer.clear()
            extractor.advance()
        }
    }

    private class ShareVideoRenderer(private val output: File) {
        private val width = 540
        private val height = 960
        private val frameRate = 6
        private val frameDurationUs = 1_000_000L / frameRate
        private val frameBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        private val frameCanvas = Canvas(frameBitmap)
        private val encoder: MediaCodec
        private val colorFormat: Int
        private val muxer: MediaMuxer
        private var trackIndex = -1
        private var muxerStarted = false
        private var frameIndex = 0L

        init {
            encoder = MediaCodec.createEncoderByType("video/avc")
            colorFormat = selectColorFormat(
                encoder.codecInfo
                    .getCapabilitiesForType("video/avc")
                    .colorFormats,
            )
            val format = MediaFormat.createVideoFormat("video/avc", width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, colorFormat)
                setInteger(MediaFormat.KEY_BIT_RATE, 1_200_000)
                setInteger(MediaFormat.KEY_FRAME_RATE, frameRate)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            }
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            encoder.start()
        }

        fun addTextScene(title: String, subtitle: String, body: String, seconds: Int) {
            repeat(seconds * frameRate) {
                drawBackground()
                drawCenteredText(title, subtitle, body)
                encodeFrame()
            }
        }

        fun addPhotoScene(path: String, label: String, seconds: Int) {
            val photo = decodeScaledBitmap(path)
            repeat(seconds * frameRate) {
                drawBackground()
                if (photo != null) {
                    drawPhoto(photo)
                }
                drawTopLabel(label)
                encodeFrame()
            }
            photo?.recycle()
        }

        fun addFinalMessageScene(message: String, seconds: Int) {
            repeat(seconds * frameRate) {
                drawBackground()
                drawFinalMessageCard(message)
                encodeFrame()
            }
        }

        fun finish() {
            val inputBufferId = encoder.dequeueInputBuffer(10_000)
            if (inputBufferId >= 0) {
                encoder.queueInputBuffer(
                    inputBufferId,
                    0,
                    0,
                    frameIndex * frameDurationUs,
                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                )
            }
            drainEncoder(true)
            encoder.stop()
            encoder.release()
            if (muxerStarted) {
                muxer.stop()
            }
            muxer.release()
            frameBitmap.recycle()
        }

        fun durationUs(): Long {
            return frameIndex * frameDurationUs
        }

        private fun encodeFrame() {
            val inputBufferId = encoder.dequeueInputBuffer(10_000)
            if (inputBufferId < 0) {
                drainEncoder(false)
                return
            }

            val inputBuffer = encoder.getInputBuffer(inputBufferId) ?: return
            inputBuffer.clear()
            writeYuv420(frameBitmap, inputBuffer)
            encoder.queueInputBuffer(
                inputBufferId,
                0,
                inputBuffer.position(),
                frameIndex * frameDurationUs,
                0,
            )
            frameIndex += 1
            drainEncoder(false)
        }

        private fun drainEncoder(endOfStream: Boolean) {
            val info = MediaCodec.BufferInfo()
            while (true) {
                val outputBufferId = encoder.dequeueOutputBuffer(info, if (endOfStream) 10_000 else 0)
                when {
                    outputBufferId == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        if (!endOfStream) return
                    }

                    outputBufferId == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        trackIndex = muxer.addTrack(encoder.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }

                    outputBufferId >= 0 -> {
                        val outputBuffer = encoder.getOutputBuffer(outputBufferId)
                        if (outputBuffer != null && info.size > 0 && muxerStarted) {
                            outputBuffer.position(info.offset)
                            outputBuffer.limit(info.offset + info.size)
                            muxer.writeSampleData(trackIndex, outputBuffer, info)
                        }
                        encoder.releaseOutputBuffer(outputBufferId, false)
                        if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                            return
                        }
                    }
                }
            }
        }

        private fun drawBackground() {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            paint.shader = LinearGradient(
                0f,
                0f,
                width.toFloat(),
                height.toFloat(),
                Color.rgb(255, 250, 247),
                Color.rgb(255, 217, 199),
                Shader.TileMode.CLAMP,
            )
            frameCanvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
            paint.shader = null
            paint.color = Color.argb(42, 190, 18, 60)
            frameCanvas.drawCircle(width - 80f, 120f, 150f, paint)
            paint.color = Color.argb(32, 15, 118, 110)
            frameCanvas.drawCircle(85f, height - 170f, 130f, paint)
        }

        private fun drawCenteredText(title: String, subtitle: String, body: String) {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textAlign = Paint.Align.CENTER
                color = Color.rgb(76, 16, 36)
                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
            }
            drawWrapped(title, paint, 56f, 230f, width - 96f, 1.12f)
            paint.color = Color.rgb(15, 118, 110)
            drawWrapped(subtitle, paint, 34f, 430f, width - 96f, 1.2f)
            paint.color = Color.rgb(47, 31, 37)
            paint.typeface = android.graphics.Typeface.DEFAULT
            drawWrapped(body, paint, 36f, 590f, width - 112f, 1.35f)
            drawFooter()
        }

        private fun drawFinalMessageCard(message: String) {
            val card = RectF(42f, 145f, width - 42f, height - 132f)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)

            paint.color = Color.argb(46, 76, 16, 36)
            frameCanvas.drawRoundRect(
                RectF(card.left + 4f, card.top + 18f, card.right + 4f, card.bottom + 18f),
                28f,
                28f,
                paint,
            )

            paint.color = Color.WHITE
            frameCanvas.drawRoundRect(card, 28f, 28f, paint)

            paint.color = Color.rgb(255, 241, 243)
            frameCanvas.drawCircle(width / 2f, card.top + 96f, 44f, paint)

            val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.rgb(190, 18, 60)
                textAlign = Paint.Align.CENTER
                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
                textSize = 42f
            }
            frameCanvas.drawText("♥", width / 2f, card.top + 111f, iconPaint)

            val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.rgb(15, 118, 110)
                textAlign = Paint.Align.CENTER
                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
                textSize = 25f
            }
            frameCanvas.drawText("Mensagem final", width / 2f, card.top + 174f, labelPaint)

            paint.color = Color.rgb(190, 18, 60)
            frameCanvas.drawRoundRect(
                RectF(width / 2f - 38f, card.top + 202f, width / 2f + 38f, card.top + 207f),
                8f,
                8f,
                paint,
            )

            val messagePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.rgb(76, 16, 36)
                textAlign = Paint.Align.CENTER
                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
            }
            drawWrapped(message, messagePaint, 35f, card.top + 278f, card.width() - 74f, 1.22f, 8)

            val footerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.rgb(122, 75, 91)
                textAlign = Paint.Align.CENTER
                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
                textSize = 22f
            }
            frameCanvas.drawText("Feito com LoveinLoop", width / 2f, card.bottom - 48f, footerPaint)
        }

        private fun drawPhoto(photo: Bitmap) {
            val target = RectF(60f, 155f, width - 60f, height - 210f)
            val source = centerCropSource(photo, target)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
            frameCanvas.drawRoundRect(target, 18f, 18f, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.WHITE
            })
            val inset = RectF(target.left + 10f, target.top + 10f, target.right - 10f, target.bottom - 10f)
            frameCanvas.drawBitmap(photo, source, inset, paint)
            drawFooter()
        }

        private fun centerCropSource(photo: Bitmap, target: RectF): Rect {
            val photoRatio = photo.width.toFloat() / photo.height.toFloat()
            val targetRatio = target.width() / target.height()
            return if (photoRatio > targetRatio) {
                val sourceWidth = (photo.height * targetRatio).toInt()
                val left = (photo.width - sourceWidth) / 2
                Rect(left, 0, left + sourceWidth, photo.height)
            } else {
                val sourceHeight = (photo.width / targetRatio).toInt()
                val top = (photo.height - sourceHeight) / 2
                Rect(0, top, photo.width, top + sourceHeight)
            }
        }

        private fun decodeScaledBitmap(path: String): Bitmap? {
            val bounds = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                return null
            }

            var sampleSize = 1
            while (bounds.outWidth / sampleSize > width * 2 || bounds.outHeight / sampleSize > height * 2) {
                sampleSize *= 2
            }

            return BitmapFactory.decodeFile(
                path,
                BitmapFactory.Options().apply {
                    inSampleSize = sampleSize
                    inPreferredConfig = Bitmap.Config.ARGB_8888
                },
            )
        }

        private fun selectColorFormat(colorFormats: IntArray): Int {
            if (colorFormats.contains(MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar)) {
                return MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar
            }
            if (colorFormats.contains(MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar)) {
                return MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar
            }
            if (colorFormats.contains(MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)) {
                return MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible
            }
            error("H.264 encoder does not support YUV420 input.")
        }

        private fun drawTopLabel(label: String) {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.rgb(76, 16, 36)
                textAlign = Paint.Align.CENTER
                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
            }
            drawWrapped(label, paint, 30f, 90f, width - 96f, 1.1f)
        }

        private fun drawFooter() {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.rgb(190, 18, 60)
                textAlign = Paint.Align.CENTER
                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
            }
            frameCanvas.drawText("LoveinLoop", width / 2f, height - 70f, paint.apply { textSize = 30f })
        }

        private fun drawWrapped(
            text: String,
            paint: Paint,
            textSize: Float,
            startY: Float,
            maxWidth: Float,
            lineHeight: Float,
        ) {
            paint.textSize = textSize
            val words = text.replace("\n", " ").split(Regex("\\s+")).filter { it.isNotBlank() }
            val lines = mutableListOf<String>()
            var line = ""
            words.forEach { word ->
                val candidate = if (line.isBlank()) word else "$line $word"
                if (paint.measureText(candidate) <= maxWidth) {
                    line = candidate
                } else {
                    if (line.isNotBlank()) lines.add(line)
                    line = word
                }
            }
            if (line.isNotBlank()) lines.add(line)

            var y = startY
            lines.take(6).forEach {
                frameCanvas.drawText(it, width / 2f, y, paint)
                y += textSize * lineHeight
            }
        }

        private fun drawWrapped(
            text: String,
            paint: Paint,
            textSize: Float,
            startY: Float,
            maxWidth: Float,
            lineHeight: Float,
            maxLines: Int,
        ) {
            paint.textSize = textSize
            val words = text.replace("\n", " ").split(Regex("\\s+")).filter { it.isNotBlank() }
            val lines = mutableListOf<String>()
            var line = ""
            words.forEach { word ->
                val candidate = if (line.isBlank()) word else "$line $word"
                if (paint.measureText(candidate) <= maxWidth) {
                    line = candidate
                } else {
                    if (line.isNotBlank()) lines.add(line)
                    line = word
                }
            }
            if (line.isNotBlank()) lines.add(line)

            var y = startY
            lines.take(maxLines).forEach {
                frameCanvas.drawText(it, width / 2f, y, paint)
                y += textSize * lineHeight
            }
        }

        private fun writeYuv420(bitmap: Bitmap, buffer: ByteBuffer) {
            val pixels = IntArray(width * height)
            bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

            val yPlaneSize = width * height
            val uvPlaneSize = yPlaneSize / 4
            val yuv = ByteArray(yPlaneSize + uvPlaneSize * 2)
            var yIndex = 0
            var uIndex = yPlaneSize
            var vIndex = yPlaneSize + uvPlaneSize
            var uvIndex = yPlaneSize
            val semiPlanar = colorFormat != MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar

            for (j in 0 until height) {
                for (i in 0 until width) {
                    val pixel = pixels[j * width + i]
                    val r = pixel shr 16 and 0xff
                    val g = pixel shr 8 and 0xff
                    val b = pixel and 0xff
                    val y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                    val u = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                    val v = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128
                    yuv[yIndex++] = y.coerceIn(0, 255).toByte()
                    if (j % 2 == 0 && i % 2 == 0) {
                        if (semiPlanar) {
                            yuv[uvIndex++] = u.coerceIn(0, 255).toByte()
                            yuv[uvIndex++] = v.coerceIn(0, 255).toByte()
                        } else {
                            yuv[uIndex++] = u.coerceIn(0, 255).toByte()
                            yuv[vIndex++] = v.coerceIn(0, 255).toByte()
                        }
                    }
                }
            }
            buffer.put(yuv)
        }
    }
}
