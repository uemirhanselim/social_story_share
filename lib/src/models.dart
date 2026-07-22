/// A social app that can be targeted for sharing or availability checks.
enum SocialApp {
  instagram,
  facebook,
  whatsapp,
  telegram,
  twitter;

  /// Wire value sent to the native side.
  String get id => name;
}

/// Outcome of a share attempt.
enum ShareResult {
  /// The target app was opened with the content.
  success,

  /// The target app is not installed on the device.
  appNotInstalled,

  /// Nothing to share was provided (e.g. no story asset, or empty text).
  missingContent,

  /// The share failed for another reason (unreadable file, native error, ...).
  error;

  /// Maps the native string result to an enum value.
  static ShareResult fromName(String? value) {
    return ShareResult.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShareResult.error,
    );
  }
}
