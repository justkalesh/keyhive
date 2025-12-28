# 🔐 KeyHive - Secure Offline Password Manager

<p align="center">
  <img src="assets/icon.png" alt="KeyHive Logo" width="120" height="120">
</p>

<p align="center">
  <strong>A secure, offline-first password manager built with Flutter</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#security">Security</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#getting-started">Getting Started</a>
</p>

---

## ✨ Features

### 🔒 Security First
- **AES-256 Encryption** - All passwords encrypted at rest using industry-standard AES-256
- **Biometric Authentication** - Fingerprint, Face ID, or device PIN/pattern protection
- **Offline-Only Storage** - Your data never leaves your device, no cloud sync
- **Auto-Lock** - Automatically locks when app is minimized (configurable)

### 📱 User Experience
- **Beautiful Dark/Light Themes** - Navy blue & gold premium design
- **Interactive Tutorial** - Guided onboarding for new users
- **Category Organization** - Sort passwords by Social, Banking, Work, Shopping, etc.
- **Favorites & Search** - Quick access to frequently used passwords
- **Smart Favicons** - Automatic website icons for 50+ popular platforms

### 💾 Data Management
- **Encrypted Backup/Restore** - Export passwords as encrypted `.kh` files
- **Share Backups** - Securely share backup files via any app
- **Import Data** - Restore from encrypted backup files
- **Copy to Clipboard** - One-tap copy with auto-clear option

---

## 🛡️ Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     USER AUTHENTICATION                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Fingerprint │  │   Face ID   │  │ Device PIN/Pattern  │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         └────────────────┼────────────────────┘             │
│                          ▼                                  │
│              ┌───────────────────────┐                      │
│              │   LOCAL_AUTH CHECK    │                      │
│              └───────────┬───────────┘                      │
└──────────────────────────┼──────────────────────────────────┘
                           │ On Success
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   ENCRYPTION LAYER                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │         FLUTTER SECURE STORAGE                      │    │
│  │    (Android Keystore / iOS Keychain)                │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │  256-bit AES Encryption Key (Auto-generated)│    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────┘    │
│                          │                                  │
│                          ▼ Key used to open                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              HIVE ENCRYPTED BOX                     │    │
│  │         (AES-256 CBC Mode Encryption)               │    │
│  │  ┌──────────────────────────────────────────────┐   │    │
│  │  │  📁 Password Entries  Encrypted at Rest      │   │    │
│  │  │    • Platform Name                           │   │    │
│  │  │    • Username/Email                          │   │    │
│  │  │    • Password                                │   │    │
│  │  │    • Website URL                             │   │    │
│  │  │    • Notes & Category                        │   │    │
│  │  └──────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Security Flow

1. **First Launch**: A cryptographically secure 32-byte AES key is generated
2. **Key Storage**: The key is stored in Flutter Secure Storage (Android Keystore / iOS Keychain)
3. **App Launch**: User must authenticate via biometrics or device credentials
4. **Data Access**: On successful auth, the encryption key opens the encrypted Hive database
5. **No Auth = No Data**: Without authentication, passwords remain encrypted and inaccessible

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart              # App entry point, routing, lifecycle management
├── models/
│   └── password_entry.dart   # Password data model with Hive adapter
├── providers/
│   └── providers.dart        # Riverpod state management
├── screens/
│   ├── lock_screen.dart      # Biometric authentication screen
│   ├── home_screen.dart      # Main password list view
│   ├── add_edit_screen.dart  # Create/edit password form
│   ├── detail_screen.dart    # Password details view
│   └── settings_screen.dart  # App settings & preferences
├── services/
│   ├── auth_service.dart       # Biometric/device authentication
│   ├── encryption_service.dart # AES-256 key management
│   ├── password_service.dart   # CRUD operations for passwords
│   └── backup_service.dart     # Export/import encrypted backups
├── theme/
│   └── app_theme.dart        # Dark/light theme definitions
├── utils/
│   └── clipboard_helper.dart # Secure clipboard operations
└── widgets/
    └── tutorial_overlay.dart # Interactive onboarding tutorial
```

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.10+ |
| **State Management** | Riverpod |
| **Local Database** | Hive (with AES encryption) |
| **Secure Storage** | flutter_secure_storage |
| **Authentication** | local_auth |
| **Encryption** | encrypt (AES-256-CBC) |

### Data Model

```dart
class PasswordEntry {
  final String id;           // UUID v4
  String platformName;       // e.g., "Netflix"
  String username;           // Username or email
  String password;           // Encrypted at box level
  final DateTime dateCreated;
  DateTime dateModified;
  String? websiteUrl;        // Optional URL
  String? notes;             // Optional notes
  String category;           // General, Social, Banking, etc.
  bool isFavorite;           // Quick access flag
}
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.3 or higher
- Android Studio / VS Code with Flutter extensions
- Android device/emulator (API 21+) or iOS device/simulator

### Installation

```bash
# Clone the repository
git clone https://github.com/justkalesh/keyhive.git
cd keyhive

# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build

# Run the app
flutter run
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS with Xcode)
flutter build ipa --release
```

---

## 📱 Screens

| Lock Screen | Home Screen | Add Password |
|-------------|-------------|--------------|
| Biometric authentication | Password list with categories | Create new entries |
| PIN/Pattern fallback | Search & favorites | Password generator |

| Password Details | Settings |
|------------------|----------|
| View/copy credentials | Dark/light theme toggle |
| Edit/delete options | Auto-lock settings |
| Website launch | Backup & restore |

---

## ⚙️ Configuration

### Available Settings

- **Dark Mode** - Toggle between dark and light themes
- **Lock on Minimize** - Auto-lock when app goes to background (5+ seconds)
- **Clipboard Auto-Clear** - Automatically clear copied passwords
- **Clear Duration** - Time before clipboard is wiped (15-120 seconds)
- **Backup/Restore** - Export and import encrypted password backups

---

## 🔐 Backup Format

Backups are exported as `.kh` files containing:

```json
{
  "version": 1,
  "exportDate": "2024-12-28T12:00:00.000Z",
  "passwords": [...]
}
```

The entire JSON payload is encrypted using AES-256-CBC with a random IV:
```
Format: iv_base64:ciphertext_base64
```

> ⚠️ **Important**: Backups can only be restored on devices where the same encryption key exists. If you uninstall the app, you'll lose the ability to decrypt your backups!

---

## 👨‍💻 Developer

**Kalash Mani Tripathi**

---

## 📄 License

This project is proprietary software. All rights reserved.

---

<p align="center">
  Made with ❤️ using Flutter
</p>
