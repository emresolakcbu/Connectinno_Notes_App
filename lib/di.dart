// lib/di.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;

import 'data/local_db.dart';
import 'data/api_client.dart';
import 'data/notes_repository.dart';

final AppDb db = AppDb();

String _detectBaseUrl() {
  // Prod
  if (kReleaseMode) return 'https://api.domainin.com';

  // Dev
  if (kIsWeb) return 'http://localhost:8000';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    // Android Emulator → host bilgisayara erişim
      return 'http://10.0.2.2:8000';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return 'http://localhost:8000';
    default:
      return 'http://localhost:8000';
  }
}

final String baseUrl = _detectBaseUrl();

final ApiClient api = ApiClient(
  baseUrl: baseUrl,
  auth: FirebaseAuth.instance,
);

final NotesRepository repo = NotesRepository(
  db,
  api,
  FirebaseAuth.instance,
);
