import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/password_entry.dart';

/// DetailScreen - Display full password entry details.
/// 
/// Features:
/// - Show all password details
/// - Copy password to clipboard with configurable auto-clear
/// - Password visibility timer (configurable via settings)
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

  /// Toggle password visibility with configurable auto-hide timer
  void _togglePasswordVisibility() {
    final autoHideEnabled = ref.read(passwordAutoHideProvider);
    final duration = ref.read(passwordVisibilityDurationProvider);
    
    setState(() {
      _obscurePassword = !_obscurePassword;
    });

    // Cancel existing timer
    _visibilityTimer?.cancel();

    // If showing password and auto-hide is enabled, start timer
    if (!_obscurePassword && autoHideEnabled) {
      _visibilityTimer = Timer(Duration(seconds: duration), () {
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

    final autoClearEnabled = ref.read(clipboardAutoClearProvider);
    final clearDuration = ref.read(clipboardClearDurationProvider);

    await Clipboard.setData(ClipboardData(text: _entry!.password));

    // Schedule clipboard clear if enabled
    if (autoClearEnabled) {
      Future.delayed(Duration(seconds: clearDuration), () async {
        final currentData = await Clipboard.getData('text/plain');
        if (currentData?.text == _entry!.password) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            autoClearEnabled 
                ? 'Password copied (auto-clears in ${clearDuration}s)'
                : 'Password copied to clipboard',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
                    _buildPlatformIcon(iconColor),
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

              const SizedBox(height: 24),

              // Password Expiry Warning (if older than 90 days)
              if (_entry!.isOlderThan(90))
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password is old',
                              style: TextStyle(
                                color: Colors.red[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Update recommended for security',
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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

                      // Website URL (if present)
                      if (_entry!.websiteUrl != null && _entry!.websiteUrl!.isNotEmpty) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.link,
                          label: 'Website',
                          value: _entry!.websiteUrl!,
                        ),
                      ],

                      // Notes (if present)
                      if (_entry!.notes != null && _entry!.notes!.isNotEmpty) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.note_outlined,
                          label: 'Notes',
                          value: _entry!.notes!,
                        ),
                      ],
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

  // Map of common platform names to their domains
  static const Map<String, String> _platformDomains = {
    'google': 'google.com',
    'gmail': 'gmail.com',
    'facebook': 'facebook.com',
    'instagram': 'instagram.com',
    'twitter': 'twitter.com',
    'x': 'x.com',
    'linkedin': 'linkedin.com',
    'netflix': 'netflix.com',
    'amazon': 'amazon.com',
    'spotify': 'spotify.com',
    'youtube': 'youtube.com',
    'github': 'github.com',
    'discord': 'discord.com',
    'reddit': 'reddit.com',
    'apple': 'apple.com',
    'microsoft': 'microsoft.com',
    'paypal': 'paypal.com',
    'snapchat': 'snapchat.com',
    'tiktok': 'tiktok.com',
    'whatsapp': 'whatsapp.com',
    'telegram': 'telegram.org',
    'slack': 'slack.com',
    'zoom': 'zoom.us',
    'flipkart': 'flipkart.com',
    'swiggy': 'swiggy.com',
    'zomato': 'zomato.com',
    'paytm': 'paytm.com',
  };

  Widget _buildPlatformIcon(Color accentColor) {
    String? domain;

    // First try websiteUrl
    if (_entry!.websiteUrl != null && _entry!.websiteUrl!.isNotEmpty) {
      domain = _entry!.websiteUrl!;
      if (domain.startsWith('http://') || domain.startsWith('https://')) {
        try {
          domain = Uri.parse(domain).host;
        } catch (_) {}
      }
    }

    // If no websiteUrl, try platform name mapping
    if (domain == null || domain.isEmpty) {
      final platformLower = _entry!.platformName.toLowerCase().trim();
      domain = _platformDomains[platformLower];

      // Also check if platform name contains a known name
      if (domain == null) {
        for (final platform in _platformDomains.keys) {
          if (platformLower.contains(platform)) {
            domain = _platformDomains[platform];
            break;
          }
        }
      }
    }

    // If we have a domain, try to load favicon
    if (domain != null && domain.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            'https://www.google.com/s2/favicons?domain=$domain&sz=128',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(accentColor);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildFallbackIcon(accentColor);
            },
          ),
        ),
      );
    }

    return _buildFallbackIcon(accentColor);
  }

  Widget _buildFallbackIcon(Color accentColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          _entry!.platformName.isNotEmpty
              ? _entry!.platformName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: accentColor,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
