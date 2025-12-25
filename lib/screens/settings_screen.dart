import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/providers.dart';

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
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.primary,
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
                    icon: Icons.work_outline,
                    title: 'LinkedIn',
                    subtitle: 'linkedin.com/in/justkalesh',
                    url: 'https://www.linkedin.com/in/justkalesh/',
                    color: const Color(0xFF0A66C2),
                  ),
                  const Divider(height: 1),
                  _LinkTile(
                    icon: Icons.code,
                    title: 'GitHub',
                    subtitle: 'github.com/justkalesh',
                    url: 'https://github.com/justkalesh/',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  const Divider(height: 1),
                  _LinkTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Instagram',
                    subtitle: '@kalash.hu',
                    url: 'https://www.instagram.com/kalash.hu/',
                    color: const Color(0xFFE4405F),
                  ),
                  const Divider(height: 1),
                  _LinkTile(
                    icon: Icons.mail_outline,
                    title: 'Email',
                    subtitle: 'parth.ie.kalash@gmail.com',
                    url: 'mailto:parth.ie.kalash@gmail.com',
                    color: theme.colorScheme.primary,
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
      leading: Icon(icon, color: color),
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
