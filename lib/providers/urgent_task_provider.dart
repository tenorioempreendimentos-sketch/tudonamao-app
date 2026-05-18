import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/urgent_task.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class UrgentTaskProvider extends ChangeNotifier {
  late Box<UrgentTask> _box;
  final _uuid = const Uuid();
  ApiService? _api;
  SyncService? _sync;

  void setServices(ApiService api, SyncService sync) {
    _api  = api;
    _sync = sync;
  }

  List<UrgentTask> get tasks =>
      _box.values.toList()..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        final order = {'urgente': 0, 'importante': 1, 'normal': 2};
        final pa = order[a.priority] ?? 2;
        final pb = order[b.priority] ?? 2;
        if (pa != pb) return pa.compareTo(pb);
        if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
        return 0;
      });

  Future<void> init() async {
    _box = await Hive.openBox<UrgentTask>('urgent_tasks');
    notifyListeners();
  }

  Future<void> sincronizarDoServidor() async {
    if (_api == null || !(_sync?.online ?? false)) return;
    try {
      final lista = await _api!.get('/api/app/urgencias') as List<dynamic>;
      for (final item in lista) {
        final id = item['id'].toString();
        if (!_box.containsKey(id)) {
          final t = UrgentTask(
            id       : id,
            title    : item['titulo'] ?? '',
            type     : item['tipo'] ?? 'tarefa',
            priority : item['prioridade'] ?? 'normal',
            dueDate  : item['data_vencimento'] != null
                ? DateTime.tryParse(item['data_vencimento']) : null,
            amount   : item['valor'] != null ? (item['valor']).toDouble() : null,
            isDone   : (item['concluido'] ?? 0) == 1,
            note     : item['nota'] ?? '',
            createdAt: DateTime.tryParse(item['criado_em'] ?? '') ?? DateTime.now(),
            category : item['categoria'] ?? 'Geral',
          );
          await _box.put(id, t);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  List<UrgentTask> get tarefas  => tasks.where((t) => t.type == 'tarefa').toList();
  List<UrgentTask> get contas   => tasks.where((t) => t.type == 'conta').toList();
  List<UrgentTask> get overdueItems   => tasks.where((t) => t.isOverdue).toList();
  List<UrgentTask> get dueTodayItems  => tasks.where((t) => t.isDueToday && !t.isDone).toList();
  List<UrgentTask> get pendingUrgent  => tasks.where((t) => !t.isDone && t.priority == 'urgente').toList();
  int    get pendingCount         => tasks.where((t) => !t.isDone).length;
  double get totalContasPendentes => contas
      .where((t) => !t.isDone && t.amount != null)
      .fold(0, (s, t) => s + t.amount!);

  Future<void> add(UrgentTask task) async {
    await _box.put(task.id, task);
    notifyListeners();
    final body = {
      'titulo'          : task.title,
      'tipo'            : task.type,
      'prioridade'      : task.priority,
      'data_vencimento' : task.dueDate?.toIso8601String().split('T').first,
      'valor'           : task.amount,
      'nota'            : task.note,
      'categoria'       : task.category,
    };
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.post('/api/app/urgencias', body); } catch (_) {
        await _sync?.enfileirar(metodo: 'POST', path: '/api/app/urgencias', body: body, idLocal: task.id);
      }
    } else {
      await _sync?.enfileirar(metodo: 'POST', path: '/api/app/urgencias', body: body, idLocal: task.id);
    }
  }

  Future<void> toggleDone(UrgentTask task) async {
    final concluindo = !task.isDone; // vai marcar como concluído
    task.isDone = concluindo;
    await task.save();

    // ── Recorrência: cria próxima ocorrência ao concluir ──────────────────
    if (concluindo && task.recurrenceType != 'nenhuma' && task.nextOccurrence != null) {
      final proxima = task.nextOccurrence!;
      final novaTask = UrgentTask(
        id: _uuid.v4(),
        title: task.title,
        type: task.type,
        priority: task.priority,
        dueDate: proxima,
        amount: task.amount,
        isDone: false,
        note: task.note,
        createdAt: DateTime.now(),
        category: task.category,
        recurrenceType: task.recurrenceType,
        nextOccurrence: _calcularProxima(proxima, task.recurrenceType),
      );
      await _box.put(novaTask.id, novaTask);
    }

    notifyListeners();
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.patch('/api/app/urgencias/${task.id}/toggle'); } catch (_) {
        await _sync?.enfileirar(metodo: 'PATCH', path: '/api/app/urgencias/${task.id}/toggle');
      }
    } else {
      await _sync?.enfileirar(metodo: 'PATCH', path: '/api/app/urgencias/${task.id}/toggle');
    }
  }

  DateTime? _calcularProxima(DateTime base, String tipo) {
    switch (tipo) {
      case 'diaria':  return base.add(const Duration(days: 1));
      case 'semanal': return base.add(const Duration(days: 7));
      case 'mensal':  return DateTime(base.year, base.month + 1, base.day);
      case 'anual':   return DateTime(base.year + 1, base.month, base.day);
      default:        return null;
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.delete('/api/app/urgencias/$id'); } catch (_) {
        await _sync?.enfileirar(metodo: 'DELETE', path: '/api/app/urgencias/$id');
      }
    } else {
      await _sync?.enfileirar(metodo: 'DELETE', path: '/api/app/urgencias/$id');
    }
  }

  String generateId() => _uuid.v4();
}
