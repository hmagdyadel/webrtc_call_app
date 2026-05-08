# Sawa (سوا) — Progress Tracker

## Phase Status Overview

| Phase | Description | Status |
|-------|-------------|--------|
| 1–4 | Infrastructure, Firebase, Auth, Home & Chat List | ✅ Complete |
| 5 | Bug Fixes (icons, OTP loop, mounted, Firestore index) | ✅ Complete |
| 6 | Navigation & UX Polish | ✅ Complete |
| 7 | Chat Screen & Real Messaging | 🔲 Next |
| 8 | QR Code | 🔲 Planned |
| 9 | WebRTC Voice Calls | 🔲 Planned |
| 10 | Video Calls | 🔲 Planned |
| 11 | Push Notifications (FCM) | 🔲 Planned |
| 12 | Native Call UI (CallKit/ConnectionService) | 🔲 Planned |
| 13 | Profile & Settings | 🔲 Planned |
| 14 | Contacts Sync | 🔲 Planned |
| 15 | Production Hardening | 🔲 Planned |

---

## Phase 6 — Navigation & UX Polish ✅

### 6a: go_router ✅
- Replaced all `Navigator.push` with `go_router`
- Auth guard redirect logic: splash → onboarding → auth/home
- `GoRouterRefresh` listens to both auth stream and onboarding store

### 6b: Rename to Sawa ✅
- `pubspec.yaml` package renamed to `sawa`
- Android `applicationId` + namespace → `com.sawa.app`
- Android launcher label → `Sawa`
- iOS `CFBundleDisplayName` + `CFBundleName` → `Sawa`
- iOS bundle identifiers → `com.sawa.app`

### 6c: Sawa theme ✅
- Created `lib/app/theme/app_colors.dart` — full brand palette
- Created `lib/app/theme/app_theme.dart` — `sawaTheme()` using Plus Jakarta Sans
- Wired in `lib/app/app.dart`

### 6d: google_fonts ✅
- Plus Jakarta Sans integrated via `google_fonts` package

### 6e: flutter_easyloading ✅
- `EasyLoading.init()` in MaterialApp builder
- Auth flow (PhoneScreen, OtpScreen) uses HUD/toast instead of inline spinners

### 6f: Asset folders ✅
- Registered `assets/animations/`, `assets/icons/`, `assets/images/` in pubspec
- All animation files placed and referenced

### 6g: App icon ✅
- Generated Sawa icon: two overlapping speech bubbles (purple س + teal S)
- Deep purple gradient background (#3D33A8 → #5B4FD4), white dot at overlap
- SVG source at `assets/icons/sawa_icon.svg`
- PNG at `assets/icons/app_icon.png` (1024×1024)
- Adaptive foreground at `assets/icons/app_icon_foreground.png`
- `dart run flutter_launcher_icons` — Android (adaptive + legacy) + iOS generated

### 6h: Splash screen ✅
- `SplashScreen` with Lottie animation + branded Arabic/English text
- Routes based on onboarding + auth state after 2s delay

### 6i: Onboarding ✅
- 3-page onboarding with Lottie animations (chat, voice, video)
- Arabic-first bilingual text
- `SharedPreferences` flag for first-launch persistence
- Skip/Get Started buttons with smooth page indicator

### 6j: Home theme migration ✅
- `HomeScreen` migrated from hardcoded blue/grey to `AppColors` system
- NavigationBar, AppBar, FAB, ChatTile all use brand colors

### Lottie Animations ✅
- `splash.json` — 2.5s, two bubbles appear + ripple rings (no loop)
- `onboarding_chat.json` — 3s, sent/received bubbles + typing dots (loop)
- `onboarding_voice.json` — 3s, phone circle + ripple rings + 7 waveform bars (loop)
- `onboarding_video.json` — 3.5s, two phone screens + connection dots + avatars (loop)
- All use exact Sawa brand colors (#5B4FD4, #00C8A0, #7B6FEE)

---

## What Currently Exists (Code Inventory)

### Auth Feature — FULLY WORKING
- `UserModel` (Freezed) — id, phone, name, avatarUrl, isOnline, createdAt
- `AuthRemoteSource` — Firebase Phone OTP send + verify
- `UserRemoteSource` — Firestore user create + read
- `AuthRepository` — orchestrates both sources
- `AuthCubit` — 7 states (initial/loading/sendingOtp/otpSent/authenticated/unauthenticated/error)
- `PhoneScreen` + `OtpScreen` — complete auth flow

### Chat Feature — PARTIAL (list only, no messaging)
- `ChatModel` (Freezed) — id, members, lastMessage, lastMessageSenderId, lastMessageTime, unreadCount
- `ChatRemoteSource` — getChats stream, createOrGetChat
- `ChatRepository` — delegates to source
- `ChatCubit` + `ChatState` — loads chat list via Firestore stream
- `HomeScreen` — 5-tab NavigationBar with chat list
- `NewChatScreen` — lists registered users, creates/opens chats
- ❌ No `MessageModel` yet
- ❌ No `ChatScreen` yet
- ❌ No message sending/receiving

### Router
- Routes: `/splash`, `/onboarding`, `/auth/phone`, `/auth/otp`, `/home`, `/home/new-chat`
- ❌ Missing: `/home/chat/:chatId`

---

## Known Issues / Bugs
- None currently — `flutter analyze` returns zero issues

## Test Accounts
| Phone | OTP | Firestore UID |
|-------|-----|---------------|
| +20 1125516481 | 123456 | GnNAYAP1W3YV9jwH7CRUtCa0VBv2 |

---

## Exact Start Point for Next Session
1. **Phase 7 — Chat Screen & Real Messaging**
   - Create `MessageModel` (Freezed)
   - Add message methods to `ChatRemoteSource` + `ChatRepository`
   - Create `MessageCubit` + `MessageState`
   - Build `ChatScreen` UI with Sawa-branded message bubbles
   - Add `/home/chat/:chatId` route
   - Wire chat tile tap → navigate to ChatScreen
   - Run `dart run build_runner build --delete-conflicting-outputs`
   - Test on Samsung device: two devices exchange messages in real-time

---

*Last updated: May 8, 2026 — Session: App Icon + Lottie Animations + Phase 6 Complete*
