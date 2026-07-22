## 0.2.1

* Documentation: added a support link to the README.

## 0.2.0

* Added direct text/link sharing: `shareToWhatsApp`, `shareToTelegram`,
  `shareToTwitter` (X) and `shareToSms`.
* Added `shareToSystem` (native OS share sheet with text and/or image).
* Added `copyToClipboard` (text and/or image).
* Generalized availability checks: `isInstalled(SocialApp)` and `installedApps()`.
* Renamed the result enum to `ShareResult` and introduced the `SocialApp` enum.

## 0.1.0

* Initial release.
* Share to Instagram Stories and Facebook Stories on iOS and Android.
* Supports background image, background video, sticker overlay, gradient
  top/bottom colors and an attribution content URL.
* iOS is Swift Package Manager compatible (no CocoaPods required); Android
  bundles its own `FileProvider`.
