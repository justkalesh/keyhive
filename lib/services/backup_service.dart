import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/password_entry.dart';
import 'encryption_service.dart';

/// BackupService - Export and import encrypted password backups
class BackupService {
  final EncryptionService _encryptionService;

  BackupService(this._encryptionService);

  /// Export all passwords as an encrypted JSON file
  /// Returns the path to the created file
  Future<String?> exportBackup(List<PasswordEntry> passwords) async {
    try {
      // Convert passwords to JSON
      final jsonList = passwords.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode({
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'passwords': jsonList,
      });

      // Encrypt the JSON string
      final encryptedData = _encryptionService.encryptString(jsonString);

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'keyhive_backup_$timestamp.kh';
      final filePath = '${directory.path}/$fileName';

      // Write encrypted data to file
      final file = File(filePath);
      await file.writeAsString(encryptedData);

      return filePath;
    } catch (e) {
      debugPrint('Backup export failed: $e');
      return null;
    }
  }

  /// Share the backup file with other apps
  Future<bool> shareBackup(List<PasswordEntry> passwords) async {
    try {
      final filePath = await exportBackup(passwords);
      if (filePath == null) return false;

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'KeyHive Password Backup',
        text: 'Encrypted password backup from KeyHive',
      );

      return true;
    } catch (e) {
      debugPrint('Backup share failed: $e');
      return false;
    }
  }

  /// Import passwords from an encrypted backup file
  Future<List<PasswordEntry>?> importBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      // Read encrypted data
      final encryptedData = await file.readAsString();

      // Decrypt
      final jsonString = _encryptionService.decryptString(encryptedData);
      if (jsonString == null) return null;

      // Parse JSON
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final passwordsJson = jsonData['passwords'] as List;

      // Convert to PasswordEntry objects
      final passwords = passwordsJson
          .map((json) => PasswordEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      return passwords;
    } catch (e) {
      debugPrint('Backup import failed: $e');
      return null;
    }
  }
}
