Connectinno Notes — Mobile (Flutter)

A Flutter notes app with Firebase Authentication, offline-first storage via Drift (SQLite), and background sync with a Flask backend. Includes multiple note themes and a placeholder AI action (“Coming soon”).

Features

Email/Password Firebase Auth (login/register/logout)

Offline-first: notes saved locally first (Drift), then push/pull sync to the API

Themes (skins): plain, yellow, pink, blue, purple, sepia, kraft

Notes list with search and sort (Newest / A→Z)

Connectivity toasts (No connection / Back online)

Logout clears local cache

AI button (currently shows “Coming soon” toast)

1) Requirements

Flutter SDK (3.x recommended)

Android Studio and/or Xcode (platform toolchains)

A Firebase project (Authentication enabled)

Running backend API (Flask) — see server README

You’ll need an emulator/simulator or a physical device.

2) Firebase Setup

Easiest: FlutterFire CLI

dart pub global activate flutterfire_cli
firebase login
flutterfire configure


Manual (summary):

Enable Email/Password in Firebase Console → Authentication → Sign-in method.

Download platform configs:

Android: put google-services.json in android/app/

iOS: put GoogleService-Info.plist in ios/Runner/

Ensure Firebase is initialized in your app (Firebase.initializeApp(); FlutterFire CLI scaffolds this).

3) Backend Base URL

During development, emulator networking differs:

Android Emulator → http://10.0.2.2:8000

iOS Simulator → http://127.0.0.1:8000

Real device → your machine’s LAN IP (e.g., http://192.168.1.50:8000)

Recommended lib/di.dart:

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode;

final String baseUrl = kReleaseMode
    ? 'https://<your-prod-host>'
    : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000');


Production: use HTTPS.

Android cleartext (dev only)

Allow HTTP for development in AndroidManifest.xml (<application>):

android:usesCleartextTraffic="true"

iOS ATS (dev only)

If you use HTTP locally, add a temporary exception in Info.plist:

<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key><true/>
</dict>

4) Dependencies (pubspec)

Key packages:

firebase_core, firebase_auth

flutter_bloc, equatable

go_router

http

connectivity_plus

drift, drift_dev, path_provider

flutter_staggered_grid_view

If you show an illustration on the login page, declare the asset:

flutter:
  assets:
    - assets/images/login_illustration.png

5) Drift (SQLite) Codegen

lib/data/local_db.dart uses part 'local_db.g.dart';.
Generate code:

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs


Schema version is 2 (adds kind and skin columns); migration is included.

6) Run the App

Start the backend (python main.py → :8000).

In Flutter:

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run


Register or log in, then create and manage notes.

7) Architecture (short)

Auth (LoginPage + AuthCubit)
Firebase email/password login/register. On success, navigate to /notes. Errors are mapped to friendly messages.

Notes List (NotesListPage)
Lists notes via Bloc, supports search & sort; shows connectivity toasts; logout dialog clears local cache and signs out.

Note Form (NoteFormPage)
Create/edit notes, choose theme. AI action currently shows a “🚀 AI features are coming soon!” toast.

Repository & API

NotesRepository: local-first; marks changes as isDirty, then debounced sync (push dirty changes, pull remote).

ApiClient: injects Authorization: Bearer <idToken> when logged in, and throws ApiException with user-friendly messages for network/HTTP errors.

Local DB (Drift)
NotesTable with id/title/content/kind/skin/createdAt/updatedAt/isDirty/isDeleted.

8) Error & UX Copy

Auth errors (examples):

Weak password → “Password must be at least 6 characters.”

Wrong password → “Wrong password. Please try again.”

User not found → “There’s no user with this email.”

Invalid email → “Please enter a valid email address.”

Generic → “Authentication failed. Please try again.”

Network/API:

No internet → “No internet connection. Please check your network.”

Timeout → “Request timed out. Please try again later.”

API 4xx/5xx → prefer server { "error": "..." }, otherwise show status text/body.

Connectivity toasts:

Went offline → “No connection — offline mode”

Back online → “Back online”

Logout flow:

Clear local Drift cache → FirebaseAuth.signOut() → navigate to /login.

9) Troubleshooting

Unauthorized / Invalid token: user not logged in or token expired. Log in again.

Android HTTP dev: ensure usesCleartextTraffic="true" (dev only).

iOS HTTP dev: ATS exception (dev only) or switch to HTTPS.

Cannot reach backend from device: use machine’s LAN IP; ensure firewall allows inbound connections.

Missing Drift part file: run build_runner (see section 5).

10) Folder Structure (excerpt)
lib/
├─ data/
│  ├─ api_client.dart
│  ├─ local_db.dart           # generates local_db.g.dart
│  └─ notes_repository.dart   # local-first + sync
├─ features/
│  └─ notes/
│     ├─ notes_list_page.dart
│     ├─ note_form_page.dart
│     └─ bloc/...
├─ ui/responsive/responsive.dart
├─ di.dart
└─ main.dart

11) License

MIT (or as required by your organization)
