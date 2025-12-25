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

  /// Website URL (optional)
  @HiveField(6)
  String? websiteUrl;

  /// Additional notes (optional)
  @HiveField(7)
  String? notes;

  /// Category for organizing passwords
  @HiveField(8)
  String category;

  /// Whether this entry is marked as favorite
  @HiveField(9)
  bool isFavorite;

  PasswordEntry({
    required this.id,
    required this.platformName,
    required this.username,
    required this.password,
    required this.dateCreated,
    required this.dateModified,
    this.websiteUrl,
    this.notes,
    this.category = 'General',
    this.isFavorite = false,
  });

  /// Available categories for password entries
  static const List<String> categories = [
    'General',
    'Social',
    'Banking',
    'Work',
    'Shopping',
    'Entertainment',
    'Other',
  ];

  /// Creates a copy with updated fields (immutable update pattern)
  PasswordEntry copyWith({
    String? platformName,
    String? username,
    String? password,
    String? websiteUrl,
    String? notes,
    String? category,
    bool? isFavorite,
  }) {
    return PasswordEntry(
      id: id,
      platformName: platformName ?? this.platformName,
      username: username ?? this.username,
      password: password ?? this.password,
      dateCreated: dateCreated,
      dateModified: DateTime.now(),
      websiteUrl: websiteUrl ?? this.websiteUrl,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Check if password is older than specified days
  bool isOlderThan(int days) {
    return DateTime.now().difference(dateModified).inDays > days;
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platformName': platformName,
      'username': username,
      'password': password,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
      'websiteUrl': websiteUrl,
      'notes': notes,
      'category': category,
      'isFavorite': isFavorite,
    };
  }

  /// Create from JSON for restore/import
  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'],
      platformName: json['platformName'],
      username: json['username'],
      password: json['password'],
      dateCreated: DateTime.parse(json['dateCreated']),
      dateModified: DateTime.parse(json['dateModified']),
      websiteUrl: json['websiteUrl'],
      notes: json['notes'],
      category: json['category'] ?? 'General',
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
