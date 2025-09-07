import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../di.dart';
import '../../ui/responsive/responsive.dart';
import 'bloc/notes_bloc.dart';
import 'bloc/notes_event.dart';
import 'bloc/notes_state.dart';
import '../../data/local_db.dart';

enum SortMode { recent, az }

class NotesListPage extends StatelessWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: BlocProvider(create: (_) => NotesBloc(repo)..add(const NotesStarted()), child: const _NotesScaffold()),
    );
  }
}

class _NotesScaffold extends StatefulWidget {
  const _NotesScaffold();

  @override
  State<_NotesScaffold> createState() => _NotesScaffoldState();
}

class _NotesScaffoldState extends State<_NotesScaffold> with SingleTickerProviderStateMixin {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late final AnimationController _spinCtrl;
  SortMode _sort = SortMode.recent;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _spinCtrl.repeat();
  }

  @override
  void dispose() {
    _spinCtrl.stop();
    _spinCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be logged out of your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) {
      try {
        // 1) Clear local cache
        await repo.clearLocalCache();
      } catch (e) {
        // optional: log
        debugPrint('Error while clearing cache: $e');
      }

      // 2) Firebase logout
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      // 3) Redirect to login page
      context.go('/login'); // adjust route if needed

      // 4) Info toast
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out successfully'), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context) || Responsive.isDesktop(context);
    final crossAxisCount = isTablet ? 2 : 2;
    final padding = const EdgeInsets.symmetric(horizontal: 16);

    return BlocListener<NotesBloc, NotesState>(
      listenWhen: (prev, curr) => prev.online != curr.online,
      listener: (context, state) {
        final msg = state.online ? 'Tekrar online' : 'Bağlantı yok — offline mod';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
      },
      child: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          final q = _searchCtrl.text.trim().toLowerCase();
          final items = _applyQuerySort(state.items, q);

          return Scaffold(
            body: SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: () async {
                    context.read<NotesBloc>().add(const NotesSyncRequested());
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: CustomScrollView(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        elevation: 0,
                        toolbarHeight: 66,
                        titleSpacing: 8,
                        title: Row(
                          children: [
                            Icon(Icons.folder_rounded, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Notes', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            if (state.syncing)
                              RotationTransition(turns: _spinCtrl, child: const Icon(Icons.sync))
                            else if (!state.online)
                              const Icon(Icons.cloud_off, color: Colors.amber),
                            const SizedBox(width: 8),
                            PopupMenuButton<SortMode>(
                              initialValue: _sort,
                              onSelected: (v) => setState(() => _sort = v),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: SortMode.recent, child: Text('Sort: Newest')),
                                PopupMenuItem(value: SortMode.az, child: Text('Sort: A → Z')),
                              ],
                              tooltip: 'Sort',
                              icon: const Icon(Icons.sort_rounded),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Log out',
                              icon: const Icon(Icons.logout_rounded),
                              onPressed: _confirmLogout,
                            ),
                          ],
                        ),
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(60),
                          child: Padding(
                            padding: padding.copyWith(bottom: 12),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Search notes…',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (state.loading)
                        const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                      else if (items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.note_add_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No notes yet', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: padding.copyWith(top: 8, bottom: 96),
                          sliver: SliverMasonryGrid.count(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childCount: items.length,
                            itemBuilder: (_, i) {
                              final n = items[i];
                              return _NoteCardV2(
                                note: n,
                                onTap: () => context
                                    .push(
                                      '/note-form',
                                      extra: {
                                        'id': n.id,
                                        'title': n.title,
                                        'content': n.content,
                                        'skin': ((n as dynamic).skin as String?) ?? 'plain',
                                      },
                                    )
                                    .then((changed) {
                                      if (changed == true && context.mounted) {
                                        context.read<NotesBloc>().add(const NotesSyncRequested());
                                      }
                                    }),
                                onDelete: () => _confirmDelete(context, n.id),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: _AddFab(
              onPressed: () {
                context.push('/note-form').then((changed) {
                  if (changed == true && context.mounted) {
                    context.read<NotesBloc>().add(const NotesSyncRequested());
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        context.read<NotesBloc>().add(NotesDeleted(id));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete note: $e')));
      }
    }
  }

  List<NotesTableData> _applyQuerySort(List<NotesTableData> items, String query) {
    var list = query.isEmpty
        ? List<NotesTableData>.from(items)
        : items.where((n) => n.title.toLowerCase().contains(query) || n.content.toLowerCase().contains(query)).toList();

    if (_sort == SortMode.az) {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('New Note'),
    );
  }
}

class _NoteCardV2 extends StatelessWidget {
  const _NoteCardV2({required this.note, required this.onTap, required this.onDelete});

  final NotesTableData note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preview = note.content.trim();
    final lines = (preview.isEmpty ? note.title : preview).split('\n');
    final approx = lines.take(6).join('\n');

    return Card(
      clipBehavior: Clip.antiAlias,
      color: _skinColorOf(note, context),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    note.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Text(approx, maxLines: 8, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${note.updatedAt.toLocal()}'.split('.')[0],
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () async {
                      final res = await showModalBottomSheet<int>(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit_outlined),
                                title: const Text('Edit'),
                                onTap: () => Navigator.pop(context, 1),
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete_outline),
                                title: const Text('Delete'),
                                onTap: () => Navigator.pop(context, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (res == 1) onTap();
                      if (res == 2) onDelete();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _skinColorOf(NotesTableData n, BuildContext context) {
  final s = ((n as dynamic).skin as String?) ?? 'plain';
  switch (s) {
    case 'yellow':
      return const Color(0xFFFFF9C4); // Sarı
    case 'pink':
      return const Color(0xFFFFE4EC); // Pembe
    case 'blue':
      return const Color(0xFFE3F2FD); // Mavi
    case 'purple':
      return const Color(0xFFEDE7F6); // Mor
    case 'sepia':
      return const Color(0xFFF4EAD5); // Sepya
    case 'kraft':
      return const Color(0xFFE6D7B6); // Kraft
    case 'plain':
    default:
      return Theme.of(context).cardColor;
  }
}
