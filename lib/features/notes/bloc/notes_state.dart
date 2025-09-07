import 'package:equatable/equatable.dart';
import '../../../data/local_db.dart';

class NotesState extends Equatable {
  final List<NotesTableData> items;
  final bool loading;
  final bool syncing;
  final bool online;

  final bool lastSyncFromConnectivity;

  const NotesState({
    required this.items,
    required this.loading,
    required this.syncing,
    required this.online,
    this.lastSyncFromConnectivity = false,
  });

  const NotesState.loading()
      : items = const [],
        loading = true,
        syncing = false,
        online = true,
        lastSyncFromConnectivity = false;

  NotesState copyWith({
    List<NotesTableData>? items,
    bool? loading,
    bool? syncing,
    bool? online,
    bool? lastSyncFromConnectivity,
  }) {
    return NotesState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      online: online ?? this.online,
      lastSyncFromConnectivity:
      lastSyncFromConnectivity ?? this.lastSyncFromConnectivity,
    );
  }

  @override
  List<Object?> get props => [items, loading, syncing, online, lastSyncFromConnectivity];
}
