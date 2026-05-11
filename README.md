<p align="center">
  <img src="assets/icons/app_icon.png" width="120" height="120" alt="Sawa Logo"/>
</p>

<h1 align="center">Sawa — سوا</h1>
<p align="center">
  <em>Together, always connected — سوا دايماً متواصلين</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20FCM-FFCA28?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/WebRTC-Voice%20%26%20Video-333333?logo=webrtc" alt="WebRTC"/>
  <img src="https://img.shields.io/badge/Theme-Dynamic%20V2-5B4FD4" alt="Theme"/>
</p>

---

## 📱 About

**Sawa (سوا)** is a full-featured Arabic-first calling and chat app, built with a premium "Business" aesthetic. Inspired by Botim and WhatsApp, it uses a professional Flutter architecture to deliver high-performance real-time communication.

### Key Features
- 🔐 **Phone OTP Authentication** — Firebase Auth with Egypt (+20) default.
- 🎨 **Unified Dynamic Theme System** — Professional `ThemeExtension` architecture supporting Dark and Light modes.
- 💬 **Multimedia Chat** — Text, Images, Videos, Audio (with waveforms), Location, and Native Contacts.
- ✨ **Sticker & Emoji Picker** — Built-in local sticker library, emoji integration, and WhatsApp-style floating sticker rendering.
- 🖼️ **Pro Image Editor** — WhatsApp-style workflow: launches directly into crop mode, custom themed AppBars with recipient status, and streamlined "one-tap" send flow.
- 📞 **Voice & Video Calls** — WebRTC-powered high-quality calling (In Progress).
- 🔗 **QR Code Discovery** — Scan to add contacts instantly.
- 🗺️ **Location Sharing** — Coordinate-based sharing with native map deep linking.

---

## 🎨 Design System

Sawa uses a semantic color system that adapts to the current theme mode.

| Token | Light Mode (Business) | Dark Mode (Premium) |
|-------|------------------------|----------------------|
| Primary | `#5B4FD4` (Purple) | `#5B4FD4` (Purple) |
| Accent | `#00C8A0` (Teal) | `#00C8A0` (Teal) |
| AppBar | `#5B4FD4` (Purple) | `#1A1640` (Dark) |
| Nav Bar | `#F5F4FF` (Lavender) | `#0D0D1E` (Black) |
| Font | Plus Jakarta Sans | Plus Jakarta Sans |

---

## 🏗 Architecture

The project follows **Clean Architecture** principles with a focus on modularity and testability.

- **State Management**: `flutter_bloc` (Cubit) with strict UI/Logic separation.
- **Theme Management**: Professional `ThemeExtension` (`SawaColors`) for type-safe custom color tokens.
- **Dependency Injection**: `get_it` + `injectable` for robust service discovery.
- **Routing**: `go_router` with centralized auth-guarded path management.

---

## 📂 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                         # MaterialApp configuration
│   ├── theme/
│   │   ├── app_colors.dart              # SawaColors ThemeExtension
│   │   └── app_theme.dart               # Theme factory (Light/Dark)
│   └── router/                          # Path-based routing
├── core/
│   ├── di/                              # Dependency Injection setup
│   └── utils/                           # Shared helpers & extensions
└── features/
    ├── chat/                            # Messaging, Media, & Location
    ├── auth/                            # Firebase Phone OTP flow
    ├── profile/                         # Settings & Dynamic Themes
    └── splash/                          # Theme-aware entry screen
```

---

## 🚀 Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code (Freezed, JSON, Injectable)
dart run build_runner build --delete-conflicting-outputs

# 3. Run the app
flutter run
```

---

## 📋 Roadmap

- [x] **Infrastructure & Auth** — Firebase integration & Phone OTP.
- [x] **Core Messaging** — Real-time text & empty states.
- [x] **QR Discovery** — Personal QR cards & scanning.
- [x] **Multimedia Chat** — Audio 2.0, Location 2.0, Files, & Native Contacts.
- [x] **Unified Theme System** — Professional Light/Dark mode migration.
- [ ] **Voice & Video Calls** — WebRTC implementation.
- [ ] **Push Notifications** — Firebase Cloud Messaging integration.

See [PROGRESS.md](PROGRESS.md) for detailed session logs.

---

<p align="center">
  <strong>سوا دايماً متواصلين</strong><br/>
  <em>Together, always connected</em>
</p>
