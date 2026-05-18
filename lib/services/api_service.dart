import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Serviço central de chamadas HTTP.
/// Online  → chama o servidor Railway com JWT.
/// Offline → lança ApiOfflineException (provider usa Hive local).
class ApiService {
  static const String _base =
      'https://tudonamao-site-production.up.railway.app';

  final AuthService _auth;

  ApiService(this._auth);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
      };

  // ── GET ────────────────────────────────────────────────────────────────────
  Future<dynamic> get(String path) async {
    final res = await http
        .get(Uri.parse('$_base$path'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── POST ───────────────────────────────────────────────────────────────────
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse('$_base$path'),
            headers: _headers, body: json.encode(body))
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── PUT ────────────────────────────────────────────────────────────────────
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http
        .put(Uri.parse('$_base$path'),
            headers: _headers, body: json.encode(body))
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── PATCH ──────────────────────────────────────────────────────────────────
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http
        .patch(Uri.parse('$_base$path'),
            headers: _headers,
            body: body != null ? json.encode(body) : null)
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  Future<dynamic> delete(String path) async {
    final res = await http
        .delete(Uri.parse('$_base$path'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── Handler interno ────────────────────────────────────────────────────────
  dynamic _handle(http.Response res) {
    if (res.statusCode == 401) throw ApiAuthException();
    if (res.statusCode >= 500) throw ApiServerException(res.statusCode);
    if (res.body.isEmpty) return null;
    return json.decode(res.body);
  }
}

class ApiOfflineException implements Exception {}
class ApiAuthException    implements Exception {}
class ApiServerException  implements Exception {
  final int code;
  ApiServerException(this.code);
}
