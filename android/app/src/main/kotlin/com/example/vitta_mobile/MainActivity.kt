package com.example.vitta_mobile

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.vitta_mobile/file_export"
        private const val SAVE_PDF_METHOD = "savePdfToDownloads"
        private const val STORAGE_PERMISSION_REQUEST = 4107
    }

    private data class PendingSave(
        val bytes: ByteArray,
        val fileName: String,
        val result: MethodChannel.Result,
    )

    private var pendingSave: PendingSave? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != SAVE_PDF_METHOD) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val bytes = call.argument<ByteArray>("bytes")
                val requestedName = call.argument<String>("fileName")
                if (bytes == null || bytes.isEmpty() || requestedName.isNullOrBlank()) {
                    result.error("invalid_pdf", "O PDF ou o nome do arquivo é inválido.", null)
                    return@setMethodCallHandler
                }

                val fileName = sanitizePdfFileName(requestedName)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    saveWithMediaStore(bytes, fileName, result)
                } else {
                    saveOnLegacyAndroid(bytes, fileName, result)
                }
            }
    }

    private fun saveOnLegacyAndroid(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
                    PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingSave != null) {
                result.error("save_in_progress", "Já existe um salvamento em andamento.", null)
                return
            }
            pendingSave = PendingSave(bytes, fileName, result)
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                STORAGE_PERMISSION_REQUEST,
            )
            return
        }
        writeLegacyFile(bytes, fileName, result)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != STORAGE_PERMISSION_REQUEST) return

        val pending = pendingSave ?: return
        pendingSave = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            writeLegacyFile(pending.bytes, pending.fileName, pending.result)
        } else {
            pending.result.error(
                "storage_permission_denied",
                "Permita o acesso aos arquivos para salvar a caderneta em Download/Vitta.",
                null,
            )
        }
    }

    private fun writeLegacyFile(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        try {
            val downloads = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS,
            )
            val directory = File(downloads, "Vitta")
            if (!directory.exists() && !directory.mkdirs()) {
                throw IllegalStateException("Não foi possível criar a pasta Download/Vitta.")
            }
            val target = uniqueFile(directory, fileName)
            target.outputStream().use { it.write(bytes) }
            MediaScannerConnection.scanFile(
                this,
                arrayOf(target.absolutePath),
                arrayOf("application/pdf"),
                null,
            )
            result.success("Download/Vitta/${target.name}")
        } catch (error: Exception) {
            result.error("save_failed", "Não foi possível salvar o PDF.", error.message)
        }
    }

    private fun saveWithMediaStore(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        val resolver = contentResolver
        val collection = MediaStore.Downloads.getContentUri(
            MediaStore.VOLUME_EXTERNAL_PRIMARY,
        )
        val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/Vitta/"
        val displayName = uniqueMediaStoreName(collection, relativePath, fileName)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
        if (uri == null) {
            result.error("save_failed", "Não foi possível criar o PDF em Download/Vitta.", null)
            return
        }

        try {
            resolver.openOutputStream(uri, "w")?.use { it.write(bytes) }
                ?: throw IllegalStateException("Não foi possível abrir o arquivo para gravação.")
            val completed = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, completed, null, null)
            result.success("Download/Vitta/$displayName")
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            result.error("save_failed", "Não foi possível salvar o PDF.", error.message)
        }
    }

    private fun uniqueMediaStoreName(
        collection: android.net.Uri,
        relativePath: String,
        requestedName: String,
    ): String {
        var candidate = requestedName
        var suffix = 2
        while (mediaStoreFileExists(collection, relativePath, candidate)) {
            candidate = withSuffix(requestedName, suffix++)
        }
        return candidate
    }

    private fun mediaStoreFileExists(
        collection: android.net.Uri,
        relativePath: String,
        displayName: String,
    ): Boolean = contentResolver.query(
        collection,
        arrayOf(MediaStore.MediaColumns._ID),
        "${MediaStore.MediaColumns.RELATIVE_PATH} = ? AND " +
            "${MediaStore.MediaColumns.DISPLAY_NAME} = ?",
        arrayOf(relativePath, displayName),
        null,
    )?.use { it.moveToFirst() } ?: false

    private fun uniqueFile(directory: File, requestedName: String): File {
        var candidate = File(directory, requestedName)
        var suffix = 2
        while (candidate.exists()) {
            candidate = File(directory, withSuffix(requestedName, suffix++))
        }
        return candidate
    }

    private fun withSuffix(fileName: String, suffix: Int): String {
        val base = fileName.removeSuffix(".pdf")
        return "$base-$suffix.pdf"
    }

    private fun sanitizePdfFileName(requestedName: String): String {
        val leafName = requestedName.substringAfterLast('/').substringAfterLast('\\')
        val sanitized = leafName.replace(Regex("[^A-Za-z0-9._-]"), "-")
        val usableName = sanitized.ifBlank { "carteira-digital-vitta.pdf" }
        return if (usableName.lowercase().endsWith(".pdf")) {
            usableName
        } else {
            "$usableName.pdf"
        }
    }
}
