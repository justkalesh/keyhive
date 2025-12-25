import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/password_entry.dart';
import '../utils/clipboard_helper.dart';

/// DetailScreen - Display full password entry details.
/// 
/// Features:
/// - Show all password details
/// - Copy password to clipboard with auto-clear (30s)
/// - Password visibility timer (auto-hide after 30s)
/// - Edit and Delete actions
class DetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const DetailScreen({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _obscurePassword = true;
  PasswordEntry? _entry;
  Timer? _visibilityTimer;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    super.dispose();
  }

  void _loadEntry() {
    final passwordService = ref.read(passwordServiceProvider);
    setState(() {
      _entry = passwordService.getPasswordById(widget.entryId);
    });
  }

  /// Toggle password visibility with auto-hide timer
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });

    // Cancel existing timer
    _visibilityTimer?.cancel();

    // If showing password, start auto-hide timer (30 seconds)
    if (!_obscurePassword) {
      _visibilityTimer = Timer(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() {
            _obscurePassword = true;
          });
        }
      });
    }
  }

  Future<void> _copyPassword() async {
    if (_entry == null) return;

    // Use auto-clear clipboard helper (clears after 30 seconds)
    await ClipboardHelper.copyWithAutoClear(_entry!.password);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password copied (auto-clears in 30s)'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyUsername() async {
    if (_entry == null) return;

    await Clipboard.setData(ClipboardData(text: _entry!.username));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username copied'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password'),
        content: Text(
          'Are you sure you want to delete the password for "${_entry?.platformName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _entry != null) {
      await ref.read(passwordListProvider.notifier).deletePassword(_entry!.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(passwordListProvider, (previous, next) {
      _loadEntry();
    });

    if (_entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details')),
        body: const Center(child: Text('Password not found')),
      );
    }

    final iconColor = _getPlatformColor(_entry!.platformName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/edit', arguments: _entry!.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _entry!.platformName.isNotEmpty
                              ? _entry!.platformName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _entry!.platformName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Username
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: 'Username',
                        value: _entry!.username,
                        onCopy: _copyUsername,
                      ),

                      const Divider(height: 24),

                      // Password with visibility timer
                      _DetailRow(
                        icon: Icons.lock_outline,
                        label: 'Password',
                        value: _obscurePassword
                            ? '•' * _entry!.password.length.clamp(8, 16)
                            : _entry!.password,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Visibility toggle with timer indicator
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                                // Show timer indicator when visible
                                if (!_obscurePassword)
                                  Positioned(
                                    bottom: 8,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy_outlined,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              onPressed: _copyPassword,
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 24),

                      // Created Date
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: _formatDate(_entry!.dateCreated),
                      ),

                      const Divider(height: 24),

                      // Modified Date
                      _DetailRow(
                        icon: Icons.update_outlined,
                        label: 'Last Modified',
                        value: _formatDate(_entry!.dateModified),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Copy Password Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _copyPassword,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Password'),
                ),
              ),

              // Security info
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Password will auto-clear from clipboard in 30 seconds',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getPlatformColor(String platformName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.red,
    ];
    final hash = platformName.toLowerCase().hashCode.abs();
    return colors[hash % colors.length];
  }
}

/// Helper widget for displaying a detail row
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onCopy;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (onCopy != null && trailing == null)
          IconButton(
            icon: Icon(
              Icons.copy_outlined,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: onCopy,
          ),
      ],
    );
  }
}
