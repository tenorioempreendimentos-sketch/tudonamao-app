import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class AgendaProvider extends ChangeNotifier {
  late Box<Appointment> _box;
  final _uuid = const Uuid();
  ApiService? _api;
  SyncService? _sync;

  void setServices(ApiService api, SyncService sync) {
    _api  = api;
    _sync = sync;
  }

  List<Appointment> get appointments =>
      _box.values.toList()..sort((a, b) => a.date.compareTo(b.date));

  Future<void> init() async {
    _box = await Hive.openBox<Appointment>('appointments');
    notifyListeners();
  }

  // ── Sync: baixa dados do servidor e mescla no Hive ────────────────────────
  Future<void> sincronizarDoServidor() async {
    if (_api == null || !(_sync?.online ?? false)) return;
    try {
      final lista = await _api!.get('/api/app/agenda') as List<dynamic>;
      for (final item in lista) {
        final id = item['id'].toString();
        if (!_box.containsKey(id)) {
          final ap = Appointment(
            id          : id,
            title       : item['titulo'] ?? '',
            description : item['descricao'] ?? '',
            date        : DateTime.parse(item['data']),
            time        : item['hora'] ?? '',
            category    : item['categoria'] ?? 'Geral',
            isCompleted : (item['concluido'] ?? 0) == 1,
            color       : item['cor'] ?? 'blue',
          );
          await _box.put(id, ap);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  List<Appointment> getByDate(DateTime date) {
    return appointments.where((a) {
      return a.date.year  == date.year &&
             a.date.month == date.month &&
             a.date.day   == date.day;
    }).toList();
  }

  List<Appointment> getUpcoming() {
    final now = DateTime.now();
    return appointments
        .where((a) => a.date.isAfter(now) && !a.isCompleted)
        .take(5)
        .toList();
  }

  Map<DateTime, List<Appointment>> get eventMap {
    final map = <DateTime, List<Appointment>>{};
    for (final a in appointments) {
      final key = DateTime(a.date.year, a.date.month, a.date.day);
      map[key] = [...(map[key] ?? []), a];
    }
    return map;
  }

  Future<void> add(Appointment appointment) async {
    await _box.put(appointment.id, appointment);
    notifyListeners();

    final body = {
      'titulo'    : appointment.title,
      'descricao' : appointment.description,
      'data'      : appointment.date.toIso8601String().split('T').first,
      'hora'      : appointment.time,
      'categoria' : appointment.category,
      'cor'       : appointment.color,
    };

    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.post('/api/app/agenda', body); } catch (_) {
        await _sync?.enfileirar(metodo: 'POST', path: '/api/app/agenda',
            body: body, idLocal: appointment.id);
      }
    } else {
      await _sync?.enfileirar(metodo: 'POST', path: '/api/app/agenda',
          body: body, idLocal: appointment.id);
    }
  }

  Future<void> update(Appointment appointment) async {
    await appointment.save();
    notifyListeners();

    final body = {
      'titulo'    : appointment.title,
      'descricao' : appointment.description,
      'data'      : appointment.date.toIso8601String().split('T').first,
      'hora'      : appointment.time,
      'categoria' : appointment.category,
      'cor'       : appointment.color,
      'concluido' : appointment.isCompleted ? 1 : 0,
    };

    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.put('/api/app/agenda/${appointment.id}', body); } catch (_) {
        await _sync?.enfileirar(metodo: 'PUT',
            path: '/api/app/agenda/${appointment.id}', body: body);
      }
    } else {
      await _sync?.enfileirar(metodo: 'PUT',
          path: '/api/app/agenda/${appointment.id}', body: body);
    }
  }

  Future<void> toggleComplete(Appointment appointment) async {
    appointment.isCompleted = !appointment.isCompleted;
    await appointment.save();
    notifyListeners();

    final body = {'concluido': appointment.isCompleted ? 1 : 0};
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.put('/api/app/agenda/${appointment.id}', body); } catch (_) {
        await _sync?.enfileirar(metodo: 'PUT',
            path: '/api/app/agenda/${appointment.id}', body: body);
      }
    } else {
      await _sync?.enfileirar(metodo: 'PUT',
          path: '/api/app/agenda/${appointment.id}', body: body);
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();

    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.delete('/api/app/agenda/$id'); } catch (_) {
        await _sync?.enfileirar(metodo: 'DELETE', path: '/api/app/agenda/$id');
      }
    } else {
      await _sync?.enfileirar(metodo: 'DELETE', path: '/api/app/agenda/$id');
    }
  }

  String generateId() => _uuid.v4();
}
