# Sawa (سوا) — Progress Tracker

## Phase Status Overview

| Phase | Description | Status |
|-------|-------------|--------|
| 1–4 | Infrastructure, Firebase, Auth, Home & Chat List | ✅ Complete |
| 5 | Bug Fixes (icons, OTP loop, mounted, Firestore index) | ✅ Complete |
| 6 | Navigation & UX Polish | ✅ Complete |
| 7 | Chat Screen & Real Messaging | ✅ Complete |
| 8 | QR Code | ✅ Complete |
| 9 | WebRTC Voice Calls | 🔲 Next |
| 10 | Video Calls | 🔲 Planned |
| 11 | Push Notifications (FCM) | 🔲 Planned |
| 12 | Native Call UI (CallKit/ConnectionService) | 🔲 Planned |
| 13 | Profile & Settings | ✅ Complete |
| 14 | Last Seen & Status Toggle | ✅ Complete |
| 15 | Contacts Sync | 🔲 Planned |
| 15 | Contacts Sync | 🔲 Planned |
| 16 | Production Hardening | 🔲 Planned |
| 17 | Multimedia Chat (Audio 2.0, Location 2.0, Native Contacts) | ✅ Complete |

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

## Phase 7 — Chat Screen & Real Messaging ✅

### 7a: Data Models ✅
- Created `MessageModel` (Freezed) with Firestore `TimestampConverter`
- Updated `ChatModel` to correctly deserialize Firestore `Timestamp` for `last_message_time`

### 7b: Backend Integration ✅
- Updated `ChatRemoteSource` with real-time `getMessages` stream
- Implemented `sendMessage` with atomic metadata updates using `WriteBatch`
- Added `createOrGetChat` for deterministic 1:1 chat initialization

### 7c: Business Logic ✅
- Implemented `MessageCubit` for message stream management and sending actions
- Enhanced `ChatCubit` to handle real-time chat list updates with proper subscription lifecycle

### 7d: UI/UX ✅
- Created `ChatScreen` with Sawa-branded AppBar and auto-scrolling message list
- Developed `MessageBubble` widget with Sawa purple/dark surface theme and status indicators
- Fixed `_ChatTile` in `HomeScreen` to fetch and display actual user names/phones instead of UIDs
- Added default person icon for users without names or pictures

### 7e: DI & Routing ✅
- Registered all new Cubits in `getIt`
- Added `/home/chat/:chatId` route in `AppRouter`
- Implemented `pushReplacement` navigation for smoother transitions

---

## 🔀 Git Branching Workflow (MANDATORY)

> **Every phase gets its own branch. Merge to main only after all test cases pass.**

### Rules
1. Before starting a phase: `git checkout -b feature/phase-{N}-{description}`
2. Commit frequently with descriptive messages during development
3. After all test cases pass: commit final state, then merge:
   ```bash
   git checkout main
   git merge feature/phase-{N}-{description}
   git push origin main
   ```
4. Never push broken code to `main`

### Branch History
| Branch | Phase | Status |
|--------|-------|--------|
| `main` | Phases 1–7 | ✅ Merged |
| `feature/phase-7-chat-messaging` | Phase 7 | ✅ Complete |

---

## ✅ Phase 7 — Test Cases (Chat Screen & Real Messaging)

All must pass before merging to `main`:

### T7.1 — Code Quality
- [x] `flutter analyze` returns zero issues
- [x] `dart run build_runner build` succeeds without errors

### T7.2 — Navigation
- [x] Tapping a chat tile in HomeScreen navigates to ChatScreen
- [x] ChatScreen AppBar shows the other user's name (not UID)
- [x] Back button returns to HomeScreen

### T7.3 — Message Sending
- [x] Type text in input field → tap send → message appears in chat
- [x] Message bubble is purple (`#5B4FD4`), right-aligned (sent)
- [x] Input field clears after sending
- [x] Chat list's `lastMessage` updates with sent text

### T7.4 — Message Receiving (Real-time)
- [x] Send message from Device B → appears instantly on Device A
- [x] Received message bubble is dark (`#22223A`), left-aligned
- [x] Messages are ordered by timestamp (newest at bottom)

### T7.5 — Message Status
- [x] Sent messages show single ✓ (sent status)
- [x] Timestamp displayed on each message bubble

### T7.6 — Empty State
- [x] New chat with no messages shows "Start the conversation" placeholder

### T7.7 — Edge Cases
- [x] Sending empty message is prevented (send button disabled)
- [x] Long messages wrap properly inside bubbles
- [x] Scrolling works with many messages

---

---

## Phase 17 — Multimedia Chat (Images, Videos, Files, Location, Progress) ✅

### 17a: Media Support Architecture ✅
- Updated `MessageModel` to include `mediaUrl` and `metadata`
- Implemented `uploadMedia` in `ChatRepository` using Firebase Storage
- Enhanced `MessageCubit` with `sendMediaMessage` and `sendLocationMessage`

### 17b: Audio & Location Sharing 2.0 ✅
- **Audio 2.0**: Added waveform animations (recording & playback), playback speed toggle (1x-2x), and seeking.
- **Dynamic Input Bar**: Mic/Send button toggle with real-time waveform during record.
- **Location 2.0**: Coordinate-based card UI with `geo:` deep linking for native map apps.

### 17c: Contacts & Files ✅
- **Native Contacts**: Full implementation of native contact picker with permission guarding.
- **File Messaging**: Improved document picking and preview logic.
- **UX Polish**: Added "🎤 Voice message" previews to the main chat list.
- **Upload Flow**: Integrated percentage-based progress tracking for audio and images.

---

## Latest Session Updates (May 2026)

- Upgraded audio message UI to WhatsApp-style behavior:
  - waveform bars UI with progress highlight
  - tap on waveform to seek
  - playback speed toggle: `1x` → `1.25x` → `1.5x` → `2x`
  - upload state integrated into audio bubble (progress percent while sending)
- Audio local file playback remains available before upload completes.
- Location bubble no longer relies on static map APIs or keys:
  - shows current latitude/longitude only
  - opens coordinates via `geo:` deep link (with browser fallback)
- Ran `dart analyze`: zero issues.

---

*Last updated: May 10, 2026 — Branch: main*
