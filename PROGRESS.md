# Progress Update

## Completed This Session
- Implemented Phase 6a core navigation migration to `go_router`.
- Added `lib/app/app.dart` and moved app bootstrapping to `MaterialApp.router`.
- Added `lib/app/router/app_router.dart` with:
  - central route paths,
  - auth redirect guard,
  - `GoRouterRefreshStream` to react to auth state updates.
- Replaced remaining `Navigator` usage with `go_router` API:
  - `PhoneScreen`: navigate to OTP with `context.push(...)`, close picker with `context.pop()`.
  - `OtpScreen`: route to home on authenticated state via `context.go(...)`.
  - `HomeScreen`: open New Chat with `context.push(...)`.
  - `NewChatScreen`: close with `context.pop(...)`.
- Added a `mounted` check in `NewChatScreen` before `setState` after async fetch.

## Errors Encountered and Fixes
- `dart format` could not run in this environment due to Flutter SDK cache write restrictions outside the workspace.
  - Fix/workaround: proceeded with direct code edits and validated structure with lint diagnostics in-workspace.

## Current App State
- Works:
  - App startup now uses declarative routing.
  - Auth guard redirects unauthenticated users to phone auth.
  - Authenticated users are redirected away from auth routes to home.
  - Core in-app navigation no longer depends on `Navigator.push/pop`.
- Not done yet:
  - Splash route and onboarding route screens/wiring are not implemented yet.
  - EasyLoading migration, splash Lottie UX, icon generation, and onboarding persistence are still pending.
  - Message/chat details route wiring is pending until `ChatScreen` is implemented.

## Exact Start Point for Next Session
1. Implement Phase 6b (`flutter_easyloading`) in app builder and auth screens.
2. Implement Phase 6c splash flow:
   - add `SplashScreen`,
   - route from splash to onboarding/home based on first-launch + auth.
3. Implement Phase 6e onboarding:
   - create onboarding UI,
   - persist flag in `SharedPreferences`,
   - route guard updates to respect onboarding completion.

## Pending Decisions / Issues
- Decide whether to keep route-state-based user lookup from `AuthCubit` in `/home` builder or pass richer user data via app-level state injection.
- Decide route naming strategy (string constants only vs named routes) before route count grows.
