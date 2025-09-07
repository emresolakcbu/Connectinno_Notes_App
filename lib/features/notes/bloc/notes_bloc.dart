import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/local_db.dart';
import '../../../data/notes_repository.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc(this.repo) : super(const NotesState.loading()) {
    on<NotesStarted>(_onStarted);
    on<NotesSyncRequested>(_onSync);
    on<NotesDeleted>(_onDelete);
    on<NotesConnectivityChanged>(_onConnectivityChanged);
  }

  final NotesRepository repo;
  StreamSubscription<List<ConnectivityResult>>? _net;

  Future<void> _onStarted(NotesStarted event, Emitter<NotesState> emit) async {
    await repo.sync();

    final initial = await Connectivity().checkConnectivity();
    final initialOnline = initial.any((r) => r != ConnectivityResult.none);
    emit(state.copyWith(online: initialOnline));

    _net = Connectivity().onConnectivityChanged.listen((results) {
      final hasConn = results.any((r) => r != ConnectivityResult.none);
      add(NotesConnectivityChanged(hasConn));
      if (hasConn) {
        add(const NotesSyncRequested(fromConnectivity: true));
      }
    });

    await emit.forEach<List<NotesTableData>>(
      repo.watchNotes(),
      onData: (rows) => state.copyWith(items: rows, loading: false),
    );
  }

  Future<void> _onConnectivityChanged(
      NotesConnectivityChanged event, Emitter<NotesState> emit) async {
    emit(state.copyWith(online: event.online));
  }

  Future<void> _onSync(NotesSyncRequested event, Emitter<NotesState> emit) async {
    try {
      if (!event.silent) {
        emit(state.copyWith(syncing: true));
      }
      await repo.sync();
    } finally {
      emit(state.copyWith(
        syncing: false,
        lastSyncFromConnectivity: event.fromConnectivity,
      ));
    }
  }

  Future<void> _onDelete(NotesDeleted event, Emitter<NotesState> emit) async {
    await repo.delete(event.id);
  }

  @override
  Future<void> close() async {
    await _net?.cancel();
    return super.close();
  }
}
