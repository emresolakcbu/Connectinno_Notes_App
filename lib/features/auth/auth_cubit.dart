import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState extends Equatable {
  final bool loading;
  final String? error;
  const AuthState({this.loading = false, this.error});

  AuthState copyWith({bool? loading, String? error}) =>
      AuthState(loading: loading ?? this.loading, error: error);

  @override
  List<Object?> get props => [loading, error];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._auth) : super(const AuthState());
  final FirebaseAuth _auth;

  String _mapError(FirebaseAuthException e) {
    debugPrint("🔥 FirebaseAuthException: code=${e.code}, message=${e.message}");

    switch (e.code) {
      case 'invalid-email':
        return "The email address is not valid.";
      case 'user-disabled':
        return "This account has been disabled.";
      case 'user-not-found':
        return "No account found with this email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'invalid-credential':
        return "Invalid credentials. Please check your email or password.";
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'weak-password':
        return "Password should be at least 6 characters.";
      case 'network-request-failed':
        return "Network error. Please check your internet connection.";
      case 'too-many-requests':
        return "Too many attempts. Try again later.";
      default:
        return "Authentication failed [${e.code}]. Please try again.";
    }
  }

  Future<void> login(String email, String pass) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: pass);
      emit(state.copyWith(loading: false));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(loading: false, error: _mapError(e)));
    } catch (_) {
      emit(state.copyWith(loading: false, error: "Unexpected error occurred."));
    }
  }

  Future<void> register(String email, String pass) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: pass);
      emit(state.copyWith(loading: false));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(loading: false, error: _mapError(e)));
    } catch (_) {
      emit(state.copyWith(loading: false, error: "Unexpected error occurred."));
    }
  }

  Future<void> logout() async => _auth.signOut();
}
