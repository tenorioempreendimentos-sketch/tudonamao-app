import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/password_entry.dart';

class PasswordProvider extends ChangeNotifier {
  late Box<PasswordEntry> _box;
  final _uuid = const Uuid();

  static const List<String> categories = [
    'Rede Social',
    'Banco',
    'Cartão',
    'Email',
    'Streaming',
    'Loja Online',
    'Trabalho',
    'Outros',
  ];

  static const Map<String, String> categoryIcons = {
    'Rede Social': '📱',
    'Banco': '🏦',
    'Cartão': '💳',
    'Email': '✉️',
    'Streaming': '🎬',
    'Loja Online': '🛍️',
    'Trabalho': '💼',
    'Outros': '🔐',
  };

  static const Map<String, List<Map<String, String>>> categoryExtraFields = {
    'Banco': [
      {'label': 'Agência', 'hint': 'Ex: 0001'},
      {'label': 'Conta', 'hint': 'Ex: 12345-6'},
      {'label': 'CPF/CNPJ', 'hint': 'Documento vinculado'},
    ],
    'Cartão': [
      {'label': 'Número do Cartão', 'hint': 'Ex: **** **** **** 1234'},
      {'label': 'Validade', 'hint': 'Ex: 12/28'},
      {'label': 'CVV', 'hint': 'Ex: 123'},
    ],
    'Rede Social': [
      {'label': 'Perfil/Usuário', 'hint': 'Ex: @usuario'},
      {'label': 'Telefone vinculado', 'hint': 'Ex: (11) 99999-9999'},
      {'label': '', 'hint': ''},
    ],
    'Email': [
      {'label': 'Email recuperação', 'hint': 'Ex: backup@email.com'},
      {'label': 'Telefone', 'hint': 'Ex: (11) 99999-9999'},
      {'label': '', 'hint': ''},
    ],
  };

  bool _isUnlocked = false;
  bool get isUnlocked => _isUnlocked;

  List<PasswordEntry> get entries =>
      _box.values.toList()..sort((a, b) => a.category.compareTo(b.category));

  Future<void> init() async {
    _box = await Hive.openBox<PasswordEntry>('passwords');
    notifyListeners();
  }

  Map<String, List<PasswordEntry>> get entriesByCategory {
    final map = <String, List<PasswordEntry>>{};
    for (final e in entries) {
      map[e.category] = [...(map[e.category] ?? []), e];
    }
    return map;
  }

  List<PasswordEntry> getByCategory(String category) =>
      entries.where((e) => e.category == category).toList();

  List<PasswordEntry> search(String query) {
    final q = query.toLowerCase();
    return entries
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.username.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q))
        .toList();
  }

  void unlock() {
    _isUnlocked = true;
    notifyListeners();
  }

  void lock() {
    _isUnlocked = false;
    notifyListeners();
  }

  Future<void> add(PasswordEntry entry) async {
    await _box.put(entry.id, entry);
    notifyListeners();
  }

  Future<void> update(PasswordEntry entry) async {
    await entry.save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  String generateId() => _uuid.v4();
}
