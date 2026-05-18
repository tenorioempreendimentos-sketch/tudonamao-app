import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/groq_service.dart';
import '../providers/finance_provider.dart';
import '../providers/urgent_task_provider.dart';
import '../providers/agenda_provider.dart';
import '../theme/app_theme.dart';

// ── Modelo de mensagem ────────────────────────────────────────────────────────

class _Mensagem {
  final String texto;
  final bool isUser;
  final DateTime hora;
  _Mensagem({required this.texto, required this.isUser})
      : hora = DateTime.now();
}

// ── Tela principal do Assistente de IA ───────────────────────────────────────

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  final List<_Mensagem> _msgs = [];
  final List<Map<String, String>> _historico = [];
  bool _enviando = false;
  bool _online = true;

  // ── Hive: histórico persistente ─────────────────────────────────────────────
  static const _kBoxName = 'ai_history';
  static const _kMsgsKey = 'msgs';
  static const _kHistKey = 'hist';
  Box<dynamic>? _histBox;

  // Sugestões rápidas
  static const _sugestoes = [
    '💰 Como está meu saldo este mês?',
    '📊 Onde estou gastando mais?',
    '✅ Tenho tarefas urgentes?',
    '📅 O que tenho na agenda?',
    '💡 Dicas para economizar dinheiro',
    '📈 Como organizar minhas finanças?',
  ];

  @override
  void initState() {
    super.initState();
    _verificarConexao();
    _carregarHistorico();
  }

  // ── Carrega histórico salvo no Hive ────────────────────────────────────────
  Future<void> _carregarHistorico() async {
    _histBox = await Hive.openBox(_kBoxName);

    final msgsRaw  = _histBox!.get(_kMsgsKey);
    final histRaw  = _histBox!.get(_kHistKey);

    if (msgsRaw != null && msgsRaw is List && msgsRaw.isNotEmpty) {
      // Restaura mensagens e histórico
      final msgs = msgsRaw.cast<Map>().map((m) => _Mensagem(
            texto:  m['texto'] as String? ?? '',
            isUser: m['isUser'] as bool? ?? false,
          )).toList();

      if (histRaw != null && histRaw is List) {
        final hist = histRaw.cast<Map>().map((h) => {
          'role':    h['role']    as String? ?? 'user',
          'content': h['content'] as String? ?? '',
        }).toList();
        _historico.addAll(hist);
      }

      if (mounted) setState(() => _msgs.addAll(msgs));
    } else {
      // Primeira vez — mensagem de boas-vindas
      _msgs.add(_Mensagem(
        texto: 'Olá! 👋 Sou o **Assistente IA** do TudoNaMão.\n\n'
            'Posso te ajudar a entender suas finanças, organizar tarefas e muito mais. '
            'Tenho acesso aos seus dados do app e posso dar dicas personalizadas.\n\n'
            'O que você quer saber?',
        isUser: false,
      ));
    }
    if (mounted) _scrollBottom();
  }

  // ── Persiste histórico no Hive ─────────────────────────────────────────────
  Future<void> _salvarHistorico() async {
    if (_histBox == null) return;
    final msgsData = _msgs.map((m) => {
      'texto':  m.texto,
      'isUser': m.isUser,
    }).toList();
    final histData = _historico.map((h) => {
      'role':    h['role'],
      'content': h['content'],
    }).toList();
    await _histBox!.put(_kMsgsKey, msgsData);
    await _histBox!.put(_kHistKey, histData);
  }

  Future<void> _verificarConexao() async {
    try {
      final result = await InternetAddress.lookup('api.groq.com')
          .timeout(const Duration(seconds: 4));
      if (mounted) setState(() => _online = result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } catch (_) {
      if (mounted) setState(() => _online = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Monta contexto com dados reais do app ─────────────────────────────────

  Map<String, dynamic> _montarContexto() {
    final finance = context.read<FinanceProvider>();
    final tasks = context.read<UrgentTaskProvider>();
    final agenda = context.read<AgendaProvider>();
    final fmt = NumberFormat('#,##0.00', 'pt_BR');
    final now = DateTime.now();

    // Categorias top de despesas
    final cats = finance.despesasPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final catsStr = cats
        .take(3)
        .map((e) => '${e.key} (R\$ ${fmt.format(e.value)})')
        .join(', ');

    // Próximos eventos (até 3)
    final proxEventos = agenda.appointments
        .where((a) => a.date.isAfter(now.subtract(const Duration(days: 1))))
        .take(3)
        .map((a) {
      final d = DateFormat('dd/MM', 'pt_BR').format(a.date);
      return '${a.title} ($d${a.time.isNotEmpty ? ' às ${a.time}' : ''})';
    }).join(', ');

    // Tarefas
    final pendentes = tasks.tasks.where((t) => !t.isDone).length;
    final urgentes =
        tasks.tasks.where((t) => !t.isDone && t.priority == 'urgente').length;

    final mesAno = DateFormat('MMMM/yyyy', 'pt_BR').format(now);

    return {
      'saldo': fmt.format(finance.saldo),
      'totalReceitas': fmt.format(finance.totalReceitas),
      'totalDespesas': fmt.format(finance.totalDespesas),
      'totalAReceber': fmt.format(finance.totalAReceber),
      'categoriasTop': catsStr.isEmpty ? 'Nenhuma despesa registrada' : catsStr,
      'tarefasPendentes': '$pendentes',
      'tarefasUrgentes': '$urgentes',
      'proximosEventos':
          proxEventos.isEmpty ? 'Nenhum evento próximo' : proxEventos,
      'mesAno': mesAno,
    };
  }

  // ── Envio de mensagem ─────────────────────────────────────────────────────

  Future<void> _enviar(String texto) async {
    final msg = texto.trim();
    if (msg.isEmpty || _enviando) return;

    _ctrl.clear();
    _focus.unfocus();

    setState(() {
      _msgs.add(_Mensagem(texto: msg, isUser: true));
      _enviando = true;
    });
    _scrollBottom();

    // Adiciona ao histórico para manter contexto
    _historico.add({'role': 'user', 'content': msg});

    try {
      final resposta = await GroqService.enviarMensagem(
        mensagem: msg,
        historico: _historico.length > 1
            ? _historico.sublist(0, _historico.length - 1)
            : [],
        contextoApp: _montarContexto(),
      );

      _historico.add({'role': 'assistant', 'content': resposta});

      // Mantém histórico em no máximo 20 mensagens para não estourar tokens
      if (_historico.length > 20) {
        _historico.removeRange(0, 2);
      }

      if (mounted) {
        setState(() {
          _msgs.add(_Mensagem(texto: resposta, isUser: false));
          _enviando = false;
        });
        _scrollBottom();
        _salvarHistorico();
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        final String mensagemErro;

        if (errStr.contains('_LIMITE_ATINGIDO_')) {
          mensagemErro = '⏳ Muitos usuários usando a IA agora. Aguarde alguns segundos e tente novamente.';
        } else if (errStr.contains('_TIMEOUT_')) {
          mensagemErro = '⏱️ A IA demorou para responder. Verifique sua conexão e tente novamente.';
        } else if (errStr.contains('_CHAVE_INVALIDA_')) {
          mensagemErro = '🔧 Serviço de IA temporariamente indisponível. Tente mais tarde.';
        } else if (errStr.contains('SocketException') || errStr.contains('NetworkException')) {
          mensagemErro = '📵 Sem conexão com a internet. Verifique sua rede e tente novamente.';
        } else {
          mensagemErro = '❌ Não consegui conectar à IA. Verifique sua internet e tente novamente.';
        }

        // Remove a msg do usuário do histórico se falhou
        if (_historico.isNotEmpty && _historico.last['role'] == 'user') {
          _historico.removeLast();
        }

        setState(() {
          _msgs.add(_Mensagem(texto: mensagemErro, isUser: false));
          _enviando = false;
        });
        _scrollBottom();
      }
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Banner offline com acesso ao histórico
            if (!_online) _buildOfflineBanner(),
            Expanded(child: _buildMessages()),
            if (!_enviando && _msgs.length <= 2 && _online) _buildSugestoes(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sem conexão — modo somente leitura',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _msgs.length > 1
                    ? '${_msgs.length - 1} mensagem${_msgs.length > 2 ? "s" : ""} no histórico disponíveis'
                    : 'Sem histórico anterior',
                  style: TextStyle(
                    color: Colors.redAccent.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _verificarConexao,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Tentar',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          // Avatar IA
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366f1).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assistente IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _online ? const Color(0xFF10b981) : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _online ? 'Online · Llama 3 via Groq' : 'Sem conexão · Verifique a internet',
                      style: TextStyle(
                        color: _online ? const Color(0xFF64748b) : Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botão limpar conversa
          if (_msgs.length > 1)
            IconButton(
              onPressed: _limparConversa,
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF64748b), size: 20),
              tooltip: 'Nova conversa',
            ),
        ],
      ),
    );
  }

  void _limparConversa() {
    setState(() {
      _msgs.clear();
      _historico.clear();
      _msgs.add(_Mensagem(
        texto: 'Conversa reiniciada! 🔄 Como posso te ajudar?',
        isUser: false,
      ));
    });
    _salvarHistorico();
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _msgs.length + (_enviando ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _msgs.length) return _buildTypingIndicator();
        return _buildBubble(_msgs[i]);
      },
    );
  }

  Widget _buildBubble(_Mensagem msg) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: msg.isUser ? 48 : 0,
        right: msg.isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 15),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.texto));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mensagem copiada'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? const Color(0xFF1E63B7)
                      : const Color(0xFF0F2240),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                    bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                  ),
                  border: msg.isUser
                      ? null
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                          width: 1,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextoFormatado(msg.texto),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(msg.hora),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Renderiza negrito (**texto**) e itálico (_texto_) simples
  Widget _buildTextoFormatado(String texto) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|_(.+?)_');
    int last = 0;

    for (final match in regex.allMatches(texto)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: texto.substring(last, match.start),
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
        ));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(
            color: Color(0xFFBDD3EA),
            fontSize: 14,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ));
      }
      last = match.end;
    }
    if (last < texto.length) {
      spans.add(TextSpan(
        text: texto.substring(last),
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 15),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2240),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildSugestoes() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Sugestões',
              style: TextStyle(color: Color(0xFF64748b), fontSize: 12),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sugestoes
                .map((s) => GestureDetector(
                      onTap: () => _enviar(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2240),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1E63B7).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            color: Color(0xFFBDD3EA),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F2240),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Theme(
                // Isola o TextField do inputDecorationTheme global.
                // No tema claro, fillColor=white tornaria o texto branco invisível.
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: const Color(0xFF6366f1),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _online
                        ? 'Pergunte algo...'
                        : 'Sem conexão — histórico disponível acima',
                    hintStyle: const TextStyle(
                        color: Color(0xFF64748b), fontSize: 14),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  onSubmitted: _online ? _enviar : null,
                  enabled: _online,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: _enviando
                  ? const LinearGradient(
                      colors: [Color(0xFF374151), Color(0xFF374151)])
                  : const LinearGradient(
                      colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _enviando
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF6366f1).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _enviando ? null : () => _enviar(_ctrl.text),
                child: Center(
                  child: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animação dos 3 pontos de "digitando" ─────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
