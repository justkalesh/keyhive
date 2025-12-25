import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/password_entry.dart';
import '../utils/password_strength.dart';
import '../utils/password_generator.dart';

/// AddEditScreen - Create or edit password entries.
/// 
/// Features:
/// - TextFields for Platform, Username, Password, Website, Notes
/// - Password visibility toggle
/// - Password generator button
/// - Password strength indicator
/// - Validation logic
/// - Save/Update functionality
class AddEditScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const AddEditScreen({
    super.key,
    this.entryId,
  });

  @override
  ConsumerState<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends ConsumerState<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _platformController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isEditing = false;
  PasswordEntry? _existingEntry;
  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _isEditing = widget.entryId != null;

    // Listen to password changes for strength indicator
    _passwordController.addListener(() {
      setState(() {
        _currentPassword = _passwordController.text;
      });
    });

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final passwordService = ref.read(passwordServiceProvider);
        final entry = passwordService.getPasswordById(widget.entryId!);
        if (entry != null) {
          setState(() {
            _existingEntry = entry;
            _platformController.text = entry.platformName;
            _usernameController.text = entry.username;
            _passwordController.text = entry.password;
            _websiteController.text = entry.websiteUrl ?? '';
            _notesController.text = entry.notes ?? '';
            _currentPassword = entry.password;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _platformController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final generated = PasswordGenerator.generate(length: 16);
    _passwordController.text = generated;
    setState(() {
      _obscurePassword = false; // Show the generated password
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Strong password generated!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(passwordListProvider.notifier);

      if (_isEditing && _existingEntry != null) {
        final updatedEntry = PasswordEntry(
          id: _existingEntry!.id,
          platformName: _platformController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          dateCreated: _existingEntry!.dateCreated,
          dateModified: DateTime.now(),
          websiteUrl: _websiteController.text.trim().isEmpty 
              ? null 
              : _websiteController.text.trim(),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );
        await notifier.updatePassword(updatedEntry);
      } else {
        await notifier.addPassword(
          platformName: _platformController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          websiteUrl: _websiteController.text.trim().isEmpty 
              ? null 
              : _websiteController.text.trim(),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Password updated successfully' 
                : 'Password saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Password' : 'Add Password'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePassword,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Platform Name Field
                _buildSectionLabel('Platform', theme),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _platformController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Netflix, Google, Bank',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the platform name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Username/Email Field
                _buildSectionLabel('Username or Email', theme),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g., john@example.com',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the username or email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Password Field with Generator
                _buildSectionLabel('Password', theme),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Generate button
                        IconButton(
                          icon: Icon(
                            Icons.auto_awesome,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Generate password',
                          onPressed: _generatePassword,
                        ),
                        // Visibility toggle
                        IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the password';
                    }
                    return null;
                  },
                ),

                // Password Strength Indicator
                PasswordStrengthIndicator(password: _currentPassword),

                const SizedBox(height: 24),

                // Website URL Field (Optional)
                _buildSectionLabel('Website URL', theme, optional: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'e.g., https://netflix.com',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),

                const SizedBox(height: 24),

                // Notes Field (Optional)
                _buildSectionLabel('Notes', theme, optional: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Additional notes (security questions, etc.)',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.note_outlined),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePassword,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Update Password' : 'Save Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, ThemeData theme, {bool optional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        if (optional)
          Text(
            ' (optional)',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
      ],
    );
  }
}
