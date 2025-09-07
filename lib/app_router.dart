import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/login_page.dart';
import 'features/notes/notes_list_page.dart';
import 'features/notes/note_form_page.dart';

final _auth = FirebaseAuth.instance;

final appRouter = GoRouter(
  initialLocation: _auth.currentUser == null ? '/login' : '/notes',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/notes', builder: (_, __) => const NotesListPage()),
    GoRoute(
      path: '/note-form',
      builder: (context, state) {
        final note = state.extra as Map<String, dynamic>?;
        return NoteFormPage(note: note);
      },
    ),
  ],
);
