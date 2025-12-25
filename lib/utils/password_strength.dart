import 'package:flutter/material.dart';

/// Password Strength Calculator Utility
/// 
/// Calculates password strength based on:
/// - Length (minimum 8, optimal 12+)
/// - Uppercase letters
/// - Lowercase letters
/// - Numbers
/// - Special characters

enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
}

class PasswordStrengthResult {
  final PasswordStrength strength;
  final double score; // 0.0 to 1.0
  final String label;
  final Color color;

  const PasswordStrengthResult({
    required this.strength,
    required this.score,
    required this.label,
    required this.color,
  });
}

class PasswordStrengthCalculator {
  static PasswordStrengthResult calculate(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        strength: PasswordStrength.weak,
        score: 0.0,
        label: '',
        color: Colors.grey,
      );
    }

    int score = 0;

    // Length scoring
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;

    // Character type scoring
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1; // lowercase
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1; // uppercase
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1; // numbers
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1; // special

    // Calculate normalized score (max possible: 7)
    double normalizedScore = (score / 7).clamp(0.0, 1.0);

    // Determine strength level
    if (normalizedScore < 0.3) {
      return PasswordStrengthResult(
        strength: PasswordStrength.weak,
        score: normalizedScore,
        label: 'Weak',
        color: Colors.red,
      );
    } else if (normalizedScore < 0.5) {
      return PasswordStrengthResult(
        strength: PasswordStrength.fair,
        score: normalizedScore,
        label: 'Fair',
        color: Colors.orange,
      );
    } else if (normalizedScore < 0.75) {
      return PasswordStrengthResult(
        strength: PasswordStrength.good,
        score: normalizedScore,
        label: 'Good',
        color: Colors.amber,
      );
    } else {
      return PasswordStrengthResult(
        strength: PasswordStrength.strong,
        score: normalizedScore,
        label: 'Strong',
        color: Colors.green,
      );
    }
  }
}

/// Password Strength Indicator Widget
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final result = PasswordStrengthCalculator.calculate(password);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: result.score,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: result.color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                result.label,
                style: TextStyle(
                  color: result.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
