# 🗺️ SAWA APP — COMPLETE UI INTERACTION MAP
## Every screen, every button, every widget path documented

---

## HOW TO READ THIS DOCUMENT

Each section follows this pattern:

```
📱 SCREEN NAME
File: lib/features/.../screen_name.dart
Cubit: lib/features/.../cubit_name.dart
State: lib/features/.../state_name.dart

  [Widget name] (type)
  → Action: what happens when user interacts
  → Navigates to: next screen (if any)
  → File: path of destination widget
  → Emits: cubit state emitted (if any)
  → Calls: method called on cubit/repo
```

---

## 🌟 APP STARTUP FLOW

```
main.dart
  └── configureDependencies()
  └── ThemeCubit.loadSavedTheme()     → reads SharedPrefs 'sawa_theme_mode'
  └── runApp(App())

App() → lib/app/app.dart
  └── BlocProvider<ThemeCubit>
  └── BlocBuilder<ThemeCubit, ThemeMode>
      → ThemeMode.system  → follows device setting
      → ThemeMode.dark    → sawaDarkTheme()
      → ThemeMode.light   → sawaLightTheme()
  └── MaterialApp.router(routerConfig: appRouter)
      → initialLocation: '/splash'
```

---

## 📱 SCREEN: SplashScreen
**File:** `lib/features/splash/view/splash_screen.dart`
**Shown:** Cold start, every time app opens

```
SplashScreen (StatefulWidget)
  │
  ├── [Lottie animation] (Lottie.asset)
  │     File: assets/animations/splash.json
  │     → Plays once (2.5s), no interaction
  │
  ├── [SAWA text] (Text)
  │     → No interaction, display only
  │
  ├── [سوا text] (Text)
  │     → No interaction, display only
  │
  └── [Auto-navigate after 2.5s] (_navigate method)
        → Reads SharedPrefs 'onboarding_seen'
        → Reads AuthCubit.state
        
        IF onboarding_seen == false:
          → Navigates to: /onboarding
          → File: lib/features/onboarding/view/onboarding_screen.dart

        ELSE IF isLoggedIn == true:
          → Navigates to: /home
          → File: lib/features/chat/view/screens/home_screen.dart

        ELSE:
          → Navigates to: /auth/phone
          → File: lib/features/auth/view/screens/phone_screen.dart
```

---

## 📱 SCREEN: OnboardingScreen
**File:** `lib/features/onboarding/view/onboarding_screen.dart`
**Shown:** First install only (onboarding_seen = false in SharedPrefs)

```
OnboardingScreen (StatefulWidget)
  │
  ├── [Skip button] (TextButton) — top right
  │     → Calls: SharedPrefs.setBool('onboarding_seen', true)
  │     → Navigates to: /auth/phone
  │     → File: lib/features/auth/view/screens/phone_screen.dart
  │
  ├── [PageView] (PageView.builder) — 3 pages
  │     │
  │     ├── Page 1: Chat animation
  │     │     File: assets/animations/onboarding_chat.json
  │     │     Title: تواصل مع اللي تحبهم
  │     │
  │     ├── Page 2: Voice call animation
  │     │     File: assets/animations/onboarding_voice.json
  │     │     Title: مكالمات زي ما تكون جنب بعض
  │     │
  │     └── Page 3: Video call animation
  │           File: assets/animations/onboarding_video.json
  │           Title: شوف وجه بعض في أي وقت
  │
  ├── [SmoothPageIndicator] (dots)
  │     → No interaction, shows current page
  │
  └── [Next / Get Started button] (ElevatedButton)
        IF page < 2:
          → Calls: _controller.nextPage()
          → Moves to next page (no navigation)
        
        IF page == 2 (last page):
          → Calls: SharedPrefs.setBool('onboarding_seen', true)
          → Navigates to: /auth/phone
          → File: lib/features/auth/view/screens/phone_screen.dart
```

---

## 📱 SCREEN: PhoneScreen
**File:** `lib/features/auth/view/screens/phone_screen.dart`
**Cubit:** `lib/features/auth/viewmodel/auth_cubit.dart`
**State:** `lib/features/auth/viewmodel/auth_state.dart`

```
PhoneScreen (StatefulWidget)
  │
  ├── [Country code selector] (GestureDetector)
  │     → Opens: ModalBottomSheet with country list
  │     → Countries: Egypt +20, Saudi +966, UAE +971, USA +1, UK +44
  │     → On tap country:
  │         → setState(_countryCode = selected)
  │         → Navigator.pop() (closes sheet)
  │
  ├── [Phone number TextField] (TextField)
  │     → keyboardType: TextInputType.phone
  │     → Updates: _phoneController
  │     → No navigation on change
  │
  └── [Continue button] (ElevatedButton)
        IF phone is empty:
          → Shows: SnackBar 'Please enter your phone number'
          → No navigation
        
        IF phone not empty:
          → Calls: AuthCubit.sendOTPWithCallback(fullPhone)
          → Shows: local _isLoading = true (button shows spinner)
          → Emits: AuthState.sendingOtp()
          → Firebase: verifyPhoneNumber() called
          
          ON codeSent callback:
            → Emits: AuthState.otpSent()
            → Navigates to: /auth/otp (extra: phoneNumber)
            → File: lib/features/auth/view/screens/otp_screen.dart
          
          ON error callback:
            → Shows: SnackBar with error message
            → Resets: _isLoading = false
```

---

## 📱 SCREEN: OtpScreen
**File:** `lib/features/auth/view/screens/otp_screen.dart`
**Cubit:** `lib/features/auth/viewmodel/auth_cubit.dart`

```
OtpScreen (StatefulWidget)
  │
  ├── [Back arrow] (AppBar leading)
  │     → Navigates back to: PhoneScreen
  │     → File: lib/features/auth/view/screens/phone_screen.dart
  │
  ├── [6 OTP boxes] (List<TextField>)
  │     → Each box: maxLength 1, numeric
  │     → On digit entered:
  │         → Auto-advance to next box (FocusNode.requestFocus)
  │     → On backspace:
  │         → Move to previous box
  │     → When all 6 filled:
  │         → Auto-calls: _onVerify()
  │
  ├── [Resend code] (TextButton)
  │     → Calls: AuthCubit.sendOTP(phoneNumber)
  │     → Firebase: sends new OTP SMS
  │     → No navigation
  │
  └── [Verify button] (ElevatedButton)
        IF OTP length < 6:
          → Shows: SnackBar 'Please enter the complete code'
        
        IF OTP length == 6:
          → Calls: AuthCubit.verifyOTP(otp)
          → Emits: AuthState.loading()
          → Firebase: signInWithCredential() called
          
          ON success:
            → Emits: AuthState.authenticated(user)
            → Checks Firestore: does user doc exist?
              IF new user: saves UserModel to Firestore users/{uid}
              IF existing: returns existing UserModel
            → main.dart BlocBuilder detects authenticated state
            → Navigates to: /home (extra: userId)
            → File: lib/features/chat/view/screens/home_screen.dart
          
          ON error:
            → Emits: AuthState.error(message)
            → Shows: SnackBar with error
```

---

## 📱 SCREEN: HomeScreen
**File:** `lib/features/chat/view/screens/home_screen.dart`
**Structure:** Scaffold with NavigationBar (5 tabs)

```
HomeScreen (StatefulWidget)
  │
  ├── [NavigationBar] (bottom)
  │     │
  │     ├── Tab 0: Calls 📞
  │     │     → Shows: _CallsTab widget (inline)
  │     │     → File: same file (home_screen.dart)
  │     │
  │     ├── Tab 1: Chats 💬 (DEFAULT)
  │     │     → Shows: _ChatsTab widget
  │     │     → File: same file (home_screen.dart)
  │     │
  │     ├── Tab 2: Explore 🧭
  │     │     → Shows: _ExploreTab widget
  │     │     → File: same file (home_screen.dart)
  │     │
  │     ├── Tab 3: Contacts 👥
  │     │     → Shows: _ContactsTab widget
  │     │     → File: same file (home_screen.dart)
  │     │
  │     └── Tab 4: Me 👤
  │           → Shows: ProfileScreen widget
  │           → File: lib/features/profile/view/screens/profile_screen.dart
  │
  └── [Each tab body — see below]
```

---

## 📱 TAB: Chats (_ChatsTab)
**File:** `lib/features/chat/view/screens/home_screen.dart`
**Cubit:** `lib/features/chat/viewmodel/chat_cubit.dart`

```
_ChatsTab
  │
  ├── [AppBar — "محادثات"]
  │     │
  │     ├── [Search icon ⌕] (IconButton)
  │     │     → TODO: opens search overlay
  │     │     → Not yet implemented
  │     │
  │     └── [Add icon ⊕] (IconButton)
  │           → Navigates to: /home/new-chat
  │           → File: lib/features/chat/view/screens/new_chat_screen.dart
  │
  ├── [BlocBuilder<ChatCubit>]
  │     │
  │     ├── IF loading:
  │     │     → Shows: CircularProgressIndicator (center)
  │     │
  │     ├── IF loaded + chats empty:
  │     │     → Shows: Text 'No chats yet' (center)
  │     │
  │     └── IF loaded + chats not empty:
  │           → Shows: ListView of ChatTile widgets
  │
  └── [ChatTile] (ListTile) — one per chat
        → File: lib/features/chat/view/widgets/chat_tile.dart
        │
        ├── [Avatar] (CircleAvatar)
        │     → Shows: first 2 chars of contact phone/name
        │     → Color: AppColors.primary (#5B4FD4)
        │     → No interaction
        │
        ├── [Contact name/phone] (Text)
        │     → Shows: user.name if set, else user.phone
        │     → No direct interaction
        │
        ├── [Last message preview] (Text)
        │     → Shows: chat.lastMessage
        │     → No direct interaction
        │
        ├── [Timestamp] (Text)
        │     → Shows: formatted time (now/Xm/Xh/Xd)
        │     → No direct interaction
        │
        ├── [Unread badge] (Container)
        │     → Shows: count if unreadCount > 0
        │     → Color: AppColors.primary
        │     → No direct interaction
        │
        └── [Tap on tile] (onTap)
              → Navigates to: /home/chat/:chatId
              → File: lib/features/chat/view/screens/chat_screen.dart
              → Passes: chatId, otherUser, currentUserId
```

---

## 📱 SCREEN: NewChatScreen
**File:** `lib/features/chat/view/screens/new_chat_screen.dart`

```
NewChatScreen (StatefulWidget)
  │
  ├── [AppBar — "New Chat"]
  │     └── [Back arrow] → back to HomeScreen
  │
  ├── [Loading indicator]
  │     → Shows while fetching users from Firestore
  │
  ├── [Empty state]
  │     → Shows: 'No other users found'
  │
  └── [ListView of users] (ListView.builder)
        └── [UserTile] (ListTile)
              │
              ├── [Avatar] (CircleAvatar)
              │     → Last 2 digits of phone
              │
              ├── [Name or phone] (Text)
              │
              └── [Tap] (onTap)
                    → Calls: ChatRemoteSource.createOrGetChat(currentId, otherId)
                    → Creates new chat doc in Firestore IF not exists
                    → Returns: chatId
                    → Navigates to: /home/chat/:chatId
                    → File: lib/features/chat/view/screens/chat_screen.dart
```

---

## 📱 SCREEN: ChatScreen
**File:** `lib/features/chat/view/screens/chat_screen.dart`
**Cubit:** `lib/features/chat/viewmodel/message_cubit.dart`

```
ChatScreen (StatefulWidget)
  │
  ├── [AppBar]
  │     │
  │     ├── [Back arrow] → back to HomeScreen (Chats tab)
  │     │
  │     ├── [Avatar + Name + Last seen] (Row)
  │     │     → Tapping row: TODO → opens contact profile
  │     │
  │     ├── [Video call icon 📹] (IconButton)
  │     │     → Calls: CallCubit.startCall(type: video)
  │     │     → Navigates to: /home/call
  │     │     → File: lib/features/call/view/screens/outgoing_call_screen.dart
  │     │
  │     └── [Voice call icon 📞] (IconButton)
  │           → Calls: CallCubit.startCall(type: voice)
  │           → Navigates to: /home/call
  │           → File: lib/features/call/view/screens/outgoing_call_screen.dart
  │
  ├── [Messages ListView] (BlocBuilder<MessageCubit>)
  │     └── [MessageBubble] — one per message
  │           → File: lib/features/chat/view/widgets/message_bubble.dart
  │           │
  │           ├── IF type == text:
  │           │     → Shows: text bubble (purple sent, dark/light received)
  │           │
  │           ├── IF type == image:
  │           │     → Shows: CachedNetworkImage in rounded container
  │           │     → [Tap image]: TODO → opens full screen image viewer
  │           │
  │           ├── IF type == sticker:
  │           │     → Shows: CachedNetworkImage, NO bubble background
  │           │     → Floating transparent image
  │           │
  │           └── IF type == call_log:
  │                 → Shows: call icon + duration + missed/answered
  │
  └── [Bottom input bar]
        │
        ├── [Attachment icon 📎] (IconButton)
        │     → Opens: showModalBottomSheet with options
        │     │
        │     ├── [Gallery 🖼️] (ListTile)
        │     │     → Opens: ImagePicker (gallery)
        │     │     → On image selected:
        │     │         → Navigates to: ImagePreviewScreen
        │     │         → File: lib/features/chat/view/screens/image_preview_screen.dart
        │     │
        │     ├── [Camera 📷] (ListTile)
        │     │     → Opens: ImagePicker (camera)
        │     │     → On photo taken:
        │     │         → Navigates to: ImagePreviewScreen
        │     │         → File: lib/features/chat/view/screens/image_preview_screen.dart
        │     │
        │     └── [Document 📄] (ListTile)
        │           → TODO: file picker
        │
        ├── [Emoji icon 😊] (IconButton)
        │     → TODO: opens emoji keyboard
        │
        ├── [TextField] (TextField)
        │     → Updates: _messageController
        │     → On change: shows/hides send button
        │
        └── [Send button ➤] (IconButton)
              → IF text not empty:
                  → Calls: MessageCubit.sendTextMessage(text)
                  → Saves to: Firestore chats/{chatId}/messages/{id}
                  → Updates: chats/{chatId} lastMessage + last_message_time
                  → Clears: _messageController
```

---

## 📱 SCREEN: ImagePreviewScreen
**File:** `lib/features/chat/view/screens/image_preview_screen.dart`

```
ImagePreviewScreen (StatefulWidget)
  │
  ├── [AppBar]
  │     │
  │     ├── [Back arrow] → back to ChatScreen (no send)
  │     │
  │     ├── [Contact avatar + name + online status] (Row)
  │     │     → Display only, no interaction
  │     │
  │     └── [Send icon ➤] (IconButton) — top right
  │           → Calls: _sendImage(asSticker: false)
  │           → Uploads to: Firebase Storage chats/{chatId}/images/
  │           → Saves message type: image
  │           → Navigates back to: ChatScreen
  │
  ├── [Image preview] (InteractiveViewer)
  │     → Pinch to zoom, pan
  │     → No buttons here
  │
  └── [Bottom action bar]
        │
        ├── [تعديل — Edit button] (GestureDetector)
        │     → Opens: ProImageEditor (full screen)
        │     → File: pro_image_editor package
        │     → User can: draw, write text, add emoji, apply filters
        │     → On save: updates _currentFile with edited image
        │     → Returns to: ImagePreviewScreen with edited image
        │
        ├── [اقتصاص — Crop button] (GestureDetector)
        │     → Opens: ProImageEditor (crop tab focused)
        │     → User can: free crop, rotate, flip
        │     → On save: updates _currentFile
        │     → Returns to: ImagePreviewScreen
        │
        ├── [ستيكر — Sticker button] (GestureDetector)
        │     → Calls: _convertToSticker()
        │     → Process:
        │         1. Reads image bytes
        │         2. Resizes to max 512px
        │         3. Applies rounded corners (32px radius)
        │         4. Saves as PNG (transparent corners)
        │         5. Calls: _sendImage(asSticker: true)
        │         6. Uploads to: Firebase Storage chats/{chatId}/stickers/
        │         7. Saves message: type=sticker, stickerUrl, stickerWidth, stickerHeight
        │     → Navigates back to: ChatScreen
        │
        └── [إرسال — Send button] (GestureDetector)
              → Calls: _sendImage(asSticker: false)
              → Same as AppBar send icon
              → Navigates back to: ChatScreen
```

---

## 📱 TAB: Me (ProfileScreen)
**File:** `lib/features/profile/view/screens/profile_screen.dart`
**Cubit:** `lib/features/profile/viewmodel/profile_cubit.dart`
**Also uses:** `lib/core/theme/theme_cubit.dart`

```
ProfileScreen
  │
  ├── [User info card] (Container)
  │     │
  │     ├── [Avatar] (CircleAvatar)
  │     │     → TODO: tap to change photo
  │     │
  │     ├── [Display name] (Text)
  │     │     → Shows: user.name
  │     │
  │     ├── [Phone] (Text)
  │     │     → Shows: user.phone
  │     │
  │     └── [Edit icon ✏️] (Icon)
  │           → TODO: navigate to edit profile
  │           → File: lib/features/profile/view/screens/edit_profile_screen.dart
  │
  ├── [Appearance section]
  │     └── [Theme options] (BlocBuilder<ThemeCubit>)
  │           │
  │           ├── [حسب الجهاز — System] (ListTile)
  │           │     → Calls: ThemeCubit.setSystem()
  │           │     → Saves: SharedPrefs 'sawa_theme_mode' = 'system'
  │           │     → Emits: ThemeMode.system
  │           │     → App: follows device theme immediately
  │           │
  │           ├── [الوضع الليلي — Dark] (ListTile)
  │           │     → Calls: ThemeCubit.setDark()
  │           │     → Saves: SharedPrefs 'sawa_theme_mode' = 'dark'
  │           │     → Emits: ThemeMode.dark
  │           │     → App: switches to dark theme immediately
  │           │
  │           └── [الوضع النهاري — Light] (ListTile)
  │                 → Calls: ThemeCubit.setLight()
  │                 → Saves: SharedPrefs 'sawa_theme_mode' = 'light'
  │                 → Emits: ThemeMode.light
  │                 → App: switches to light theme immediately
  │
  ├── [QR Code section]
  │     └── [رمز QR الخاص بي] (ListTile)
  │           → Navigates to: /home/qr (extra: userId)
  │           → File: lib/features/profile/view/screens/qr_screen.dart
  │
  └── [تسجيل الخروج — Sign out] (ListTile)
        → Calls: AuthCubit.signOut()
        → Firebase: signOut()
        → Emits: AuthState.unauthenticated()
        → Navigates to: /auth/phone (go_router redirect)
        → File: lib/features/auth/view/screens/phone_screen.dart
```

---

## 📱 SCREEN: QrScreen
**File:** `lib/features/profile/view/screens/qr_screen.dart`

```
QrScreen (StatefulWidget) — 2 tabs
  │
  ├── [AppBar — "رمز QR"]
  │     └── [Back arrow] → back to ProfileScreen
  │
  ├── [Tab 0: My QR — "رمز QR الخاص بي"]
  │     │
  │     └── [QrImageView] (qr_flutter)
  │           → Encodes: 'sawa://user/{userId}'
  │           → QR eye color: #5B4FD4 (purple)
  │           → Background: white card
  │           → No interaction (display only, for others to scan)
  │
  └── [Tab 1: Scan — "مسح"]
        │
        ├── [MobileScanner] (camera viewfinder)
        │     → Scans QR codes continuously
        │     → On QR detected:
        │         IF starts with 'sawa://user/':
        │           → Extracts: userId
        │           → Calls: ChatRemoteSource.createOrGetChat(currentId, scannedId)
        │           → Navigates to: /home/chat/:chatId
        │           → File: lib/features/chat/view/screens/chat_screen.dart
        │
        └── [Scan frame overlay] (Container)
              → Purple border rectangle in center
              → Visual guide only, no interaction
```

---

## 📱 SCREEN: OutgoingCallScreen
**File:** `lib/features/call/view/screens/outgoing_call_screen.dart`
**Cubit:** `lib/features/call/viewmodel/call_cubit.dart`

```
OutgoingCallScreen
  │
  ├── [Contact avatar + name] (display)
  │     → Large avatar, contact name, "Calling..." text
  │
  ├── [Animated pulse rings] (Lottie or custom animation)
  │     → Visual "ringing" indicator
  │
  └── [Cancel button 🔴] (GestureDetector)
        → Calls: CallCubit.endCall()
        → Emits: CallState.ended()
        → Socket.IO: emits end-call event to server
        → Saves: CallModel to Firestore (status: missed)
        → Navigates back to: ChatScreen
```

---

## 📱 SCREEN: IncomingCallScreen
**File:** `lib/features/call/view/screens/incoming_call_screen.dart`
**Triggered by:** FCM push notification or Socket.IO incoming-call event

```
IncomingCallScreen
  │
  ├── [Caller avatar + name + "Incoming call"] (display)
  │
  ├── [Accept button 🟢] (GestureDetector)
  │     → Calls: CallCubit.acceptCall()
  │     → Socket.IO: emits answer event
  │     → WebRTC: createAnswer(), setRemoteDescription()
  │     → Navigates to: /home/call (replaces IncomingCallScreen)
  │     → File: lib/features/call/view/screens/active_call_screen.dart
  │
  └── [Decline button 🔴] (GestureDetector)
        → Calls: CallCubit.declineCall()
        → Socket.IO: emits end-call event
        → Saves: CallModel (status: missed)
        → Navigates back to: previous screen (ChatScreen or HomeScreen)
```

---

## 📱 SCREEN: ActiveCallScreen
**File:** `lib/features/call/view/screens/active_call_screen.dart`
**Cubit:** `lib/features/call/viewmodel/call_cubit.dart`

```
ActiveCallScreen
  │
  ├── [Full-screen remote video] (RTCVideoView) — video calls only
  │     → Fills screen
  │     → No interaction
  │
  ├── [Local video preview] (RTCVideoView) — video calls only
  │     → Small corner window (bottom right)
  │     → Draggable (TODO)
  │
  ├── [Call timer] (Text)
  │     → Shows: 00:00 counting up
  │     → No interaction
  │
  ├── [Mute button 🎙️] (GestureDetector)
  │     → Calls: WebRTCService.toggleMute()
  │     → Toggles: local audio track enabled/disabled
  │     → Icon changes: mic_on ↔ mic_off
  │
  ├── [Speaker button 🔊] (GestureDetector)
  │     → Calls: WebRTCService.toggleSpeaker()
  │     → Toggles: earpiece ↔ speaker
  │     → Icon changes: speaker ↔ phone
  │
  ├── [Camera toggle 📷] — video calls only (GestureDetector)
  │     → Calls: WebRTCService.toggleVideo()
  │     → Toggles: local video track enabled/disabled
  │     → Icon changes: videocam ↔ videocam_off
  │
  ├── [Flip camera 🔄] — video calls only (GestureDetector)
  │     → Calls: WebRTCService.switchCamera()
  │     → Switches: front ↔ back camera
  │
  └── [End call button 🔴] (GestureDetector)
        → Calls: CallCubit.endCall()
        → WebRTC: closes peer connection
        → Socket.IO: emits end-call to other party
        → Saves: CallModel (status: ended, endTime, duration)
        → Adds: call_log message to chat
        → Navigates back to: ChatScreen
```

---

## 📱 TAB: Calls (_CallsTab)
**File:** `lib/features/chat/view/screens/home_screen.dart`

```
_CallsTab
  │
  ├── [AppBar — "المكالمات"]
  │
  └── [Call log list] (ListView) — TODO Phase 9
        └── [CallLogTile] — one per past call
              │
              ├── [Avatar + name] (display)
              ├── [Call type icon] — incoming green / outgoing purple / missed red
              ├── [Duration] (display)
              └── [Tap] → Navigates to: ChatScreen with that contact
```

---

## 📱 TAB: Contacts (_ContactsTab)
**File:** `lib/features/contacts/view/screens/contacts_screen.dart`
**Cubit:** `lib/features/contacts/viewmodel/contacts_cubit.dart`

```
ContactsScreen
  │
  ├── [AppBar — "جهات الاتصال"]
  │     └── [QR scan icon] (IconButton)
  │           → Navigates to: /home/qr
  │           → File: lib/features/profile/view/screens/qr_screen.dart
  │           → Opens directly on scanner tab
  │
  └── [Contacts ListView]
        └── [ContactTile] (ListTile)
              │
              ├── [Avatar] (display)
              ├── [Name or phone] (display)
              ├── [Online indicator dot] (display, teal if online)
              └── [Tap]
                    → Calls: ChatRemoteSource.createOrGetChat()
                    → Navigates to: /home/chat/:chatId
                    → File: lib/features/chat/view/screens/chat_screen.dart
```

---

## 🔔 PUSH NOTIFICATION ACTIONS

```
FCM Notification received (app killed / background)
  │
  ├── IF data.type == 'call'
  │     → Launches app
  │     → Navigates to: /home/incoming
  │     → File: lib/features/call/view/screens/incoming_call_screen.dart
  │     → Shows: Accept / Decline buttons
  │
  └── IF data.type == 'message'
        → Shows: notification banner (system)
        → On tap: opens app
        → Navigates to: /home/chat/:chatId
        → File: lib/features/chat/view/screens/chat_screen.dart
```

---

## 📂 COMPLETE FILE → SCREEN MAPPING

| File path | Screen/Widget |
|---|---|
| `lib/main.dart` | App entry point |
| `lib/app/app.dart` | MaterialApp.router wrapper |
| `lib/app/router/app_router.dart` | All route definitions |
| `lib/app/theme/app_colors.dart` | All color constants |
| `lib/app/theme/app_theme.dart` | sawaDarkTheme() + sawaLightTheme() |
| `lib/core/theme/theme_cubit.dart` | Theme toggle logic |
| `lib/core/di/injection.dart` | Dependency injection setup |
| `lib/core/network/dio_client.dart` | HTTP client setup |
| `lib/core/webrtc/webrtc_service.dart` | WebRTC peer connection |
| `lib/core/socket/signaling_service.dart` | Socket.IO events |
| `lib/core/utils/constants.dart` | Server URL, keys |
| `lib/features/splash/view/splash_screen.dart` | 🌟 Cold start screen |
| `lib/features/onboarding/view/onboarding_screen.dart` | 📖 First-time walkthrough |
| `lib/features/auth/view/screens/phone_screen.dart` | 📱 Phone number input |
| `lib/features/auth/view/screens/otp_screen.dart` | 🔐 OTP verification |
| `lib/features/auth/viewmodel/auth_cubit.dart` | Auth state management |
| `lib/features/auth/viewmodel/auth_state.dart` | Auth states (7 states) |
| `lib/features/auth/data/models/user_model.dart` | UserModel Freezed |
| `lib/features/auth/data/sources/auth_remote_source.dart` | Firebase Phone Auth |
| `lib/features/auth/data/sources/user_remote_source.dart` | Firestore user CRUD |
| `lib/features/auth/data/repositories/auth_repository.dart` | Auth business logic |
| `lib/features/chat/view/screens/home_screen.dart` | 🏠 Main 5-tab shell |
| `lib/features/chat/view/screens/chat_screen.dart` | 💬 Individual chat |
| `lib/features/chat/view/screens/new_chat_screen.dart` | ➕ Start new chat |
| `lib/features/chat/view/screens/image_preview_screen.dart` | 🖼️ Image edit before send |
| `lib/features/chat/view/widgets/message_bubble.dart` | 💭 Chat bubble widget |
| `lib/features/chat/view/widgets/chat_tile.dart` | 📋 Chat list item |
| `lib/features/chat/viewmodel/chat_cubit.dart` | Chat list state |
| `lib/features/chat/viewmodel/message_cubit.dart` | Message send/receive |
| `lib/features/chat/data/models/chat_model.dart` | ChatModel Freezed |
| `lib/features/chat/data/models/message_model.dart` | MessageModel Freezed |
| `lib/features/chat/data/sources/chat_remote_source.dart` | Firestore chat ops |
| `lib/features/chat/data/repositories/chat_repository.dart` | Chat business logic |
| `lib/features/call/view/screens/outgoing_call_screen.dart` | 📞 Calling... screen |
| `lib/features/call/view/screens/incoming_call_screen.dart` | 📲 Incoming call |
| `lib/features/call/view/screens/active_call_screen.dart` | 🔴 Live call controls |
| `lib/features/call/viewmodel/call_cubit.dart` | Call state management |
| `lib/features/call/data/models/call_model.dart` | CallModel Freezed |
| `lib/features/contacts/view/screens/contacts_screen.dart` | 👥 Contacts list |
| `lib/features/contacts/viewmodel/contacts_cubit.dart` | Contacts state |
| `lib/features/profile/view/screens/profile_screen.dart` | 👤 Me tab |
| `lib/features/profile/view/screens/qr_screen.dart` | 📷 QR show/scan |
| `signaling_server/server.js` | 🖥️ Node.js server entry |
| `signaling_server/src/handlers/callHandler.js` | WebRTC signal routing |
| `signaling_server/src/rooms/roomStore.js` | Active calls memory |
| `assets/animations/splash.json` | 🎬 Splash Lottie |
| `assets/animations/onboarding_chat.json` | 🎬 Onboarding page 1 |
| `assets/animations/onboarding_voice.json` | 🎬 Onboarding page 2 |
| `assets/animations/onboarding_video.json` | 🎬 Onboarding page 3 |
| `assets/icons/app_icon.png` | 🖼️ App icon (1024x1024) |

---

## 🔄 CUBIT STATES QUICK REFERENCE

### AuthState (auth_state.dart)
| State | When emitted | UI shows |
|---|---|---|
| initial() | App first opens | Splash screen |
| loading() | App startup auth check | Splash screen |
| sendingOtp() | OTP being sent to Firebase | PhoneScreen + local spinner |
| otpSent() | Firebase confirmed code sent | OtpScreen |
| authenticated(user) | Login successful | HomeScreen |
| unauthenticated() | Logged out or not logged in | PhoneScreen |
| error(message) | Any auth error | SnackBar with message |

### ChatState (chat_state.dart)
| State | When emitted | UI shows |
|---|---|---|
| initial() | Before loading | Nothing |
| loading() | Fetching chats | CircularProgressIndicator |
| loaded(chats) | Chats stream received | Chat list or empty state |
| error(message) | Firestore error | Red error text |

### MessageState (message_state.dart)
| State | When emitted | UI shows |
|---|---|---|
| initial() | Before loading | Nothing |
| loading() | Fetching messages | CircularProgressIndicator |
| loaded(messages) | Messages stream received | Message list |
| sending() | Message being sent | Loading on send button |
| error(message) | Send failed | SnackBar |

### CallState (call_state.dart)
| State | When emitted | UI shows |
|---|---|---|
| idle() | No active call | Nothing (chat screen normal) |
| outgoing(call) | User initiated call | OutgoingCallScreen |
| incoming(call) | Received call notification | IncomingCallScreen |
| connected(call) | Both parties in call | ActiveCallScreen |
| ended(call) | Call finished | Back to ChatScreen |
| missed(call) | Not answered | Call log in chat |

### ThemeMode (theme_cubit.dart)
| State | When set | Effect |
|---|---|---|
| ThemeMode.system | First install / user picks System | Follows device |
| ThemeMode.dark | User picks Dark | Dark theme always |
| ThemeMode.light | User picks Light | Light theme always |

---

*Sawa UI Interaction Map — April 2026*
*Update this file whenever a new screen or button is added*
