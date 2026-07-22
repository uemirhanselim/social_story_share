import Flutter
import UIKit

public class SocialStorySharePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "social_story_share", binaryMessenger: registrar.messenger())
    let instance = SocialStorySharePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "shareToStory":
      handleStory(call, result: result)
    case "shareText":
      handleText(call, result: result)
    case "shareToSystem":
      handleSystemShare(call, result: result)
    case "copyToClipboard":
      handleCopy(call, result: result)
    case "isInstalled":
      let app = (call.arguments as? [String: Any])?["app"] as? String
      result(app.map { canOpen(scheme: installScheme(for: $0)) } ?? false)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Stories

  private func handleStory(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let target = StoryTarget(rawValue: args["platform"] as? String ?? ""),
          let appId = args["appId"] as? String else {
      result(StoryResult.error)
      return
    }

    guard canOpen(scheme: target.urlScheme),
          let shareUrl = URL(string: "\(target.urlScheme)://share?source_application=\(appId)") else {
      result(StoryResult.appNotInstalled)
      return
    }

    var pasteboardItem: [String: Any] = [:]
    let ns = target.stickerNamespace

    if let path = args["backgroundImagePath"] as? String, let data = data(atPath: path) {
      pasteboardItem["\(ns).backgroundImage"] = data
    } else if let path = args["backgroundVideoPath"] as? String, let data = data(atPath: path) {
      pasteboardItem["\(ns).backgroundVideo"] = data
    }
    if let path = args["stickerImagePath"] as? String, let data = data(atPath: path) {
      pasteboardItem["\(ns).stickerImage"] = data
    }
    if let top = args["backgroundTopColor"] as? String {
      pasteboardItem["\(ns).backgroundTopColor"] = top
    }
    if let bottom = args["backgroundBottomColor"] as? String {
      pasteboardItem["\(ns).backgroundBottomColor"] = bottom
    }
    if let contentUrl = args["contentUrl"] as? String {
      pasteboardItem["\(ns).contentURL"] = contentUrl
    }
    // Facebook needs the app id inside the pasteboard item; Instagram reads it
    // from the source_application URL query instead. Without this, Facebook
    // opens but drops the story and returns to its home screen.
    if target == .facebook {
      pasteboardItem["\(ns).appID"] = appId
    }

    let hasAsset = pasteboardItem.keys.contains {
      $0.hasSuffix(".backgroundImage") || $0.hasSuffix(".backgroundVideo") || $0.hasSuffix(".stickerImage")
    }
    guard hasAsset else {
      result(StoryResult.missingContent)
      return
    }

    let options: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date().addingTimeInterval(60 * 5)
    ]
    UIPasteboard.general.setItems([pasteboardItem], options: options)
    UIApplication.shared.open(shareUrl, options: [:]) { opened in
      result(opened ? StoryResult.success : StoryResult.appNotInstalled)
    }
  }

  // MARK: - Direct text sharing

  private func handleText(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let target = args["target"] as? String else {
      result(StoryResult.error)
      return
    }
    let text = args["text"] as? String ?? ""
    let url = args["url"] as? String
    let phone = args["phone"] as? String
    let hashtags = args["hashtags"] as? [String]
    let recipients = args["recipients"] as? [String]

    guard let shareUrl = textShareURL(
      target: target, text: text, url: url, phone: phone, hashtags: hashtags, recipients: recipients
    ) else {
      result(StoryResult.error)
      return
    }

    guard UIApplication.shared.canOpenURL(shareUrl) else {
      result(StoryResult.appNotInstalled)
      return
    }
    UIApplication.shared.open(shareUrl, options: [:]) { opened in
      result(opened ? StoryResult.success : StoryResult.appNotInstalled)
    }
  }

  private func textShareURL(
    target: String, text: String, url: String?, phone: String?,
    hashtags: [String]?, recipients: [String]?
  ) -> URL? {
    let joined = [text, url].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
    switch target {
    case "whatsapp":
      if let phone = phone, !phone.isEmpty {
        return URL(string: "https://wa.me/\(phone)?text=\(enc(joined))")
      }
      return URL(string: "whatsapp://send?text=\(enc(joined))")
    case "telegram":
      return URL(string: "tg://msg?text=\(enc(joined))")
    case "twitter":
      var query = "text=\(enc(text))"
      if let url = url, !url.isEmpty { query += "&url=\(enc(url))" }
      if let hashtags = hashtags, !hashtags.isEmpty { query += "&hashtags=\(enc(hashtags.joined(separator: ",")))" }
      return URL(string: "https://twitter.com/intent/tweet?\(query)")
    case "sms":
      let to = recipients?.joined(separator: ",") ?? ""
      return URL(string: "sms:\(to)&body=\(enc(joined))")
    default:
      return nil
    }
  }

  // MARK: - System share sheet

  private func handleSystemShare(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    var items: [Any] = []
    if let text = args?["text"] as? String, !text.isEmpty {
      items.append(text)
    }
    if let path = args?["imagePath"] as? String, FileManager.default.fileExists(atPath: path) {
      items.append(URL(fileURLWithPath: path))
    }
    guard !items.isEmpty else {
      result(StoryResult.missingContent)
      return
    }
    guard let root = topViewController() else {
      result(StoryResult.error)
      return
    }
    let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
    // Required on iPad, where the sheet is presented as a popover.
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = root.view
      popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    root.present(activityVC, animated: true)
    result(StoryResult.success)
  }

  private func topViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = keyWindow?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  // MARK: - Clipboard

  private func handleCopy(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    if let text = args?["text"] as? String {
      UIPasteboard.general.string = text
    }
    if let path = args?["imagePath"] as? String, let image = UIImage(contentsOfFile: path) {
      UIPasteboard.general.image = image
    }
    result(nil)
  }

  // MARK: - Helpers

  private func canOpen(scheme: String) -> Bool {
    guard let url = URL(string: "\(scheme)://") else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private func installScheme(for app: String) -> String {
    switch app {
    case "instagram": return "instagram-stories"
    case "facebook": return "facebook-stories"
    case "whatsapp": return "whatsapp"
    case "telegram": return "tg"
    case "twitter": return "twitter"
    default: return app
    }
  }

  private func enc(_ value: String) -> String {
    return value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
  }

  private func data(atPath path: String) -> Data? {
    return try? Data(contentsOf: URL(fileURLWithPath: path))
  }
}

/// The story share target and its platform-specific identifiers.
private enum StoryTarget: String {
  case instagram
  case facebook

  var urlScheme: String {
    switch self {
    case .instagram: return "instagram-stories"
    case .facebook: return "facebook-stories"
    }
  }

  var stickerNamespace: String {
    switch self {
    case .instagram: return "com.instagram.sharedSticker"
    case .facebook: return "com.facebook.sharedSticker"
    }
  }
}

/// String results mirrored by the Dart `ShareResult` enum.
private enum StoryResult {
  static let success = "success"
  static let appNotInstalled = "appNotInstalled"
  static let missingContent = "missingContent"
  static let error = "error"
}
