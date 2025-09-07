import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di.dart';
import '../../ui/responsive/responsive.dart';
import 'bloc/note_form_cubit.dart';

enum NoteSkin { plain, yellow, pink, blue, purple, sepia, kraft }

String noteSkinToString(NoteSkin s) => switch (s) {
  NoteSkin.plain => 'plain',
  NoteSkin.yellow => 'yellow',
  NoteSkin.pink => 'pink',
  NoteSkin.blue => 'blue',
  NoteSkin.purple => 'purple',
  NoteSkin.sepia => 'sepia',
  NoteSkin.kraft => 'kraft',
};

NoteSkin noteSkinFromString(String? s) {
  switch ((s ?? 'plain').toLowerCase()) {
    case 'yellow':
      return NoteSkin.yellow;
    case 'pink':
      return NoteSkin.pink;
    case 'blue':
      return NoteSkin.blue;
    case 'purple':
      return NoteSkin.purple;
    case 'sepia':
      return NoteSkin.sepia;
    case 'kraft':
      return NoteSkin.kraft;
    default:
      return NoteSkin.plain;
  }
}

class NoteFormPage extends StatefulWidget {
  const NoteFormPage({super.key, this.note});

  final Map<String, dynamic>? note;

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  bool get isEdit => widget.note != null;
  late NoteSkin skin;

  bool online = true;
  StreamSubscription<List<ConnectivityResult>>? _net;

  late final NoteFormCubit _cubit;
  bool _submitted = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;


  Future<void> _initConnectivity() async {
    final initial = await Connectivity().checkConnectivity();
    final hasConn = initial.any((r) => r != ConnectivityResult.none);

    if (mounted) {
      setState(() {
        online = hasConn;
      });
    }

    _net = Connectivity().onConnectivityChanged.listen((results) {
      final has = results.any((r) => r != ConnectivityResult.none);
      if (!mounted) return;

      final was = online;
      setState(() => online = has);

      if (was && !has) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No connection — offline mode'), behavior: SnackBarBehavior.floating),
        );
      } else if (!was && has) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Back online'), behavior: SnackBarBehavior.floating));
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _cubit = NoteFormCubit(repo);

    _titleCtrl = TextEditingController(text: widget.note?['title'] ?? '');
    _contentCtrl = TextEditingController(text: widget.note?['content'] ?? '');

    skin = noteSkinFromString((widget.note?['skin'] ?? widget.note?['theme'])?.toString());

    _initConnectivity();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _net?.cancel();
    _cubit.close();
    super.dispose();
  }

  // Tema bazlı metin rengi (dark skin için)
  Color _editorTextColor(NoteSkin s, ThemeData theme) {
    return theme.textTheme.bodyLarge?.color ?? Colors.black87;
  }

  Future<void> _openAiSheet(BuildContext ctx) async {
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text('🚀 AI features are coming soon!'), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final textScaler = MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: BlocProvider.value(
        value: _cubit,
        child: BlocConsumer<NoteFormCubit, NoteFormState>(
          listener: (context, state) {
            if (_submitted && !state.saving && state.error == null) {
              _submitted = false;
              Navigator.of(context).pop(true);
            }
            if (state.error != null) {
              _submitted = false;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            final maxW = Responsive.maxContentWidth(context);

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                titleSpacing: 8,
                title: Row(
                  children: [
                    Text(isEdit ? 'Note' : 'New Note'),
                    if (!online)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Tooltip(
                          message: 'Offline',
                          child: Icon(Icons.cloud_off, color: Colors.amber),
                        ),
                      ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'AI',
                    icon: const Icon(Icons.auto_awesome), // or Icons.magic_button
                    onPressed: state.saving ? null : () => _openAiSheet(context),
                  ),

                  IconButton(
                    tooltip: 'Change Theme',
                    icon: const Icon(Icons.color_lens_outlined),
                    onPressed: state.saving ? null : () => _pickSkinBottomSheet(context),
                  ),
                ],
              ),
              floatingActionButton: _FabBar(
                saving: state.saving,
                online: online,
                onSave: state.saving
                    ? null
                    : () {
                        final title = _titleCtrl.text.trim();
                        final content = _contentCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
                          return;
                        }
                        _submitted = true;
                        _cubit.save(
                          id: isEdit ? widget.note!['id'] as String : null,
                          title: title,
                          content: content,
                          skin: noteSkinToString(skin),
                        );
                      },

                onCancel: state.saving ? null : () => Navigator.pop(context, false),
              ),
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(color: t.scaffoldBackgroundColor),
                child: SafeArea(
                  child: GestureDetector(
                    // ← EKLE
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
                          child: state.saving
                              ? const Center(child: CircularProgressIndicator())
                              : _FullPageEditor(
                                  titleCtrl: _titleCtrl,
                                  contentCtrl: _contentCtrl,
                                  textColor: _editorTextColor(skin, t),
                                  skin: skin,
                                  theme: t,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickSkinBottomSheet(BuildContext context) async {
    final res = await showModalBottomSheet<NoteSkin>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Theme', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              _skinTile(NoteSkin.plain, 'Plain'),
              _skinTile(NoteSkin.yellow, 'Yellow'),
              _skinTile(NoteSkin.pink, 'Pink'),
              _skinTile(NoteSkin.blue, 'Blue'),
              _skinTile(NoteSkin.purple, 'Purple'),
              _skinTile(NoteSkin.sepia, 'Sepia'),
              _skinTile(NoteSkin.kraft, 'Kraft'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (res != null && mounted) setState(() => skin = res);
  }

  Widget _skinTile(NoteSkin s, String label) {
    final selected = skin == s;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      onTap: () => Navigator.pop(context, s),
    );
  }
}

class _FullPageEditor extends StatelessWidget {
  const _FullPageEditor({
    required this.titleCtrl,
    required this.contentCtrl,
    required this.textColor,
    required this.skin,
    required this.theme,
  });

  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final Color textColor;
  final NoteSkin skin;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: titleCtrl,
          style: t.textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700, height: 1.25),
          decoration: _fieldDecoration(skin: skin, theme: t, isTitle: true),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: contentCtrl,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            style: t.textTheme.bodyLarge?.copyWith(color: textColor, height: 1.4, fontSize: 16),
            decoration: _fieldDecoration(skin: skin, theme: t, isTitle: false),
          ),
        ),
      ],
    );
  }
}

class _FabBar extends StatelessWidget {
  const _FabBar({required this.saving, required this.online, required this.onSave, required this.onCancel});

  final bool saving;
  final bool online;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        FloatingActionButton.extended(
          heroTag: 'cancel',
          onPressed: onCancel,
          label: const Text('Cancel'),
          icon: const Icon(Icons.close),
          foregroundColor: Colors.black87,
          backgroundColor: Colors.white,
        ),
        FloatingActionButton.extended(
          heroTag: 'save',
          onPressed: onSave,
          label: Text(online ? 'Save' : 'Save (offline)'),
          icon: saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration({required NoteSkin skin, required ThemeData theme, required bool isTitle}) {
  final Color fill = switch (skin) {
    NoteSkin.plain => (theme.brightness == Brightness.dark ? Colors.grey[850]! : Colors.white),
    NoteSkin.yellow => const Color(0xFFFFFDE7),
    NoteSkin.pink => const Color(0xFFFFF1F5),
    NoteSkin.blue => const Color(0xFFEFF6FF),
    NoteSkin.purple => const Color(0xFFF3E8FF),
    NoteSkin.sepia => const Color(0xFFF7EEDD),
    NoteSkin.kraft => const Color(0xFFF1E4C7),
  };

  final hintColor = (theme.brightness == Brightness.dark) ? Colors.white60 : Colors.black45;

  final base = theme.inputDecorationTheme;
  return InputDecoration()
      .applyDefaults(base)
      .copyWith(
        filled: true,
        fillColor: fill,
        hintText: isTitle ? 'Title' : 'Content',
        hintStyle: TextStyle(
          fontSize: isTitle ? 18 : 16,
          fontWeight: isTitle ? FontWeight.w600 : FontWeight.normal,
          color: hintColor,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isTitle ? 12 : 10),
      );
}
