import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/providers.dart';
import '../services/backup_service.dart';
import '../models/password_entry.dart';

/// SettingsScreen - App settings and preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDarkMode = ref.watch(isDarkModeProvider);
    
    // Security settings
    final clipboardAutoClear = ref.watch(clipboardAutoClearProvider);
    final clipboardDuration = ref.watch(clipboardClearDurationProvider);
    final lockOnMinimize = ref.watch(lockOnMinimizeProvider);
    final passwordAutoHide = ref.watch(passwordAutoHideProvider);
    final passwordVisibilityDuration = ref.watch(passwordVisibilityDurationProvider);
    final importAutoResolve = ref.watch(importAutoResolveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance', theme),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: Text(isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
              secondary: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(isDarkModeProvider.notifier).state = value;
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Security Section
          _buildSectionHeader('Security', theme),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // Clipboard Auto-Clear Toggle
                SwitchListTile(
                  title: const Text('Auto-clear Clipboard'),
                  subtitle: Text(
                    clipboardAutoClear 
                        ? 'Clears copied passwords after ${clipboardDuration}s'
                        : 'Disabled - passwords stay in clipboard',
                  ),
                  secondary: Icon(
                    Icons.content_paste_off_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  value: clipboardAutoClear,
                  onChanged: (value) {
                    ref.read(clipboardAutoClearProvider.notifier).state = value;
                  },
                ),
                
                // Clipboard Duration Slider
                if (clipboardAutoClear)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Slider(
                            value: clipboardDuration.toDouble(),
                            min: 10,
                            max: 120,
                            divisions: 11,
                            label: '${clipboardDuration}s',
                            onChanged: (value) {
                              ref.read(clipboardClearDurationProvider.notifier).state = value.toInt();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 45,
                          child: Text(
                            '${clipboardDuration}s',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Divider(height: 1),
                
                // Lock on Minimize Toggle
                SwitchListTile(
                  title: const Text('Lock When Minimized'),
                  subtitle: Text(
                    lockOnMinimize 
                        ? 'Requires authentication when app reopened'
                        : 'App stays unlocked when minimized',
                  ),
                  secondary: Icon(
                    Icons.screen_lock_portrait_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  value: lockOnMinimize,
                  onChanged: (value) {
                    ref.read(lockOnMinimizeProvider.notifier).state = value;
                  },
                ),
                
                const Divider(height: 1),
                
                // Password Auto-Hide Toggle
                SwitchListTile(
                  title: const Text('Auto-hide Passwords'),
                  subtitle: Text(
                    passwordAutoHide 
                        ? 'Hides visible passwords after ${passwordVisibilityDuration}s'
                        : 'Passwords stay visible until toggled',
                  ),
                  secondary: Icon(
                    Icons.visibility_off_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  value: passwordAutoHide,
                  onChanged: (value) {
                    ref.read(passwordAutoHideProvider.notifier).state = value;
                  },
                ),
                
                // Password Visibility Duration Slider
                if (passwordAutoHide)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Slider(
                            value: passwordVisibilityDuration.toDouble(),
                            min: 5,
                            max: 60,
                            divisions: 11,
                            label: '${passwordVisibilityDuration}s',
                            onChanged: (value) {
                              ref.read(passwordVisibilityDurationProvider.notifier).state = value.toInt();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 45,
                          child: Text(
                            '${passwordVisibilityDuration}s',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data & Backup Section
          _buildSectionHeader('Data & Backup', theme),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-resolve Conflicts'),
                  subtitle: Text(
                    importAutoResolve 
                        ? 'Keeps most recent password automatically'
                        : 'Ask for each conflicting password',
                  ),
                  secondary: Icon(
                    importAutoResolve ? Icons.auto_mode_rounded : Icons.touch_app_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  value: importAutoResolve,
                  onChanged: (value) {
                    ref.read(importAutoResolveProvider.notifier).state = value;
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.backup_rounded, color: theme.colorScheme.primary),
                  title: const Text('Export Encrypted Backup'),
                  subtitle: const Text('Save passwords as encrypted file'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final passwords = ref.read(passwordListProvider);
                    if (passwords.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No passwords to backup'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    
                    // Create backup file first
                    final encryptionService = ref.read(encryptionServiceProvider);
                    final backupService = BackupService(encryptionService);
                    final filePath = await backupService.exportBackup(passwords);
                    
                    if (filePath == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to create backup'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }
                    
                    // Get file info
                    final file = File(filePath);
                    final fileSize = await file.length();
                    final fileName = filePath.split('/').last.split('\\').last;
                    final fileSizeStr = fileSize > 1024 
                        ? '${(fileSize / 1024).toStringAsFixed(1)} KB'
                        : '$fileSize bytes';
                    
                    // Show dialog with options
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Backup Ready'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.insert_drive_file_rounded, 
                                       color: theme.colorScheme.primary, size: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          fileSizeStr,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${passwords.length} passwords encrypted',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                // Save directly to Downloads folder
                                try {
                                  final downloadsDir = Directory('/storage/emulated/0/Download');
                                  if (await downloadsDir.exists()) {
                                    final destPath = '${downloadsDir.path}/$fileName';
                                    await file.copy(destPath);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Saved to Downloads: $fileName'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Fallback: use share
                                    await backupService.shareBackup(passwords);
                                  }
                                } catch (e) {
                                  await backupService.shareBackup(passwords);
                                }
                              },
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download'),
                            ),
                            FilledButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                await backupService.shareBackup(passwords);
                              },
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Share'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
              leading: Icon(Icons.restore_rounded, color: theme.colorScheme.primary),
              title: const Text('Import Backup'),
              subtitle: const Text('Restore from encrypted backup file'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                // Pick file
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  allowMultiple: false,
                );
                
                if (result == null || result.files.isEmpty) {
                  return;
                }
                
                final filePath = result.files.first.path;
                if (filePath == null) {
                  return;
                }
                
                // Show loading
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 16),
                          Text('Importing backup...'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                
                // Import backup
                final encryptionService = ref.read(encryptionServiceProvider);
                final backupService = BackupService(encryptionService);
                final entries = await backupService.importBackup(filePath);
                
                if (entries != null && entries.isNotEmpty && context.mounted) {
                  // Get existing passwords
                  final existingPasswords = ref.read(passwordListProvider);
                  final passwordNotifier = ref.read(passwordListProvider.notifier);
                  final passwordService = ref.read(passwordServiceProvider);
                  
                  // Find all conflicts first
                  final conflicts = <({PasswordEntry existing, PasswordEntry backup})>[];
                  final newEntries = <PasswordEntry>[];
                  
                  for (final entry in entries) {
                    final existing = existingPasswords.cast<PasswordEntry?>().firstWhere(
                      (e) => e?.platformName.toLowerCase() == entry.platformName.toLowerCase() 
                          && e?.username.toLowerCase() == entry.username.toLowerCase(),
                      orElse: () => null,
                    );
                    
                    if (existing != null) {
                      conflicts.add((existing: existing, backup: entry));
                    } else {
                      newEntries.add(entry);
                    }
                  }
                  
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  
                  int importedCount = 0;
                  int updatedCount = 0;
                  int skippedCount = 0;
                  
                  // Handle conflicts
                  if (conflicts.isNotEmpty && context.mounted) {
                    final autoResolve = ref.read(importAutoResolveProvider);
                    
                    if (autoResolve) {
                      // Auto-resolve: keep most recent password
                      for (final conflict in conflicts) {
                        if (conflict.backup.dateModified.isAfter(conflict.existing.dateModified)) {
                          // Backup is newer - update
                          final updatedEntry = PasswordEntry(
                            id: conflict.existing.id,
                            platformName: conflict.backup.platformName,
                            username: conflict.backup.username,
                            password: conflict.backup.password,
                            dateCreated: conflict.existing.dateCreated,
                            dateModified: conflict.backup.dateModified,
                            websiteUrl: conflict.backup.websiteUrl,
                            notes: conflict.backup.notes,
                            category: conflict.backup.category,
                            isFavorite: conflict.backup.isFavorite,
                          );
                          await passwordService.updatePassword(updatedEntry);
                          updatedCount++;
                        } else {
                          // Existing is newer or same - skip
                          skippedCount++;
                        }
                      }
                    } else {
                      // Manual: show dialog for each conflict
                      final result = await showDialog<Map<String, String>>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => _ConflictResolutionDialog(conflicts: conflicts),
                      );
                      
                      if (result != null) {
                        for (final conflict in conflicts) {
                          final action = result[conflict.existing.id] ?? 'skip';
                          
                          if (action == 'backup') {
                            // Use backup password
                            final updatedEntry = PasswordEntry(
                              id: conflict.existing.id,
                              platformName: conflict.backup.platformName,
                              username: conflict.backup.username,
                              password: conflict.backup.password,
                              dateCreated: conflict.existing.dateCreated,
                              dateModified: conflict.backup.dateModified,
                              websiteUrl: conflict.backup.websiteUrl,
                              notes: conflict.backup.notes,
                              category: conflict.backup.category,
                              isFavorite: conflict.backup.isFavorite,
                            );
                            await passwordService.updatePassword(updatedEntry);
                            updatedCount++;
                          } else {
                            // Keep existing (skip)
                            skippedCount++;
                          }
                        }
                      } else {
                        // User cancelled
                        skippedCount = conflicts.length;
                      }
                    }
                  }
                  
                  // Add new entries (no conflicts)
                  for (final entry in newEntries) {
                    await passwordNotifier.addPassword(
                      platformName: entry.platformName,
                      username: entry.username,
                      password: entry.password,
                      websiteUrl: entry.websiteUrl,
                      notes: entry.notes,
                      category: entry.category,
                    );
                    importedCount++;
                  }
                  
                  // Refresh the list
                  passwordNotifier.loadPasswords();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Import complete: $importedCount new, $updatedCount updated, $skippedCount unchanged',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to import backup. Invalid file or wrong key.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader('About', theme),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.security, color: theme.colorScheme.primary),
                  title: const Text('Encryption'),
                  subtitle: const Text('AES-256 with biometric authentication'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                  title: const Text('About Developer'),
                  subtitle: const Text('Learn more about the creator'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AboutDeveloperScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// About Developer Screen
class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Me'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/developer.jpg',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kalash',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Developer',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bio Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, I'm Kalash, a Computer Science undergrad passionate about building efficient software solutions.",
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "I developed KeyHive to solve the issue of storing passwords locally instead of online platforms. This project was designed to demonstrate clean architecture and seamless user experience using Flutter.",
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "I am constantly learning and open to new opportunities. Check out my other projects below.",
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Links Section
            Text(
              'My Links',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _LinkTile(
                    icon: FontAwesomeIcons.linkedin,
                    title: 'LinkedIn',
                    subtitle: 'linkedin.com/in/justkalesh',
                    url: 'https://www.linkedin.com/in/justkalesh/',
                    color: const Color(0xFF0A66C2),
                  ),
                  const Divider(height: 1),
                  _LinkTile(
                    icon: FontAwesomeIcons.github,
                    title: 'GitHub',
                    subtitle: 'github.com/justkalesh',
                    url: 'https://github.com/justkalesh/',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  const Divider(height: 1),
                  _LinkTile(
                    icon: FontAwesomeIcons.instagram,
                    title: 'Instagram',
                    subtitle: '@kalash.hu',
                    url: 'https://www.instagram.com/kalash.hu/',
                    color: const Color(0xFFE4405F),
                  ),
                  const Divider(height: 1),
                  _LinkTile(
                    icon: FontAwesomeIcons.envelope,
                    title: 'Email',
                    subtitle: 'parth.ie.kalash@gmail.com',
                    url: 'mailto:parth.ie.kalash@gmail.com',
                    color: const Color(0xFFEA4335),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final Color color;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FaIcon(icon, color: color, size: 22),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () async {
        try {
          final uri = Uri.parse(url);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (context.mounted) {
            // Copy link to clipboard as fallback
            await Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Link copied: $subtitle'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }
}

/// Dialog for resolving import conflicts
class _ConflictResolutionDialog extends StatefulWidget {
  final List<({PasswordEntry existing, PasswordEntry backup})> conflicts;

  const _ConflictResolutionDialog({required this.conflicts});

  @override
  State<_ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<_ConflictResolutionDialog> {
  late Map<String, String> _decisions;

  @override
  void initState() {
    super.initState();
    // Default to keeping existing (skip)
    _decisions = {
      for (final c in widget.conflicts) c.existing.id: 'skip'
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text('${widget.conflicts.length} Conflict${widget.conflicts.length > 1 ? 's' : ''} Found'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: widget.conflicts.length,
          separatorBuilder: (_, __) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final conflict = widget.conflicts[index];
            final existing = conflict.existing;
            final backup = conflict.backup;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform name header
                Text(
                  '${existing.platformName} (${existing.username})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Keep Existing option
                RadioListTile<String>(
                  value: 'skip',
                  groupValue: _decisions[existing.id],
                  onChanged: (v) => setState(() => _decisions[existing.id] = v!),
                  title: const Text('Keep Existing'),
                  subtitle: Text(
                    'Modified: ${_formatDate(existing.dateModified)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                
                // Use Backup option
                RadioListTile<String>(
                  value: 'backup',
                  groupValue: _decisions[existing.id],
                  onChanged: (v) => setState(() => _decisions[existing.id] = v!),
                  title: const Text('Use Backup'),
                  subtitle: Text(
                    'Modified: ${_formatDate(backup.dateModified)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel Import'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _decisions),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
