import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl =
      'https://tudonamao-site-production.up.railway.app';

  static const _keyToken    = 'auth_token';
  static const _keyNome     = 'auth_nome';
  static const _keyEmail    = 'auth_email';
  static const _keyLoggedIn = 'auth_logged_in';

  String? _token;
  String  _nome  = '';
  String  _email = '';
  bool    _loggedIn = false;

  String? get token    => _token;
  String  get nome     => _nome;
  String  get email    => _email;
  bool    get loggedIn => _loggedIn;

  // ── Inicializa lendo do cache local ────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token    = prefs.getString(_keyToken);
    _nome     = prefs.getString(_keyNome)  ?? '';
    _email    = prefs.getString(_keyEmail) ?? '';
    _loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    notifyListeners();
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Extrai token do cookie Set-Cookie ou do body
        String? token = data['token'];
        if (token == null) {
          final cookie = response.headers['set-cookie'] ?? '';
          final match  = RegExp(r'token=([^;]+)').firstMatch(cookie);
          token = match?.group(1);
        }

        final nome  = data['user']?['name']  ?? email.split('@').first;
        final email_ = data['user']?['email'] ?? email;

        await _salvarSessao(token ?? '', nome, email_);
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Credenciais inválidas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Sem conexão com o servidor'};
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyNome);
    await prefs.remove(_keyEmail);
    await prefs.setBool(_keyLoggedIn, false);

    _token    = null;
    _nome     = '';
    _email    = '';
    _loggedIn = false;
    notifyListeners();
  }

  // ── Verifica se o token ainda é válido no servidor ─────────────────────────
  Future<bool> verificarToken() async {
    if (_token == null) return false;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/verify'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['valid'] == true) {
          // Atualiza nome caso tenha mudado
          final nome = data['user']?['name'] ?? _nome;
          if (nome != _nome) {
            _nome = nome;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_keyNome, nome);
            notifyListeners();
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      // Sem internet — mantém sessão local
      return _loggedIn;
    }
  }

  // ── Salva sessão localmente ────────────────────────────────────────────────
  Future<void> _salvarSessao(String token, String nome, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken,  token);
    await prefs.setString(_keyNome,   nome);
    await prefs.setString(_keyEmail,  email);
    await prefs.setBool(_keyLoggedIn, true);

    _token    = token;
    _nome     = nome;
    _email    = email;
    _loggedIn = true;
    notifyListeners();
  }

  // ── Primeiro nome (para saudação) ──────────────────────────────────────────
  String get primeiroNome {
    if (_nome.isEmpty) return 'Usuário';
    return _nome.split(' ').first;
  }
}
