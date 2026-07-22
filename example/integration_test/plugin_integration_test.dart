// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:social_story_share/social_story_share.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isInstalled returns a boolean from the host', (tester) async {
    // Instagram is unlikely to be installed on a CI device; either way the
    // native side must return a boolean without throwing.
    final installed = await SocialStoryShare.isInstalled(SocialApp.instagram);
    expect(installed, isA<bool>());
  });
}
