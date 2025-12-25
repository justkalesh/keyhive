import 'dart:math';

/// Password Generator Utility
/// 
/// Generates secure random passwords with configurable options.
class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Generate a secure random password
  /// 
  /// [length] - Length of the password (default: 16, minimum: 12)
  /// [includeUppercase] - Include uppercase letters (default: true)
  /// [includeLowercase] - Include lowercase letters (default: true)
  /// [includeNumbers] - Include numbers (default: true)
  /// [includeSymbols] - Include special characters (default: true)
  static String generate({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    // Ensure minimum length of 12
    if (length < 12) length = 12;

    // Build character pool
    String charPool = '';
    List<String> requiredChars = [];

    if (includeLowercase) {
      charPool += _lowercase;
      requiredChars.add(_lowercase);
    }
    if (includeUppercase) {
      charPool += _uppercase;
      requiredChars.add(_uppercase);
    }
    if (includeNumbers) {
      charPool += _numbers;
      requiredChars.add(_numbers);
    }
    if (includeSymbols) {
      charPool += _symbols;
      requiredChars.add(_symbols);
    }

    // Fallback to all characters if nothing selected
    if (charPool.isEmpty) {
      charPool = _lowercase + _uppercase + _numbers + _symbols;
      requiredChars = [_lowercase, _uppercase, _numbers, _symbols];
    }

    final random = Random.secure();
    final password = StringBuffer();

    // Ensure at least one character from each required set
    for (final charSet in requiredChars) {
      password.write(charSet[random.nextInt(charSet.length)]);
    }

    // Fill remaining length with random characters from pool
    for (int i = password.length; i < length; i++) {
      password.write(charPool[random.nextInt(charPool.length)]);
    }

    // Shuffle the password to randomize position of required characters
    final chars = password.toString().split('');
    chars.shuffle(random);

    return chars.join();
  }

  /// Generate a memorable password using words and numbers
  static String generateMemorable({int wordCount = 3}) {
    const words = [
      'apple', 'banana', 'cherry', 'delta', 'eagle', 'flash',
      'grace', 'honey', 'ivory', 'jazz', 'kite', 'lemon',
      'mango', 'ninja', 'orbit', 'piano', 'quest', 'river',
      'solar', 'tiger', 'ultra', 'vivid', 'water', 'xenon',
      'yoga', 'zebra', 'amber', 'blaze', 'coral', 'drift',
    ];

    final random = Random.secure();
    final buffer = StringBuffer();

    for (int i = 0; i < wordCount; i++) {
      if (i > 0) buffer.write('-');
      String word = words[random.nextInt(words.length)];
      // Capitalize first letter
      buffer.write(word[0].toUpperCase() + word.substring(1));
    }

    // Add random number
    buffer.write(random.nextInt(999).toString().padLeft(3, '0'));

    return buffer.toString();
  }
}
