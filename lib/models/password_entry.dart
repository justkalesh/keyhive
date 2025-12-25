import 'package:hive/hive.dart';

part 'password_entry.g.dart';

/// PasswordEntry - A HiveObject model for storing password data securely.
/// 
/// SECURITY NOTE: This model is stored in an AES-256 encrypted Hive box.
/// The password field is stored as plain text within the encrypted box,
/// meaning decryption happens at the box level, not the field level.
@HiveType(typeId: 0)
class PasswordEntry extends HiveObject {
  /// Unique identifier for the entry (UUID v4)
  @HiveField(0)
  final String id;

  /// Name of the platform/service (e.g., "Netflix", "Google")
  @HiveField(1)
  String platformName;

  /// Username or email associated with the account
  @HiveField(2)
  String username;

  /// The password (stored encrypted at box level)
  @HiveField(3)
  String password;

  /// When the entry was first created
  @HiveField(4)
  final DateTime dateCreated;

  /// When the entry was last modified
  @HiveField(5)
  DateTime dateModified;

  PasswordEntry({
    required this.id,
    required this.platformName,
    required this.username,
    required this.password,
    required this.dateCreated,
    required this.dateModified,
  });

  /// Creates a copy with updated fields (immutable update pattern)
  PasswordEntry copyWith({
    String? platformName,
    String? username,
    String? password,
  }) {
    return PasswordEntry(
      id: id,
      platformName: platformName ?? this.platformName,
      username: username ?? this.username,
      password: password ?? this.password,
      dateCreated: dateCreated,
      dateModified: DateTime.now(),
    );
  }
}
