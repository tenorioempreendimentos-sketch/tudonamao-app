import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  late Box<Budget> _box;
  final _uuid = const Uuid();

  List<Budget> get budgets =>
      _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Budget> get emitidos =>
      budgets.where((b) => b.budgetType == 'emitido').toList();

  List<Budget> get recebidos =>
      budgets.where((b) => b.budgetType == 'recebido').toList();

  Future<void> init() async {
    _box = await Hive.openBox<Budget>('budgets');
    notifyListeners();
  }

  List<Budget> getByStatus(String status) =>
      budgets.where((b) => b.status == status).toList();

  List<Budget> getByType(String type) =>
      budgets.where((b) => b.budgetType == type).toList();

  double get totalAprovado => budgets
      .where((b) => b.status == 'aprovado' && b.budgetType == 'emitido')
      .fold(0, (sum, b) => sum + b.total);

  double get totalRecebidoAceito => budgets
      .where((b) => b.status == 'aceito' && b.budgetType == 'recebido')
      .fold(0, (sum, b) => sum + b.total);

  Future<void> add(Budget budget) async {
    await _box.put(budget.id, budget);
    notifyListeners();
  }

  Future<void> update(Budget budget) async {
    await budget.save();
    notifyListeners();
  }

  Future<void> updateStatus(Budget budget, String status) async {
    budget.status = status;
    await budget.save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  String generateId() => _uuid.v4();
  String generateItemId() => _uuid.v4();
}
