// lib/features/notes/bloc/note_form_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/notes_repository.dart';

class NoteFormState extends Equatable {
  final bool saving;
  final String? error;
  const NoteFormState({this.saving = false, this.error});

  NoteFormState copyWith({bool? saving, String? error}) =>
      NoteFormState(saving: saving ?? this.saving, error: error);

  @override
  List<Object?> get props => [saving, error];
}

class NoteFormCubit extends Cubit<NoteFormState> {
  NoteFormCubit(this.repo) : super(const NoteFormState());
  final NotesRepository repo;

  Future<void> save({
    String? id,
    required String title,
    required String content,
    String skin = 'plain',
  }) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      if (id == null) {
        await repo.add(title: title, content: content, skin: skin);
      } else {
        await repo.update(id: id, title: title, content: content, skin: skin);
      }
      emit(state.copyWith(saving: false));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}
