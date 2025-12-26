import 'package:flutter/material.dart';

/// Tutorial step data
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Alignment spotlightPosition;
  final bool showSpotlight;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.spotlightPosition = Alignment.center,
    this.showSpotlight = false,
  });
}

/// Interactive tutorial overlay widget
class TutorialOverlay extends StatefulWidget {
  final Widget child;
  final bool showTutorial;
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.child,
    required this.showTutorial,
    required this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> 
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const List<TutorialStep> _steps = [
    TutorialStep(
      title: 'Welcome to KeyHive! 🔐',
      description: 'Your secure, offline password manager.\nLet\'s take a quick tour of the app.',
      icon: Icons.waving_hand_rounded,
    ),
    TutorialStep(
      title: 'Add Passwords',
      description: 'Tap the + button at the bottom right to add your first password.',
      icon: Icons.add_circle_outline_rounded,
      spotlightPosition: Alignment.bottomRight,
      showSpotlight: true,
    ),
    TutorialStep(
      title: 'Organize with Categories',
      description: 'Use category filters to organize passwords by type - Social, Banking, Work, and more.',
      icon: Icons.category_rounded,
      spotlightPosition: Alignment.topCenter,
      showSpotlight: true,
    ),
    TutorialStep(
      title: 'Quick Search',
      description: 'Tap the search icon to quickly find any password by name or username.',
      icon: Icons.search_rounded,
      spotlightPosition: Alignment.topRight,
      showSpotlight: true,
    ),
    TutorialStep(
      title: 'Settings & Backup',
      description: 'Access settings, backup your passwords, and customize the app from the menu.',
      icon: Icons.menu_rounded,
      spotlightPosition: Alignment.topRight,
      showSpotlight: true,
    ),
    TutorialStep(
      title: 'You\'re All Set! 🎉',
      description: 'Your passwords are encrypted with AES-256 and stored only on your device. Stay secure!',
      icon: Icons.check_circle_outline_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (widget.showTutorial) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _completeTutorial() {
    _animationController.reverse().then((_) {
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showTutorial) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final step = _steps[_currentStep];
    final size = MediaQuery.of(context).size;

    // Calculate spotlight position based on alignment
    Positioned? spotlightWidget;
    if (step.showSpotlight) {
      final safeTop = MediaQuery.of(context).padding.top;
      double? top, bottom, left, right;
      
      if (step.spotlightPosition == Alignment.topLeft) {
        top = safeTop + 0; // App bar area
        left = 10;
      } else if (step.spotlightPosition == Alignment.topCenter) {
        top = safeTop + 50; // Below app bar, at category filters
        left = (size.width - 60) / 2; // Centered
      } else if (step.spotlightPosition == Alignment.topRight) {
        top = safeTop + 0; // App bar area
        right = 10;
      } else if (step.spotlightPosition == Alignment.bottomRight) {
        bottom = 30; // FAB position
        right = 16;
      } else if (step.spotlightPosition == Alignment.bottomLeft) {
        bottom = 30;
        left = 16;
      } else if (step.spotlightPosition == Alignment.center) {
        top = (size.height - 60) / 2;
        left = (size.width - 60) / 2;
      }
      
      spotlightWidget = Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        widget.child,
        // Dark overlay
        FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () {}, // Prevent taps from passing through
            child: Stack(
              children: [
                // Dark background
                Container(color: Colors.black.withValues(alpha: 0.85)),
                // Spotlight (absolutely positioned)
                if (spotlightWidget != null) spotlightWidget,
                // Content
                SafeArea(
                  child: Column(
                    children: [
                      // Skip button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextButton(
                            onPressed: _completeTutorial,
                            child: Text(
                              'Skip',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                    
                      // Content card
                      Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step.icon,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Title
                            Text(
                              step.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            
                            // Description
                            Text(
                              step.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            
                            // Progress indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _steps.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentStep == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentStep == index
                                        ? theme.colorScheme.primary
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Navigation buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Back button
                                _currentStep > 0
                                    ? TextButton.icon(
                                        onPressed: _previousStep,
                                        icon: const Icon(Icons.arrow_back_rounded),
                                        label: const Text('Back'),
                                      )
                                    : const SizedBox(width: 100),
                                
                                // Next/Done button
                                FilledButton.icon(
                                  onPressed: _nextStep,
                                  icon: Icon(
                                    _currentStep == _steps.length - 1
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                  ),
                                  label: Text(
                                    _currentStep == _steps.length - 1
                                        ? 'Get Started'
                                        : 'Next',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
