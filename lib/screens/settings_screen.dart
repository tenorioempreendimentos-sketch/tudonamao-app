import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _versao = '';
  String _build = '';
  bool _verificandoUpdate = false;

  @override
  void initState() {
    super.initState();
    _carregarVersao();
  }

  Future<void> _carregarVersao() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _versao = info.version;
        _build  = info.buildNumber;
      });
    }
  }

  Future<void> _verificarAtualizacao() async {
    setState(() => _verificandoUpdate = true);
    await UpdateService.checarAtualizacao(context, silencioso: false);
    if (mounted) setState(() => _verificandoUpdate = false);
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F2240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sair da conta?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Seus dados salvos no dispositivo não serão apagados.',
          style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748b))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth  = context.read<AuthService>();
              final sync  = context.read<SyncService>();
              await sync.limparFila();
              await auth.logout();
            },
            child: const Text('Sair',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Dados da Conta ──────────────────────────────────
                    _buildSection('Conta', [
                      _buildAccountCard(auth),
                    ]),

                    const SizedBox(height: 20),

                    // ── Aparência ────────────────────────────────────────
                    _buildSection('Aparência', [
                      _buildThemeToggle(context),
                    ]),

                    const SizedBox(height: 20),

                    // ── App ─────────────────────────────────────────────
                    _buildSection('Aplicativo', [
                      _buildTile(
                        icon: Icons.system_update_rounded,
                        iconColor: const Color(0xFF22c55e),
                        title: 'Buscar atualizações',
                        subtitle: _versao.isEmpty
                            ? 'Verificando versão...'
                            : 'Versão instalada: v$_versao (build $_build)',
                        trailing: _verificandoUpdate
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF22c55e),
                                ),
                              )
                            : const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF64748b)),
                        onTap: _verificandoUpdate
                            ? null
                            : _verificarAtualizacao,
                      ),
                      _buildDivider(),
                      _buildTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF1E63B7),
                        title: 'Sobre o TudoNaMão',
                        subtitle: _versao.isEmpty
                            ? ''
                            : 'v$_versao · build $_build',
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF64748b)),
                        onTap: _mostrarSobre,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    // ── WhatsApp Bot ─────────────────────────────────────
                    _buildSection('WhatsApp Bot', [
                      _buildTile(
                        icon: Icons.chat_bubble_rounded,
                        iconColor: const Color(0xFF25d366),
                        title: 'Vincular WhatsApp',
                        subtitle: 'Registre gastos e compromissos pelo WhatsApp',
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF64748b)),
                        onTap: () => _abrirVincularWhatsApp(context),
                      ),
                    ]),

                    // ── Suporte ─────────────────────────────────────────
                    _buildSection('Suporte', [
                      _buildTile(
                        icon: Icons.chat_rounded,
                        iconColor: const Color(0xFF25d366),
                        title: 'Suporte via WhatsApp',
                        subtitle: 'Falar com a equipe TudoNaMão',
                        trailing: const Icon(Icons.open_in_new_rounded,
                            color: Color(0xFF64748b), size: 18),
                        onTap: () => _abrirUrl(
                            'https://wa.me/5521965918527?text=Olá,%20preciso%20de%20ajuda%20com%20o%20TudoNaMão'),
                      ),
                      _buildDivider(),
                      _buildTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: const Color(0xFF64748b),
                        title: 'Política de Privacidade',
                        subtitle: 'Como seus dados são protegidos',
                        trailing: const Icon(Icons.open_in_new_rounded,
                            color: Color(0xFF64748b), size: 18),
                        onTap: () => _abrirUrl(
                            'https://tudonamao-site-production.up.railway.app/privacidade.html'),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Sair ─────────────────────────────────────────────
                    _buildSection('Sessão', [
                      _buildTile(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.redAccent,
                        title: 'Sair da conta',
                        subtitle: auth.email,
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF64748b)),
                        onTap: _confirmarLogout,
                        titleColor: Colors.redAccent,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // ── Rodapé ───────────────────────────────────────────
                    Center(
                      child: Text(
                        'TudoNaMão v$_versao · Feito com ❤️ no Brasil',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          const Text(
            'Configurações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card da conta ─────────────────────────────────────────────────────────

  Widget _buildAccountCard(AuthService auth) {
    final inicial = auth.nome.isNotEmpty ? auth.nome[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E63B7), Color(0xFF0B1F3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.nome.isEmpty ? 'Usuário' : auth.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  auth.email,
                  style: const TextStyle(
                    color: Color(0xFF64748b),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22c55e).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF22c55e).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    '✓  Assinatura ativa',
                    style: TextStyle(
                      color: Color(0xFF22c55e),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Copiar e-mail
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: auth.email));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('E-mail copiado'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded,
                color: Color(0xFF64748b), size: 18),
            tooltip: 'Copiar e-mail',
          ),
        ],
      ),
    );
  }

  // ── Seção com título ──────────────────────────────────────────────────────

  Widget _buildSection(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF64748b),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F2240),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // ── Tile padrão ───────────────────────────────────────────────────────────

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748b),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  // ── Toggle de tema ────────────────────────────────────────────────────────

  Widget _buildThemeToggle(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF6366f1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              themeProvider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: const Color(0xFF6366f1),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  themeProvider.isDark ? 'Tema Escuro' : 'Tema Claro',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  themeProvider.isDark
                    ? 'Toque para alternar para claro'
                    : 'Toque para alternar para escuro',
                  style: const TextStyle(color: Color(0xFF64748b), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
            activeColor: const Color(0xFF6366f1),
            activeTrackColor: const Color(0xFF6366f1).withValues(alpha: 0.3),
            inactiveThumbColor: const Color(0xFFf59e0b),
            inactiveTrackColor: const Color(0xFFf59e0b).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
      indent: 68,
      endIndent: 0,
    );
  }

  // ── Dialog "Sobre" ────────────────────────────────────────────────────────

  void _mostrarSobre() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F2240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E63B7), Color(0xFF0B1F3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('T',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'TudoNaMão',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'v$_versao (build $_build)',
              style: const TextStyle(color: Color(0xFF64748b), fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Organize sua vida toda em um único app.\nFeito com ❤️ no Brasil.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF94a3b8), fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  _AboutRow(label: 'Finanças', icon: '💰'),
                  _AboutRow(label: 'Agenda', icon: '📅'),
                  _AboutRow(label: 'Tarefas', icon: '✅'),
                  _AboutRow(label: 'Compras', icon: '🛒'),
                  _AboutRow(label: 'Cofre de Senhas', icon: '🔐'),
                  _AboutRow(label: 'Assistente de IA', icon: '🤖'),
                  _AboutRow(label: 'Assistente de Voz', icon: '🎙️'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar',
                style: TextStyle(color: Color(0xFF1E63B7))),
          ),
        ],
      ),
    );
  }

  void _abrirVincularWhatsApp(BuildContext context) {
    final ctrlTelefone = TextEditingController();
    String? codigoGerado;
    String? meuTelefone; // telefone do usuário com 55
    bool carregando = false;
    final auth = context.read<AuthService>();
    final apiBase = 'https://tudonamao-site-production.up.railway.app';
    const botNumero = '558299763155';
    const botQrUrl  = 'https://wa.me/qr/I3V3TFXQRRDFI1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2240),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(children: [
                Icon(Icons.chat_bubble_rounded, color: Color(0xFF25d366), size: 28),
                SizedBox(width: 12),
                Text('Vincular WhatsApp',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 8),
              const Text(
                'Depois de vincular, você pode enviar mensagens como:\n"comprei 25,00 de almoço" e o app registra automaticamente!',
                style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),

              // ── Card número do bot ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF25d366).withValues(alpha: 0.08),
                  border: Border.all(color: const Color(0xFF25d366).withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25d366).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF25d366), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Número do Bot TudoNaMão',
                              style: TextStyle(color: Colors.white54, fontSize: 11)),
                          SizedBox(height: 2),
                          Text('(82) 9976-3155',
                              style: TextStyle(color: Colors.white, fontSize: 17,
                                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _abrirUrl(botQrUrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25d366),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Abrir', style: TextStyle(color: Colors.white,
                                fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (codigoGerado == null) ...[
                // Passo 1: digitar telefone
                const Text('Seu número de WhatsApp:',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrlTelefone,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '(11) 99999-9999',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixText: '+55 ',
                    prefixStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25d366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: carregando ? null : () async {
                      setModal(() => carregando = true);
                      try {
                        final token = auth.token;
                        final resp = await http.post(
                          Uri.parse('$apiBase/api/whatsapp/vincular'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: jsonEncode({
                            // Garante envio com 55 + apenas dígitos
                            'telefone': ctrlTelefone.text.replaceAll(RegExp(r'\D'), ''),
                          }),
                        );
                        final data = jsonDecode(resp.body);
                        if (data['success'] == true) {
                          // Salva o telefone do usuário (com 55) para usar no wa.me
                          final tel = ctrlTelefone.text.replaceAll(RegExp(r'\D'), '');
                          setModal(() {
                            codigoGerado = data['codigo'].toString();
                            meuTelefone  = tel.startsWith('55') ? tel : '55$tel';
                            carregando   = false;
                          });
                        } else {
                          setModal(() => carregando = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(data['message'] ?? 'Erro ao gerar código'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      } catch(e) {
                        setModal(() => carregando = false);
                      }
                    },
                    child: carregando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Gerar código', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ] else ...[
                // Passo 2: mostrar código e instrução
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25d366).withValues(alpha: 0.1),
                    border: Border.all(color: const Color(0xFF25d366).withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    const Text('Seu código de verificação:',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(codigoGerado!,
                        style: const TextStyle(color: Color(0xFF25d366), fontSize: 36,
                            fontWeight: FontWeight.w900, letterSpacing: 8)),
                    const SizedBox(height: 4),
                    const Text('Válido por 15 minutos',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Próximo passo:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(height: 8),
                      Text('1. Toque em "Enviar código" abaixo\n2. O WhatsApp vai abrir com a mensagem pronta\n3. Só enviar e aguardar confirmação! ✅',
                          style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13, height: 1.6)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Botão enviar código direto no WhatsApp
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25d366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Enviar código pelo WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    onPressed: () {
                      // Abre o WhatsApp DO BOT com o código puro (só 6 dígitos)
                      // O bot espera apenas o código numérico para verificar
                      final msg = Uri.encodeComponent(codigoGerado ?? '');
                      _abrirUrl('https://wa.me/$botNumero?text=$msg');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setModal(() => codigoGerado = null),
                    child: const Text('Usar outro número'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir: $url'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Widget auxiliar para o dialog "Sobre" ────────────────────────────────────

class _AboutRow extends StatelessWidget {
  final String label;
  final String icon;
  const _AboutRow({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13)),
          const Spacer(),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF22c55e), size: 14),
        ],
      ),
    );
  }
}
