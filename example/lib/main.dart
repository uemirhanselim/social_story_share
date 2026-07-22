import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:social_story_share/social_story_share.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Replace with your own Meta/Facebook App ID.
  static const _appId = '000000000000000';

  String _status = '';

  Future<void> _run(String label, Future<ShareResult> Function() action) async {
    setState(() => _status = '$label...');
    try {
      final result = await action();
      setState(() => _status = '$label: ${result.name}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  /// Renders a simple 1080x1920 gradient PNG to a temp file (no bundled asset).
  Future<String> _renderStoryImage() async {
    const width = 1080.0;
    const height = 1920.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const rect = Rect.fromLTWH(0, 0, width, height);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF623EDC), Color(0xFF2B1876)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final file = File(
      '${Directory.systemTemp.path}/social_story_share_example.png',
    );
    await file.writeAsBytes(data!.buffer.asUint8List());
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('social_story_share example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _run(
                  'Instagram Story',
                  () async => SocialStoryShare.shareToInstagramStory(
                    appId: _appId,
                    backgroundImagePath: await _renderStoryImage(),
                  ),
                ),
                child: const Text('Share to Instagram Story'),
              ),
              ElevatedButton(
                onPressed: () => _run(
                  'WhatsApp',
                  () => SocialStoryShare.shareToWhatsApp(
                    text: 'Hello from social_story_share!',
                  ),
                ),
                child: const Text('Share text to WhatsApp'),
              ),
              ElevatedButton(
                onPressed: () => _run(
                  'X/Twitter',
                  () => SocialStoryShare.shareToTwitter(
                    text: 'Hello',
                    url: 'https://pub.dev/packages/social_story_share',
                    hashtags: ['flutter'],
                  ),
                ),
                child: const Text('Share to X/Twitter'),
              ),
              const SizedBox(height: 24),
              Text(_status),
            ],
          ),
        ),
      ),
    );
  }
}
