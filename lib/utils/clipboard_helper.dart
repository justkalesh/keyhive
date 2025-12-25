import 'package:flutter/services.dart';

/// Clipboard utility with auto-clear functionality
/// 
/// SECURITY: Automatically clears sensitive data from clipboard
/// after a specified duration to prevent accidental exposure.
class ClipboardHelper {
  static const Duration defaultClearDuration = Duration(seconds: 30);

  /// Copies text to clipboard and automatically clears it after duration
  static Future<void> copyWithAutoClear(
    String text, {
    Duration clearAfter = defaultClearDuration,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));

    // Schedule clipboard clear
    Future.delayed(clearAfter, () async {
      // Only clear if the clipboard still contains our text
      final currentData = await Clipboard.getData('text/plain');
      if (currentData?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }
}
