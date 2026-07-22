package com.uemirhanselim.social_story_share

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** Native sharing to Instagram/Facebook Stories and to WhatsApp/Telegram/X/SMS. */
class SocialStorySharePlugin :
    FlutterPlugin,
    ActivityAware,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "social_story_share")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "shareToStory" -> shareToStory(call, result)
            "shareText" -> shareText(call, result)
            "shareToSystem" -> shareToSystem(call, result)
            "copyToClipboard" -> copyToClipboard(call, result)
            "isInstalled" -> result.success(isInstalled(packageFor(call.argument<String>("app"))))
            else -> result.notImplemented()
        }
    }

    // region Stories

    private fun shareToStory(
        call: MethodCall,
        result: Result,
    ) {
        val target = StoryTarget.fromName(call.argument<String>("platform"))
        val appId = call.argument<String>("appId")
        if (target == null || appId == null) {
            result.success(RESULT_ERROR)
            return
        }
        if (!isInstalled(target.packageName)) {
            result.success(RESULT_APP_NOT_INSTALLED)
            return
        }

        val backgroundImage = fileUri(call.argument<String>("backgroundImagePath"))
        val backgroundVideo = fileUri(call.argument<String>("backgroundVideoPath"))
        val sticker = fileUri(call.argument<String>("stickerImagePath"))
        if (backgroundImage == null && backgroundVideo == null && sticker == null) {
            result.success(RESULT_MISSING_CONTENT)
            return
        }

        try {
            val intent = Intent(target.action).setPackage(target.packageName)
            intent.putExtra("source_application", appId)
            if (target == StoryTarget.FACEBOOK) {
                intent.putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)
            }
            when {
                backgroundImage != null -> intent.setDataAndType(backgroundImage, "image/*")
                backgroundVideo != null -> intent.setDataAndType(backgroundVideo, "video/*")
                // Sticker-only / gradient story: no background asset, but the
                // intent still needs a type or the story activity won't match.
                else -> intent.type = "image/*"
            }
            sticker?.let { intent.putExtra("interactive_asset_uri", it) }
            call.argument<String>("backgroundTopColor")?.let { intent.putExtra("top_background_color", it) }
            call.argument<String>("backgroundBottomColor")?.let { intent.putExtra("bottom_background_color", it) }
            call.argument<String>("contentUrl")?.let { intent.putExtra("content_url", it) }

            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            listOfNotNull(backgroundImage, backgroundVideo, sticker).forEach {
                context.grantUriPermission(target.packageName, it, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            launch(intent)
            result.success(RESULT_SUCCESS)
        } catch (e: Exception) {
            result.success(RESULT_ERROR)
        }
    }

    // endregion

    // region Direct text sharing

    private fun shareText(
        call: MethodCall,
        result: Result,
    ) {
        val target = call.argument<String>("target")
        val text = call.argument<String>("text").orEmpty()
        val url = call.argument<String>("url")
        val phone = call.argument<String>("phone")
        val hashtags = call.argument<List<String>>("hashtags")
        val recipients = call.argument<List<String>>("recipients")
        val body = listOfNotNull(text.ifEmpty { null }, url?.ifEmpty { null }).joinToString("\n")

        val intent = when (target) {
            "whatsapp" ->
                if (!phone.isNullOrEmpty()) {
                    Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$phone?text=${Uri.encode(body)}"))
                } else {
                    sendText(body, "com.whatsapp")
                }
            "telegram" -> sendText(body, "org.telegram.messenger")
            "twitter" -> {
                val query = buildString {
                    append("text=").append(Uri.encode(text))
                    if (!url.isNullOrEmpty()) append("&url=").append(Uri.encode(url))
                    if (!hashtags.isNullOrEmpty()) append("&hashtags=").append(Uri.encode(hashtags.joinToString(",")))
                }
                Intent(Intent.ACTION_VIEW, Uri.parse("https://twitter.com/intent/tweet?$query"))
            }
            "sms" -> {
                val to = recipients?.joinToString(",").orEmpty()
                Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$to")).putExtra("sms_body", body)
            }
            else -> null
        }

        if (intent == null) {
            result.success(RESULT_ERROR)
            return
        }
        if (intent.resolveActivity(context.packageManager) == null) {
            result.success(RESULT_APP_NOT_INSTALLED)
            return
        }
        try {
            launch(intent)
            result.success(RESULT_SUCCESS)
        } catch (e: Exception) {
            result.success(RESULT_ERROR)
        }
    }

    private fun sendText(
        body: String,
        packageName: String,
    ): Intent =
        Intent(Intent.ACTION_SEND)
            .setType("text/plain")
            .setPackage(packageName)
            .putExtra(Intent.EXTRA_TEXT, body)

    // endregion

    // region System share sheet

    private fun shareToSystem(
        call: MethodCall,
        result: Result,
    ) {
        val text = call.argument<String>("text")
        val imageUri = fileUri(call.argument<String>("imagePath"))
        if (text.isNullOrEmpty() && imageUri == null) {
            result.success(RESULT_MISSING_CONTENT)
            return
        }
        try {
            val send = Intent(Intent.ACTION_SEND)
            if (imageUri != null) {
                send.type = "image/*"
                send.putExtra(Intent.EXTRA_STREAM, imageUri)
                send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                send.type = "text/plain"
            }
            if (!text.isNullOrEmpty()) send.putExtra(Intent.EXTRA_TEXT, text)

            val chooser = Intent.createChooser(send, null)
            chooser.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            launch(chooser)
            result.success(RESULT_SUCCESS)
        } catch (e: Exception) {
            result.success(RESULT_ERROR)
        }
    }

    // endregion

    // region Clipboard & availability

    private fun copyToClipboard(
        call: MethodCall,
        result: Result,
    ) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val text = call.argument<String>("text")
        val imageUri = fileUri(call.argument<String>("imagePath"))
        val clip = when {
            imageUri != null -> ClipData.newUri(context.contentResolver, "image", imageUri)
            text != null -> ClipData.newPlainText("text", text)
            else -> null
        }
        clip?.let { clipboard.setPrimaryClip(it) }
        result.success(null)
    }

    private fun isInstalled(packageName: String?): Boolean {
        if (packageName == null) return false
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun packageFor(app: String?): String? =
        when (app) {
            "instagram" -> "com.instagram.android"
            "facebook" -> "com.facebook.katana"
            "whatsapp" -> "com.whatsapp"
            "telegram" -> "org.telegram.messenger"
            "twitter" -> "com.twitter.android"
            else -> null
        }

    // endregion

    /** Wraps a file path into a shareable content:// uri, or null if absent/missing. */
    private fun fileUri(path: String?): Uri? {
        if (path.isNullOrEmpty()) return null
        val source = File(path)
        if (!source.exists()) return null
        // Copy the file into our own cache directory before handing it to the
        // FileProvider. The caller's path may live anywhere (temp, code_cache,
        // getFilesDir, …); copying guarantees it sits under a configured root,
        // avoiding "Failed to find configured root that contains …".
        val shareDir = File(context.cacheDir, "social_story_share").apply { mkdirs() }
        val target = File(shareDir, source.name)
        if (source.canonicalPath != target.canonicalPath) {
            source.copyTo(target, overwrite = true)
        }
        val authority = "${context.packageName}.social_story_share.fileprovider"
        return FileProvider.getUriForFile(context, authority, target)
    }

    private fun launch(intent: Intent) {
        val host = activity
        if (host != null) {
            host.startActivity(intent)
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }

    private enum class StoryTarget(
        val packageName: String,
        val action: String,
    ) {
        INSTAGRAM("com.instagram.android", "com.instagram.share.ADD_TO_STORY"),
        FACEBOOK("com.facebook.katana", "com.facebook.stories.ADD_TO_STORY"),
        ;

        companion object {
            fun fromName(name: String?): StoryTarget? =
                when (name) {
                    "instagram" -> INSTAGRAM
                    "facebook" -> FACEBOOK
                    else -> null
                }
        }
    }

    private companion object {
        const val RESULT_SUCCESS = "success"
        const val RESULT_APP_NOT_INSTALLED = "appNotInstalled"
        const val RESULT_MISSING_CONTENT = "missingContent"
        const val RESULT_ERROR = "error"
    }
}
