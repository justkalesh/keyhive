import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/password_entry.dart';

/// AddEditScreen - Create or edit password entries.
/// 
/// Features:
/// - TextFields for Platform, Username, Password
/// - Password visibility toggle
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

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isEditing = false;
  PasswordEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.entryId != null;

    if (_isEditing) {
      // Load existing entry data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final passwordService = ref.read(passwordServiceProvider);
        final entry = passwordService.getPasswordById(widget.entryId!);
        if (entry != null) {
          setState(() {
            _existingEntry = entry;
            _platformController.text = entry.platformName;
            _usernameController.text = entry.username;
            _passwordController.text = entry.password;
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
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(passwordListProvider.notifier);

      if (_isEditing && _existingEntry != null) {
        // Update existing entry
        final updatedEntry = PasswordEntry(
          id: _existingEntry!.id,
          platformName: _platformController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          dateCreated: _existingEntry!.dateCreated,
          dateModified: DateTime.now(),
        );
        await notifier.updatePassword(updatedEntry);
      } else {
        // Create new entry
        await notifier.addPassword(
          platformName: _platformController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
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

                // Password Field
                _buildSectionLabel('Password', theme),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the password';
                    }
                    return null;
                  },
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

  Widget _buildSectionLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
