import 'dart:ui' show Color;

import 'social_story_share_platform_interface.dart';
import 'src/models.dart';

export 'src/models.dart';

/// Native sharing to Instagram, Facebook, WhatsApp, Telegram, X/Twitter and SMS
/// — Stories, direct text/link sharing and clipboard, all Swift Package Manager
/// compatible (no CocoaPods required).
class SocialStoryShare {
  const SocialStoryShare();

  static SocialStorySharePlatform get _platform =>
      SocialStorySharePlatform.instance;

  // ---------------------------------------------------------------------------
  // Stories
  // ---------------------------------------------------------------------------

  /// Shares a story to Instagram.
  ///
  /// [appId] is your Meta/Facebook App ID (`source_application`). The story can
  /// be a full-screen [backgroundImagePath]/[backgroundVideoPath], an optional
  /// [stickerImagePath] overlay, gradient [backgroundTopColor]/
  /// [backgroundBottomColor] (used when no background asset is given) and a
  /// [contentUrl] the sticker links back to.
  static Future<ShareResult> shareToInstagramStory({
    required String appId,
    String? backgroundImagePath,
    String? backgroundVideoPath,
    String? stickerImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
    String? contentUrl,
  }) {
    return _platform.shareToStory(
      platform: SocialApp.instagram.id,
      appId: appId,
      backgroundImagePath: backgroundImagePath,
      backgroundVideoPath: backgroundVideoPath,
      stickerImagePath: stickerImagePath,
      backgroundTopColorHex: _toHex(backgroundTopColor),
      backgroundBottomColorHex: _toHex(backgroundBottomColor),
      contentUrl: contentUrl,
    );
  }

  /// Shares a story to Facebook. See [shareToInstagramStory] for the parameters.
  static Future<ShareResult> shareToFacebookStory({
    required String appId,
    String? backgroundImagePath,
    String? backgroundVideoPath,
    String? stickerImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
    String? contentUrl,
  }) {
    return _platform.shareToStory(
      platform: SocialApp.facebook.id,
      appId: appId,
      backgroundImagePath: backgroundImagePath,
      backgroundVideoPath: backgroundVideoPath,
      stickerImagePath: stickerImagePath,
      backgroundTopColorHex: _toHex(backgroundTopColor),
      backgroundBottomColorHex: _toHex(backgroundBottomColor),
      contentUrl: contentUrl,
    );
  }

  // ---------------------------------------------------------------------------
  // Direct text / link sharing
  // ---------------------------------------------------------------------------

  /// Opens WhatsApp with [text] prefilled. If [phone] (international format,
  /// digits only) is given, opens the chat with that contact.
  static Future<ShareResult> shareToWhatsApp({
    required String text,
    String? phone,
  }) {
    return _platform.shareText(target: 'whatsapp', text: text, phone: phone);
  }

  /// Opens Telegram with [text] (and optional [url]) prefilled.
  static Future<ShareResult> shareToTelegram({
    required String text,
    String? url,
  }) {
    return _platform.shareText(target: 'telegram', text: text, url: url);
  }

  /// Opens the X/Twitter composer with [text], optional [url] and [hashtags]
  /// (without the leading `#`).
  static Future<ShareResult> shareToTwitter({
    required String text,
    String? url,
    List<String>? hashtags,
  }) {
    return _platform.shareText(
      target: 'twitter',
      text: text,
      url: url,
      hashtags: hashtags,
    );
  }

  /// Opens the SMS composer with [text] (and optional [url]) prefilled,
  /// optionally addressed to [recipients].
  static Future<ShareResult> shareToSms({
    required String text,
    String? url,
    List<String>? recipients,
  }) {
    return _platform.shareText(
      target: 'sms',
      text: text,
      url: url,
      recipients: recipients,
    );
  }

  /// Opens the native OS share sheet with [text] and/or the image at
  /// [imagePath], letting the user pick any target app.
  static Future<ShareResult> shareToSystem({String? text, String? imagePath}) {
    return _platform.shareToSystem(text: text, imagePath: imagePath);
  }

  // ---------------------------------------------------------------------------
  // Clipboard & availability
  // ---------------------------------------------------------------------------

  /// Copies [text] and/or the image at [imagePath] to the system clipboard.
  static Future<void> copyToClipboard({String? text, String? imagePath}) {
    return _platform.copyToClipboard(text: text, imagePath: imagePath);
  }

  /// Whether the given [app] is installed.
  static Future<bool> isInstalled(SocialApp app) =>
      _platform.isInstalled(app.id);

  /// The subset of [SocialApp]s currently installed on the device.
  static Future<Set<SocialApp>> installedApps() async {
    final checks = await Future.wait(
      SocialApp.values.map((app) async => (app, await isInstalled(app))),
    );
    return {
      for (final (app, installed) in checks)
        if (installed) app,
    };
  }

  /// Converts a [Color] to a 6-digit `#RRGGBB` hex string (alpha is dropped, as
  /// the Stories APIs treat background colors as opaque).
  static String? _toHex(Color? color) {
    if (color == null) return null;
    int channel(double v) => (v * 255.0).round().clamp(0, 255);
    final r = channel(color.r).toRadixString(16).padLeft(2, '0');
    final g = channel(color.g).toRadixString(16).padLeft(2, '0');
    final b = channel(color.b).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}
