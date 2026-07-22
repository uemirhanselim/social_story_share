import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_story_share/social_story_share.dart';
import 'package:social_story_share/social_story_share_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelSocialStoryShare();
  const channel = MethodChannel('social_story_share');

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          calls.add(methodCall);
          if (methodCall.method == 'isInstalled') return true;
          if (methodCall.method == 'copyToClipboard') return null;
          return 'success';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('shareToStory sends the arguments and parses the result', () async {
    final result = await platform.shareToStory(
      platform: 'instagram',
      appId: '123',
      backgroundImagePath: '/tmp/story.png',
      backgroundTopColorHex: '#623EDC',
    );

    expect(result, ShareResult.success);
    final call = calls.single;
    expect(call.method, 'shareToStory');
    expect(call.arguments['platform'], 'instagram');
    expect(call.arguments['appId'], '123');
    expect(call.arguments['backgroundImagePath'], '/tmp/story.png');
    expect(call.arguments['backgroundTopColor'], '#623EDC');
  });

  test('shareText forwards target and text', () async {
    final result = await platform.shareText(target: 'telegram', text: 'hello');

    expect(result, ShareResult.success);
    expect(calls.single.method, 'shareText');
    expect(calls.single.arguments['target'], 'telegram');
    expect(calls.single.arguments['text'], 'hello');
  });

  test('isInstalled returns the native boolean', () async {
    expect(await platform.isInstalled('whatsapp'), isTrue);
    expect(calls.single.arguments['app'], 'whatsapp');
  });
}
