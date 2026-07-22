<h1 align="center">social_story_share</h1>

<p align="center">
Share to Instagram and Facebook Stories, WhatsApp, Telegram, X and SMS from Flutter,
using native APIs on iOS and Android.
</p>

<p align="center">
  <a href="https://pub.dev/packages/social_story_share"><img alt="pub" src="https://img.shields.io/pub/v/social_story_share?style=flat-square"></a>
  <a href="https://pub.dev/packages/social_story_share/score"><img alt="likes" src="https://img.shields.io/pub/likes/social_story_share?style=flat-square"></a>
  <a href="https://pub.dev/packages/social_story_share/score"><img alt="points" src="https://img.shields.io/pub/points/social_story_share?style=flat-square"></a>
  <img alt="platforms" src="https://img.shields.io/badge/platforms-iOS%20%7C%20Android-lightgrey?style=flat-square">
</p>

<p align="center">
  <a href="https://www.buymeacoffee.com/uemirhanselim">
    <img alt="Buy Me A Coffee" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" height="40">
  </a>
</p>

Sharing to Instagram/Facebook Stories on iOS normally relies on a CocoaPods plugin.
This package implements it as a Swift Package instead, so it keeps working on Flutter
projects that have migrated to Swift Package Manager without bringing CocoaPods back.
A CocoaPods podspec is still included for projects that have not migrated.

## Features

- Instagram and Facebook Stories: full-screen background image or video, an optional
  sticker overlay, gradient background colors, and an attribution link.
- Direct sharing to WhatsApp, Telegram, X/Twitter and SMS with prefilled text.
- The native OS share sheet (text and/or image).
- Copy text or an image to the clipboard.
- Check which of the supported apps are installed.
- iOS ships as a Swift Package; Android bundles its own `FileProvider`, so there is no
  per-app setup on Android.

## Comparison

| Capability | social_story_share | social_share | share_plus |
| :--- | :---: | :---: | :---: |
| Instagram Story — background image | yes | yes | no |
| Instagram Story — background video | yes | no | no |
| Instagram Story — sticker + gradient | yes | partial | no |
| Facebook Story | yes | yes | no |
| Direct WhatsApp / Telegram / X / SMS | yes | yes | no |
| OS share sheet (text + image) | yes | yes | yes |
| Arbitrary / multiple files | no | no | yes |
| Copy text to clipboard | yes | yes | no |
| Copy image to clipboard | yes | no | no |
| Check installed apps | yes | yes | no |
| Swift Package Manager | yes | no | yes |

For general file sharing through the OS share sheet (multiple files, any file type,
plus desktop and web), [`share_plus`](https://pub.dev/packages/share_plus) is the better
choice. This package focuses on Stories and direct-to-app sharing, which `share_plus`
does not cover.

## Install

```yaml
dependencies:
  social_story_share: ^0.2.0
```

```dart
import 'package:social_story_share/social_story_share.dart';
```

## Usage

### Instagram and Facebook Stories

```dart
// Full-screen background image with a tappable attribution link.
await SocialStoryShare.shareToInstagramStory(
  appId: '<YOUR_META_APP_ID>',
  backgroundImagePath: '/path/to/story.png',
  contentUrl: 'https://example.com/deeplink',
);

// Gradient background with a sticker overlay (no full-screen asset).
await SocialStoryShare.shareToFacebookStory(
  appId: '<YOUR_META_APP_ID>',
  stickerImagePath: '/path/to/sticker.png',
  backgroundTopColor: const Color(0xFF00C6FB),
  backgroundBottomColor: const Color(0xFF005BEA),
);

// A background video also works.
await SocialStoryShare.shareToInstagramStory(
  appId: '<YOUR_META_APP_ID>',
  backgroundVideoPath: '/path/to/story.mp4',
);
```

Handle the result to fall back when the app is missing:

```dart
final result = await SocialStoryShare.shareToInstagramStory(
  appId: '<YOUR_META_APP_ID>',
  backgroundImagePath: '/path/to/story.png',
);

if (result == ShareResult.appNotInstalled) {
  await SocialStoryShare.shareToSystem(imagePath: '/path/to/story.png');
}
```

### Direct text and link sharing

```dart
await SocialStoryShare.shareToWhatsApp(text: 'Check this out', phone: '905551112233');
await SocialStoryShare.shareToTelegram(text: 'Check this out', url: 'https://example.com');
await SocialStoryShare.shareToTwitter(text: 'Check this out', url: 'https://example.com', hashtags: ['flutter']);
await SocialStoryShare.shareToSms(text: 'Check this out', recipients: ['905551112233']);
```

### System share sheet, clipboard, availability

```dart
await SocialStoryShare.shareToSystem(text: 'Check this out', imagePath: '/path/to/image.png');

await SocialStoryShare.copyToClipboard(text: 'copied', imagePath: '/path/to/image.png');

final hasInstagram = await SocialStoryShare.isInstalled(SocialApp.instagram);
final installed = await SocialStoryShare.installedApps(); // Set<SocialApp>
```

## Story parameters

| Parameter | Description |
| :--- | :--- |
| `appId` | Meta/Facebook App ID, used as `source_application`. Required. |
| `backgroundImagePath` | Full-screen background image (recommended 1080x1920). |
| `backgroundVideoPath` | Full-screen background video, used when no background image is given. |
| `stickerImagePath` | Sticker image overlaid on the story. |
| `backgroundTopColor` | Gradient top color, used only when no background asset is given. |
| `backgroundBottomColor` | Gradient bottom color. |
| `contentUrl` | URL the sticker links back to. |

At least one of `backgroundImagePath`, `backgroundVideoPath` or `stickerImagePath` is required.

## Result

Each share returns a `ShareResult`:

| Value | Meaning |
| :--- | :--- |
| `success` | The target app was opened with the content. |
| `appNotInstalled` | The target app is not installed. |
| `missingContent` | Nothing was provided to share. |
| `error` | The share failed, for example an unreadable file. |

## Setup

### iOS

Add the URL schemes you use to `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>instagram-stories</string>
  <string>facebook-stories</string>
  <string>whatsapp</string>
  <string>tg</string>
  <string>twitter</string>
</array>
```

For Stories, register your Meta App ID (`FacebookAppID`) in `Info.plist` as usual. No
CocoaPods step is required.

### Android

No setup is required. The plugin declares its own `FileProvider` and the package-visibility
`<queries>` it needs. Pass files from a directory the app can read, such as the temporary
directory from `path_provider`.

## How it works

On iOS, assets are written to `UIPasteboard` under the `com.instagram.sharedSticker.*` and
`com.facebook.sharedSticker.*` keys and the `instagram-stories://` / `facebook-stories://`
schemes are opened; the other targets use their URL schemes and the system sheet uses
`UIActivityViewController`. On Android, Stories use the `com.instagram.share.ADD_TO_STORY`
and `com.facebook.stories.ADD_TO_STORY` intents with assets exposed through the bundled
`FileProvider`; the other targets use `ACTION_SEND`, `ACTION_SENDTO` and `ACTION_VIEW`.

## Support

If this package saved you some time, you can support its development:

<a href="https://www.buymeacoffee.com/uemirhanselim">
  <img alt="Buy Me A Coffee" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" height="40">
</a>

## License

MIT © Emirhan Selim Uzun
