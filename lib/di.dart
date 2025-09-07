// lib/di.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'data/local_db.dart';
import 'data/api_client.dart';
import 'data/notes_repository.dart';

final AppDb db = AppDb();

const String _devAndroidEmu = 'http://10.0.2.2:8000';
const String _devLanOverWifi = 'http://192.168.1.34:8000';
const String _devLocalhost   = 'http://localhost:8000';

String _detectBaseUrl() {
  // >>> TEMP: Force DEV for all builds (even release)
  if (kIsWeb) return _devLocalhost;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return _devAndroidEmu;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return _devLocalhost;
    default:
      return _devLocalhost;
  }
}

final String baseUrl = _detectBaseUrl();

final ApiClient api = ApiClient(
  baseUrl: baseUrl,
  auth: FirebaseAuth.instance,
);

final NotesRepository repo = NotesRepository(db, api, FirebaseAuth.instance);
