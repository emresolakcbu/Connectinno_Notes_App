import 'package:equatable/equatable.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class NotesStarted extends NotesEvent {
  const NotesStarted();
}

class NotesSyncRequested extends NotesEvent {
  const NotesSyncRequested({this.silent = false, this.fromConnectivity = false});
  final bool silent;
  final bool fromConnectivity;
  @override
  List<Object?> get props => [silent, fromConnectivity];
}

class NotesDeleted extends NotesEvent {
  const NotesDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class NotesConnectivityChanged extends NotesEvent {
  const NotesConnectivityChanged(this.online);
  final bool online;
  @override
  List<Object?> get props => [online];
}
