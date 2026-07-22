import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'social_story_share_method_channel.dart';
import 'src/models.dart';

abstract class SocialStorySharePlatform extends PlatformInterface {
  /// Constructs a SocialStorySharePlatform.
  SocialStorySharePlatform() : super(token: _token);

  static final Object _token = Object();

  static SocialStorySharePlatform _instance = MethodChannelSocialStoryShare();

  /// The default instance of [SocialStorySharePlatform] to use.
  static SocialStorySharePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SocialStorySharePlatform] when
  /// they register themselves.
  static set instance(SocialStorySharePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Shares a story to [platform] (`instagram` or `facebook`).
  ///
  /// Colors are 6-digit `#RRGGBB` hex strings. At least one of
  /// [backgroundImagePath], [backgroundVideoPath] or [stickerImagePath] must be
  /// provided.
  Future<ShareResult> shareToStory({
    required String platform,
    required String appId,
    String? backgroundImagePath,
    String? backgroundVideoPath,
    String? stickerImagePath,
    String? backgroundTopColorHex,
    String? backgroundBottomColorHex,
    String? contentUrl,
  }) {
    throw UnimplementedError('shareToStory() has not been implemented.');
  }

  /// Shares [text] (and optional [url]/[hashtags]/[recipients]) directly to a
  /// target app (`whatsapp`, `telegram`, `twitter` or `sms`).
  Future<ShareResult> shareText({
    required String target,
    required String text,
    String? url,
    String? phone,
    List<String>? hashtags,
    List<String>? recipients,
  }) {
    throw UnimplementedError('shareText() has not been implemented.');
  }

  /// Opens the native OS share sheet with [text] and/or the image at [imagePath].
  Future<ShareResult> shareToSystem({String? text, String? imagePath}) {
    throw UnimplementedError('shareToSystem() has not been implemented.');
  }

  /// Copies [text] and/or the image at [imagePath] to the system clipboard.
  Future<void> copyToClipboard({String? text, String? imagePath}) {
    throw UnimplementedError('copyToClipboard() has not been implemented.');
  }

  /// Whether the given [app] is installed.
  Future<bool> isInstalled(String app) {
    throw UnimplementedError('isInstalled() has not been implemented.');
  }
}
