import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Gerencia a fila de operações offline e sincroniza quando a internet volta.
class SyncService extends ChangeNotifier {
  static const _keyFila = 'sync_fila';

  final ApiService _api;
  bool _online = true;
  bool _sincronizando = false;
  int  _pendentes = 0;

  bool get online        => _online;
  bool get sincronizando => _sincronizando;
  int  get pendentes     => _pendentes;

  StreamSubscription? _sub;

  SyncService(this._api);

  // ── Inicia monitoramento de conectividade ──────────────────────────────────
  Future<void> init() async {
    final result = await Connectivity().checkConnectivity();
    _online = _isOnline(result);

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !_online;
      _online = _isOnline(results);
      notifyListeners();

      // Voltou online → sincroniza fila pendente
      if (wasOffline && _online) {
        sincronizar();
      }
    });

    await _atualizarContador();
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  // ── Enfileira operação para sync posterior ─────────────────────────────────
  Future<void> enfileirar({
    required String metodo,  // GET, POST, PUT, PATCH, DELETE
    required String path,
    Map<String, dynamic>? body,
    String? idLocal,         // id Hive local para deduplicação
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final filaJson = prefs.getStringList(_keyFila) ?? [];

    final op = {
      'metodo'  : metodo,
      'path'    : path,
      'body'    : body,
      'idLocal' : idLocal,
      'ts'      : DateTime.now().toIso8601String(),
    };

    filaJson.add(json.encode(op));
    await prefs.setStringList(_keyFila, filaJson);
    await _atualizarContador();
  }

  // ── Sincroniza fila com o servidor ────────────────────────────────────────
  Future<void> sincronizar() async {
    if (_sincronizando || !_online) return;

    final prefs    = await SharedPreferences.getInstance();
    final filaJson = prefs.getStringList(_keyFila) ?? [];
    if (filaJson.isEmpty) return;

    _sincronizando = true;
    notifyListeners();

    final falhas = <String>[];

    for (final opJson in filaJson) {
      try {
        final op     = json.decode(opJson) as Map<String, dynamic>;
        final metodo = op['metodo'] as String;
        final path   = op['path']   as String;
        final body   = op['body']   != null
            ? Map<String, dynamic>.from(op['body'] as Map)
            : null;

        switch (metodo) {
          case 'POST':   await _api.post(path, body!);    break;
          case 'PUT':    await _api.put(path, body!);     break;
          case 'PATCH':  await _api.patch(path, body);    break;
          case 'DELETE': await _api.delete(path);         break;
        }
      } catch (e) {
        // Se falhou de novo, mantém na fila
        falhas.add(opJson);
      }
    }

    await prefs.setStringList(_keyFila, falhas);
    await _atualizarContador();

    _sincronizando = false;
    notifyListeners();
  }

  // ── Limpa fila (ex: logout) ────────────────────────────────────────────────
  Future<void> limparFila() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFila);
    _pendentes = 0;
    notifyListeners();
  }

  Future<void> _atualizarContador() async {
    final prefs = await SharedPreferences.getInstance();
    _pendentes = (prefs.getStringList(_keyFila) ?? []).length;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
