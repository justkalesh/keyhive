import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/providers.dart';
import '../models/password_entry.dart';
import '../theme/app_theme.dart';
import '../utils/clipboard_helper.dart';
import '../widgets/tutorial_overlay.dart';

/// HomeScreen - Main screen with password list, favorites, and categories
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  List<PasswordEntry> _filterByCategory(List<PasswordEntry> passwords) {
    if (_selectedCategory == 'All') return passwords;
    return passwords.where((p) => p.category == _selectedCategory).toList();
  }

  List<PasswordEntry> _sortByFavorites(List<PasswordEntry> passwords) {
    // Separate favorites and non-favorites while preserving provider's sort order
    final favorites = passwords.where((p) => p.isFavorite).toList();
    final others = passwords.where((p) => !p.isFavorite).toList();
    // Return favorites first, then others - both maintain their original sort order
    return [...favorites, ...others];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawPasswords = ref.watch(filteredPasswordsProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final showTutorial = ref.watch(showTutorialProvider);
    
    // Apply category filter and sort by favorites
    final filteredByCategory = _filterByCategory(rawPasswords);
    final passwords = _sortByFavorites(filteredByCategory);

    return TutorialOverlay(
      showTutorial: showTutorial,
      onComplete: () async {
        // Mark tutorial as completed
        ref.read(showTutorialProvider.notifier).state = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_completed_tutorial', true);
      },
      child: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                autofocus: true,
                cursorColor: theme.colorScheme.primary,
                decoration: InputDecoration(
                  hintText: 'Search passwords...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.normal,
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              )
            : isDarkMode
                ? ShaderMask(
                    shaderCallback: (bounds) => AppTheme.goldGradient.createShader(bounds),
                    child: const Text(
                      'KeyHive',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Text(
                    'KeyHive',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _toggleSearch,
              )
            : const SizedBox.shrink(),
        leadingWidth: _isSearching ? null : 0,
        actions: [
          // Search/Close button
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: _isSearching
                ? () {
                    if (_searchController.text.isNotEmpty) {
                      _searchController.clear();
                      _onSearchChanged('');
                    } else {
                      _toggleSearch();
                    }
                  }
                : _toggleSearch,
          ),
          // Only show menu when not searching
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
        ],
      ),
      endDrawer: _buildDrawer(theme, isDarkMode),
      body: Column(
        children: [
          // Category Filter Chips with Sort button
          if (!_isSearching)
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  // Sort button
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: PopupMenuButton<SortOption>(
                      icon: Icon(
                        Icons.sort_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'Sort',
                      onSelected: (option) {
                        ref.read(sortOptionProvider.notifier).state = option;
                      },
                      itemBuilder: (context) {
                        final currentSort = ref.read(sortOptionProvider);
                        return [
                          _buildSortMenuItem(SortOption.nameAsc, 'A → Z', Icons.sort_by_alpha_rounded, currentSort),
                          _buildSortMenuItem(SortOption.nameDesc, 'Z → A', Icons.sort_by_alpha_rounded, currentSort),
                          _buildSortMenuItem(SortOption.dateNewest, 'Newest', Icons.schedule_rounded, currentSort),
                          _buildSortMenuItem(SortOption.dateOldest, 'Oldest', Icons.history_rounded, currentSort),
                        ];
                      },
                    ),
                  ),
                  // Category chips
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 8, right: 16),
                      children: [
                        _CategoryChip(
                          label: 'All',
                          isSelected: _selectedCategory == 'All',
                          onTap: () => setState(() => _selectedCategory = 'All'),
                        ),
                        ...PasswordEntry.categories.map((category) => _CategoryChip(
                          label: category,
                          isSelected: _selectedCategory == category,
                          onTap: () => setState(() => _selectedCategory = category),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Password List
          Expanded(
            child: passwords.isEmpty
                ? _buildEmptyState(theme)
                : _buildPasswordList(passwords, theme),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppTheme.goldGradient : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).pushNamed('/add'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add_rounded, color: isDarkMode ? theme.scaffoldBackgroundColor : Colors.white),
        ),
      ),
    ),
    );
  }

  PopupMenuItem<SortOption> _buildSortMenuItem(
    SortOption option,
    String label,
    IconData icon,
    SortOption currentSort,
  ) {
    final theme = Theme.of(context);
    final isSelected = currentSort == option;
    return PopupMenuItem<SortOption>(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme, bool isDarkMode) {
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.logoGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'KeyHive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Secure Password Manager',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Theme Toggle
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(isDarkModeProvider.notifier).state = value;
                },
              ),
            ),

            const Divider(),

            // Settings
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/settings');
              },
            ),

            const Spacer(),

            // Version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final searchQuery = ref.watch(searchQueryProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.neonGradient.createShader(bounds),
              child: Icon(
                searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.lock_outline_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isNotEmpty ? 'No matches found' : 'No passwords yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try a different search'
                  : 'Tap + to add your first password',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordList(List<PasswordEntry> passwords, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: passwords.length,
      itemBuilder: (context, index) {
        final entry = passwords[index];
        return _FuturisticPasswordTile(
          entry: entry,
          index: index,
          onTap: () {
            Navigator.of(context).pushNamed('/detail', arguments: entry.id);
          },
          onFavoriteToggle: () {
            ref.read(passwordListProvider.notifier).toggleFavorite(entry.id);
          },
          onLongPress: () {
            final autoClear = ref.read(clipboardAutoClearProvider);
            final duration = ref.read(clipboardClearDurationProvider);
            ClipboardHelper.copyWithFeedback(
              context,
              entry.password,
              message: 'Password copied!',
              autoClear: autoClear,
              clearAfter: Duration(seconds: duration),
            );
          },
        );
      },
    );
  }
}

/// Category filter chip
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Futuristic password tile with gradient accent, favorite star, and favicon
class _FuturisticPasswordTile extends StatelessWidget {
  final PasswordEntry entry;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onLongPress;

  const _FuturisticPasswordTile({
    required this.entry,
    required this.index,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF22D3EE), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
    ];
    final accentColor = colors[entry.platformName.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: entry.isFavorite 
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Platform icon - try favicon if websiteUrl exists
                _buildPlatformIcon(entry, accentColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.platformName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Category badge
                          if (entry.category != 'General')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                entry.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.username,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Favorite star
                IconButton(
                  icon: Icon(
                    entry.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: entry.isFavorite ? Colors.amber : Colors.grey[600],
                  ),
                  onPressed: onFavoriteToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    'icloud': 'icloud.com',
    'microsoft': 'microsoft.com',
    'outlook': 'outlook.com',
    'yahoo': 'yahoo.com',
    'dropbox': 'dropbox.com',
    'paypal': 'paypal.com',
    'ebay': 'ebay.com',
    'snapchat': 'snapchat.com',
    'tiktok': 'tiktok.com',
    'pinterest': 'pinterest.com',
    'twitch': 'twitch.tv',
    'steam': 'steampowered.com',
    'epic': 'epicgames.com',
    'playstation': 'playstation.com',
    'xbox': 'xbox.com',
    'nintendo': 'nintendo.com',
    'whatsapp': 'whatsapp.com',
    'telegram': 'telegram.org',
    'slack': 'slack.com',
    'zoom': 'zoom.us',
    'notion': 'notion.so',
    'figma': 'figma.com',
    'adobe': 'adobe.com',
    'canva': 'canva.com',
    'wordpress': 'wordpress.com',
    'medium': 'medium.com',
    'quora': 'quora.com',
    'uber': 'uber.com',
    'airbnb': 'airbnb.com',
    'booking': 'booking.com',
    'flipkart': 'flipkart.com',
    'myntra': 'myntra.com',
    'swiggy': 'swiggy.com',
    'zomato': 'zomato.com',
    'paytm': 'paytm.com',
    'phonepe': 'phonepe.com',
    'gpay': 'pay.google.com',
  };

  Widget _buildPlatformIcon(PasswordEntry entry, Color accentColor) {
    String? domain;

    // First try websiteUrl
    if (entry.websiteUrl != null && entry.websiteUrl!.isNotEmpty) {
      domain = entry.websiteUrl!;
      if (domain.startsWith('http://') || domain.startsWith('https://')) {
        try {
          domain = Uri.parse(domain).host;
        } catch (_) {}
      }
    }
    
    // If no websiteUrl, try platform name mapping
    if (domain == null || domain.isEmpty) {
      final platformLower = entry.platformName.toLowerCase().trim();
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            'https://www.google.com/s2/favicons?domain=$domain&sz=64',
            width: 52,
            height: 52,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(entry, accentColor);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildFallbackIcon(entry, accentColor);
            },
          ),
        ),
      );
    }

    return _buildFallbackIcon(entry, accentColor);
  }

  Widget _buildFallbackIcon(PasswordEntry entry, Color accentColor) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor,
            accentColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          entry.platformName.isNotEmpty
              ? entry.platformName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
