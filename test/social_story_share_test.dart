import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:social_story_share/social_story_share.dart';
import 'package:social_story_share/social_story_share_method_channel.dart';
import 'package:social_story_share/social_story_share_platform_interface.dart';

class MockSocialStorySharePlatform
    with MockPlatformInterfaceMixin
    implements SocialStorySharePlatform {
  Map<String, dynamic>? lastCall;
  final Set<String> installed = {};

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
    lastCall = {
      'method': 'shareToStory',
      'platform': platform,
      'appId': appId,
      'backgroundTopColorHex': backgroundTopColorHex,
      'backgroundBottomColorHex': backgroundBottomColorHex,
    };
    return ShareResult.success;
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
    lastCall = {
      'method': 'shareText',
      'target': target,
      'text': text,
      'url': url,
      'phone': phone,
      'hashtags': hashtags,
    };
    return ShareResult.success;
  }

  @override
  Future<ShareResult> shareToSystem({String? text, String? imagePath}) async {
    lastCall = {
      'method': 'shareToSystem',
      'text': text,
      'imagePath': imagePath,
    };
    return ShareResult.success;
  }

  @override
  Future<void> copyToClipboard({String? text, String? imagePath}) async {
    lastCall = {
      'method': 'copyToClipboard',
      'text': text,
      'imagePath': imagePath,
    };
  }

  @override
  Future<bool> isInstalled(String app) async => installed.contains(app);
}

void main() {
  final initialPlatform = SocialStorySharePlatform.instance;

  test('$MethodChannelSocialStoryShare is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSocialStoryShare>());
  });

  test('shareToInstagramStory routes to the instagram platform', () async {
    final fake = MockSocialStorySharePlatform();
    SocialStorySharePlatform.instance = fake;

    final result = await SocialStoryShare.shareToInstagramStory(
      appId: '123',
      backgroundImagePath: '/tmp/story.png',
      backgroundTopColor: const Color(0xFF623EDC),
      backgroundBottomColor: const Color(0xFF2B1876),
    );

    expect(result, ShareResult.success);
    expect(fake.lastCall!['method'], 'shareToStory');
    expect(fake.lastCall!['platform'], 'instagram');
    expect(fake.lastCall!['backgroundTopColorHex'], '#623EDC');
    expect(fake.lastCall!['backgroundBottomColorHex'], '#2B1876');
  });

  test('shareToWhatsApp routes through shareText', () async {
    final fake = MockSocialStorySharePlatform();
    SocialStorySharePlatform.instance = fake;

    await SocialStoryShare.shareToWhatsApp(text: 'hi', phone: '905551112233');

    expect(fake.lastCall!['method'], 'shareText');
    expect(fake.lastCall!['target'], 'whatsapp');
    expect(fake.lastCall!['text'], 'hi');
    expect(fake.lastCall!['phone'], '905551112233');
  });

  test('shareToSystem forwards text and image', () async {
    final fake = MockSocialStorySharePlatform();
    SocialStorySharePlatform.instance = fake;

    await SocialStoryShare.shareToSystem(text: 'hi', imagePath: '/tmp/a.png');

    expect(fake.lastCall!['method'], 'shareToSystem');
    expect(fake.lastCall!['text'], 'hi');
    expect(fake.lastCall!['imagePath'], '/tmp/a.png');
  });

  test('installedApps returns only installed apps', () async {
    final fake = MockSocialStorySharePlatform();
    fake.installed.addAll({'instagram', 'whatsapp'});
    SocialStorySharePlatform.instance = fake;

    final apps = await SocialStoryShare.installedApps();

    expect(apps, {SocialApp.instagram, SocialApp.whatsapp});
  });
}
