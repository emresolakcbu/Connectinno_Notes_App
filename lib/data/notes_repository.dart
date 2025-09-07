import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_db.dart';
import 'api_client.dart';

class NotesRepository {
  final AppDb db;
  final ApiClient api;
  final FirebaseAuth auth;

  NotesRepository(this.db, this.api, this.auth);

  Future<void> clearLocalCache() => db.clearAll();
  Stream<List<NotesTableData>> watchNotes() => db.watchAllNotes();

  // --- Helpers ---
  Future<NotesTableData?> _read(String id) async {
    final rows =
    await (db.select(db.notesTable)..where((t) => t.id.equals(id))).get();
    return rows.isEmpty ? null : rows.first;
  }

  bool _isTempId(String id) => id.startsWith('tmp_');
  String _tmpId() => 'tmp_${DateTime.now().microsecondsSinceEpoch}';

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    return null;
  }

  // --- CRUD (local-first, dirty) ---

  Future<void> add({
    required String title,
    required String content,
    String skin = 'plain',
  }) async {
    final now = DateTime.now().toUtc();
    final tempId = _tmpId();
    final note = NotesTableData(
      id: tempId,
      title: title,
      content: content,
      kind: 'text', // tek tür
      skin: skin,
      createdAt: now,
      updatedAt: now,
      isDirty: true,
      isDeleted: false,
    );
    await db.upsertNote(note);
    _scheduleSync();
  }

  Future<void> update({
    required String id,
    required String title,
    required String content,
    String skin = 'plain',
  }) async {
    final existing = await _read(id);
    final now = DateTime.now().toUtc();
    final note = NotesTableData(
      id: id,
      title: title,
      content: content,
      kind: 'text',
      skin: skin,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      isDirty: true,
      isDeleted: false,
    );
    await db.upsertNote(note);
    _scheduleSync();
  }

  Future<void> delete(String id) async {
    await db.markDeleted(id);
    _scheduleSync();
  }

  // --- Sync orchestration ---
  bool _syncing = false;
  Timer? _debounce;

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      sync();
    });
  }

  // --- Sync ---
  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      // PUSH
      final dirty = await db.getDirty();
      for (final n in dirty) {
        try {
          if (n.isDeleted) {
            await api.deleteNote(n.id);
            await db.remove(n.id);
            continue;
          }

          if (_isTempId(n.id)) {
            // CREATE
            final created = await api.createNote(
              title: n.title,
              content: n.content,
              kind: 'text',
              skin: n.skin,
            );
            final serverId =
            (created['id'] ?? created['_id'] ?? created['Id']).toString();

            final createdAt = _parseDate(created['created_at']) ?? n.createdAt;
            final updatedAt = _parseDate(created['updated_at']) ?? n.updatedAt;

            await db.remove(n.id);
            await db.upsertNote(n.copyWith(
              id: serverId,
              createdAt: createdAt,
              updatedAt: updatedAt,
              isDirty: false,
              isDeleted: false,
            ));
          } else {
            // UPDATE
            final updated = await api.updateNote(
              id: n.id,
              title: n.title,
              content: n.content,
              kind: 'text',
              skin: n.skin,
            );

            final updatedAt = _parseDate(updated['updated_at']);

            await db.upsertNote(n.copyWith(
              isDirty: false,
              updatedAt: updatedAt ?? DateTime.now().toUtc(),
            ));
          }
        } catch (_) {
        }
      }

      // PULL
      try {
        final remote = await api.getNotes();
        for (final r in remote) {
          final id = (r['id'] ?? r['_id'] ?? r['Id']).toString();
          final title = (r['title'] ?? '').toString();
          final content = (r['content'] ?? '').toString();
          final skin = (r['skin'] ?? 'plain').toString();
          final createdAt =
              _parseDate(r['created_at']) ?? DateTime.now().toUtc();
          final updatedAt =
              _parseDate(r['updated_at']) ?? DateTime.now().toUtc();

          final local = await _read(id);

          final localIsNewer = local != null &&
              local.isDirty &&
              local.updatedAt.isAfter(updatedAt);

          if (localIsNewer) continue;

          await db.upsertNote(
            NotesTableData(
              id: id,
              title: title,
              content: content,
              kind: 'text',
              skin: skin,
              createdAt: local?.createdAt ?? createdAt,
              updatedAt: updatedAt,
              isDirty: false,
              isDeleted: false,
            ),
          );
        }
      } catch (_) {}
    } finally {
      _syncing = false;
    }
  }

  // NotesRepository

  Future<String?> aiSuggestTitle({required String content}) async {
    if (content.isEmpty) return null;
    final rsp = await api.aiSuggestTitle(content: content);
    return (rsp['title'] as String?)?.trim();
  }

  Future<String?> aiSummarize({required String content}) async {
    if (content.isEmpty) return null;
    final rsp = await api.aiSummarize(content: content);
    return (rsp['summary'] as String?)?.trim();
  }

  Future<List<String>> aiSuggestTags({required String content}) async {
    if (content.isEmpty) return const [];
    final rsp = await api.aiSuggestTags(content: content);
    final raw = rsp['tags'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).cast<String>().toList();
    }
    if (raw is String) {
      return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }
}
