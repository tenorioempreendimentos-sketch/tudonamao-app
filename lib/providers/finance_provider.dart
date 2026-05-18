import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class FinanceProvider extends ChangeNotifier {
  late Box<Transaction> _box;
  final _uuid = const Uuid();
  ApiService? _api;
  SyncService? _sync;

  void setServices(ApiService api, SyncService sync) {
    _api  = api;
    _sync = sync;
  }

  List<Transaction> get transactions =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  Future<void> init() async {
    _box = await Hive.openBox<Transaction>('transactions');
    notifyListeners();
  }

  Future<void> sincronizarDoServidor() async {
    if (_api == null || !(_sync?.online ?? false)) return;
    try {
      final data = await _api!.get('/api/app/financas');
      final lista = (data['items'] ?? data) as List<dynamic>;
      for (final item in lista) {
        final id = item['id'].toString();
        if (!_box.containsKey(id)) {
          final t = Transaction(
            id            : id,
            title         : item['titulo'] ?? item['title'] ?? '',
            amount        : (item['valor'] ?? item['amount'] ?? 0).toDouble(),
            type          : item['tipo'] ?? item['type'] ?? 'despesa',
            category      : item['categoria'] ?? item['category'] ?? 'Outros',
            origin        : item['origem'] ?? item['origin'] ?? '',
            date          : DateTime.parse(item['data'] ?? item['date'] ?? DateTime.now().toIso8601String()),
            description   : item['descricao'] ?? item['description'] ?? '',
            isReceived    : (item['recebido'] ?? item['pago'] ?? 1) == 1,
            paymentMethod : item['forma_pagamento'] ?? 'Dinheiro',
          );
          await _box.put(id, t);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  List<Transaction> get receitas =>
      transactions.where((t) => t.type == 'receita').toList();
  List<Transaction> get despesas =>
      transactions.where((t) => t.type == 'despesa').toList();

  double get totalReceitas =>
      receitas.where((t) => t.isReceived).fold(0, (s, t) => s + t.amount);
  double get totalDespesas =>
      despesas.where((t) => t.isReceived).fold(0, (s, t) => s + t.amount);
  double get saldo => totalReceitas - totalDespesas;
  double get totalAReceber =>
      receitas.where((t) => !t.isReceived).fold(0, (s, t) => s + t.amount);

  List<Transaction> getByMonth(int month, int year) =>
      transactions.where((t) => t.date.month == month && t.date.year == year).toList();

  // ── Saldo / receitas / despesas do mês atual ──────────────────────────────
  double get totalReceitasMesAtual {
    final now = DateTime.now();
    return getByMonth(now.month, now.year)
        .where((t) => t.type == 'receita' && t.isReceived)
        .fold(0, (s, t) => s + t.amount);
  }

  double get totalDespesasMesAtual {
    final now = DateTime.now();
    return getByMonth(now.month, now.year)
        .where((t) => t.type == 'despesa' && t.isReceived)
        .fold(0, (s, t) => s + t.amount);
  }

  double get saldoMesAtual => totalReceitasMesAtual - totalDespesasMesAtual;

  Map<String, double> get receitasPorOrigem {
    final map = <String, double>{};
    for (final t in receitas.where((t) => t.isReceived)) {
      final o = t.origin.isEmpty ? 'Outros' : t.origin;
      map[o] = (map[o] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> get despesasPorCategoria {
    final map = <String, double>{};
    for (final t in despesas.where((t) => t.isReceived)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  List<Transaction> getRecent({int limit = 5}) => transactions.take(limit).toList();

  Future<void> add(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
    notifyListeners();

    final body = {
      'titulo'         : transaction.title,
      'valor'          : transaction.amount,
      'tipo'           : transaction.type,
      'categoria'      : transaction.category,
      'origem'         : transaction.origin,
      'data'           : transaction.date.toIso8601String().split('T').first,
      'descricao'      : transaction.description,
      'recebido'       : transaction.isReceived ? 1 : 0,
      'forma_pagamento': transaction.paymentMethod,
    };
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.post('/api/app/financas', body); } catch (_) {
        await _sync?.enfileirar(metodo: 'POST', path: '/api/app/financas', body: body, idLocal: transaction.id);
      }
    } else {
      await _sync?.enfileirar(metodo: 'POST', path: '/api/app/financas', body: body, idLocal: transaction.id);
    }
  }

  Future<void> update(Transaction transaction) async {
    await transaction.save();
    notifyListeners();
  }

  Future<void> toggleReceived(Transaction transaction) async {
    transaction.isReceived = !transaction.isReceived;
    await transaction.save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.delete('/api/app/financas/$id'); } catch (_) {
        await _sync?.enfileirar(metodo: 'DELETE', path: '/api/app/financas/$id');
      }
    } else {
      await _sync?.enfileirar(metodo: 'DELETE', path: '/api/app/financas/$id');
    }
  }

  String generateId() => _uuid.v4();
}
