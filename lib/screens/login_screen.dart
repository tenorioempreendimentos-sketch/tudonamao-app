import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _senhaCtrl  = TextEditingController();
  bool _loading     = false;
  bool _verSenha    = false;
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erro = null; });

    final auth   = context.read<AuthService>();
    final result = await auth.login(_emailCtrl.text.trim(), _senhaCtrl.text);

    if (!mounted) return;
    if (result['success'] == true) {
      // Navega para o app principal — o main.dart já ouve AuthService
    } else {
      setState(() {
        _loading = false;
        _erro    = result['message'] ?? 'Erro ao fazer login';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──────────────────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf97316), Color(0xFFea580c)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFf97316).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.handshake_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),

                  // ── Título ────────────────────────────────────────────────
                  const Text(
                    'TudoNaMão',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Entre com sua conta para continuar',
                    style: TextStyle(
                      color: Color(0xFF94a3b8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Erro ──────────────────────────────────────────────────
                  if (_erro != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7f1d1d).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFef4444).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFf87171), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _erro!,
                              style: const TextStyle(
                                  color: Color(0xFFf87171), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Campo e-mail ───────────────────────────────────────────
                  _Campo(
                    controller: _emailCtrl,
                    label: 'E-mail',
                    hint: 'seu@email.com',
                    icon: Icons.email_outlined,
                    tipo: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe o e-mail';
                      if (!v.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Campo senha ───────────────────────────────────────────
                  _Campo(
                    controller: _senhaCtrl,
                    label: 'Senha',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscure: !_verSenha,
                    sufixo: IconButton(
                      icon: Icon(
                        _verSenha
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF64748b),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _verSenha = !_verSenha),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a senha';
                      if (v.length < 4) return 'Senha muito curta';
                      return null;
                    },
                    onSubmit: (_) => _login(),
                  ),
                  const SizedBox(height: 32),

                  // ── Botão entrar ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf97316),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Info offline ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            color: Color(0xFF64748b), size: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'O app funciona offline após o primeiro login. Seus dados são sincronizados automaticamente.',
                            style: TextStyle(
                              color: Color(0xFF64748b),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget de campo reutilizável ───────────────────────────────────────────────
class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType tipo;
  final bool obscure;
  final Widget? sufixo;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmit;

  const _Campo({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.tipo = TextInputType.text,
    this.obscure = false,
    this.sufixo,
    this.validator,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFFcbd5e1),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: tipo,
          obscureText: obscure,
          onFieldSubmitted: onSubmit,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF475569)),
            prefixIcon: Icon(icon, color: const Color(0xFF64748b), size: 20),
            suffixIcon: sufixo,
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFf97316), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFef4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFef4444), width: 2),
            ),
            errorStyle: const TextStyle(color: Color(0xFFf87171)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
