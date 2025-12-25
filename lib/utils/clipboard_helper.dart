import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clipboard utility with auto-clear functionality and visual feedback
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

  /// Copy to clipboard with visual SnackBar feedback
  static Future<void> copyWithFeedback(
    BuildContext context,
    String text, {
    String? message,
    bool autoClear = false,
    Duration clearAfter = defaultClearDuration,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));

    // Schedule auto-clear if enabled
    if (autoClear) {
      Future.delayed(clearAfter, () async {
        final currentData = await Clipboard.getData('text/plain');
        if (currentData?.text == text) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      });
    }

    // Show feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                message ?? (autoClear 
                    ? 'Copied to clipboard (auto-clears in ${clearAfter.inSeconds}s)'
                    : 'Copied to clipboard!'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
