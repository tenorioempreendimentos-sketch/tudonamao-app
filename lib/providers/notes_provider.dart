import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  static const _boxName = 'notes';
  Box<Note>? _box;

  List<Note> get notes {
    if (_box == null) return [];
    final all = _box!.values.toList();
    // Fixadas primeiro, depois por data de atualização
    all.sort((a, b) {
      if (a.fixada && !b.fixada) return -1;
      if (!a.fixada && b.fixada) return 1;
      return b.atualizadoEm.compareTo(a.atualizadoEm);
    });
    return all;
  }

  Future<void> init() async {
    // Adapter já registrado no main() — não registrar de novo
    _box = await Hive.openBox<Note>(_boxName);
    notifyListeners();
  }

  Future<void> adicionarNota({
    required String titulo,
    required String conteudo,
    String cor = '#1E3A5F',
  }) async {
    final note = Note(
      id: const Uuid().v4(),
      titulo: titulo.trim(),
      conteudo: conteudo.trim(),
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
      cor: cor,
    );
    await _box!.put(note.id, note);
    notifyListeners();
  }

  Future<void> editarNota(Note note,
      {String? titulo, String? conteudo, String? cor}) async {
    if (titulo != null) note.titulo = titulo.trim();
    if (conteudo != null) note.conteudo = conteudo.trim();
    if (cor != null) note.cor = cor;
    note.atualizadoEm = DateTime.now();
    await note.save();
    notifyListeners();
  }

  Future<void> toggleFixar(Note note) async {
    note.fixada = !note.fixada;
    await note.save();
    notifyListeners();
  }

  Future<void> excluirNota(Note note) async {
    await note.delete();
    notifyListeners();
  }

  List<Note> buscar(String query) {
    if (query.trim().isEmpty) return notes;
    final q = query.toLowerCase();
    return notes
        .where((n) =>
            n.titulo.toLowerCase().contains(q) ||
            n.conteudo.toLowerCase().contains(q))
        .toList();
  }
}
