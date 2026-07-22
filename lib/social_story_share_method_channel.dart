import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'social_story_share_platform_interface.dart';
import 'src/models.dart';

/// An implementation of [SocialStorySharePlatform] that uses method channels.
class MethodChannelSocialStoryShare extends SocialStorySharePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('social_story_share');

  @override
  Future<ShareResult> shareToStory({
    required String platform,
    required String appId,
    String? backgroundImagePath,
    String? backgroundVideoPath,
    String? stickerImagePath,
    String? backgroundTopColorHex,
    String? backgroundBottomColorHex,
    String? contentUrl,
  }) async {
    final result = await methodChannel.invokeMethod<String>('shareToStory', {
      'platform': platform,
      'appId': appId,
      'backgroundImagePath': backgroundImagePath,
      'backgroundVideoPath': backgroundVideoPath,
      'stickerImagePath': stickerImagePath,
      'backgroundTopColor': backgroundTopColorHex,
      'backgroundBottomColor': backgroundBottomColorHex,
      'contentUrl': contentUrl,
    });
    return ShareResult.fromName(result);
  }

  @override
  Future<ShareResult> shareText({
    required String target,
    required String text,
    String? url,
    String? phone,
    List<String>? hashtags,
    List<String>? recipients,
  }) async {
    final result = await methodChannel.invokeMethod<String>('shareText', {
      'target': target,
      'text': text,
      'url': url,
      'phone': phone,
      'hashtags': hashtags,
      'recipients': recipients,
    });
    return ShareResult.fromName(result);
  }

  @override
  Future<ShareResult> shareToSystem({String? text, String? imagePath}) async {
    final result = await methodChannel.invokeMethod<String>('shareToSystem', {
      'text': text,
      'imagePath': imagePath,
    });
    return ShareResult.fromName(result);
  }

  @override
  Future<void> copyToClipboard({String? text, String? imagePath}) {
    return methodChannel.invokeMethod<void>('copyToClipboard', {
      'text': text,
      'imagePath': imagePath,
    });
  }

  @override
  Future<bool> isInstalled(String app) async {
    final installed = await methodChannel.invokeMethod<bool>('isInstalled', {
      'app': app,
    });
    return installed ?? false;
  }
}
