import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' as math;

import '../services/voice_service.dart';
import '../providers/agenda_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/urgent_task_provider.dart';
import '../models/appointment.dart';
import '../models/shopping_item.dart';
import '../models/transaction.dart';
import '../models/urgent_task.dart';

// ── Estado do assistente ─────────────────────────────────────────────────────

enum AssistantState {
  idle,       // Esperando
  listening,  // Ouvindo (microfone ativo)
  processing, // Processando comando
  responding, // Mostrando resposta
  error,      // Erro
}

// ── Widget principal (Botão FAB + Sheet) ─────────────────────────────────────

class VoiceAssistantButton extends StatefulWidget {
  final Function(int)? onNavigate;

  const VoiceAssistantButton({super.key, this.onNavigate});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> {
  bool _isOpen = false;

  void _openAssistant() {
    setState(() => _isOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => VoiceAssistantSheet(
        onNavigate: widget.onNavigate,
      ),
    ).then((_) => setState(() => _isOpen = false));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openAssistant,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isOpen
              ? const Color(0xFF6C63FF)
              : const Color(0xFF1E3A5F),
          border: Border.all(
            color: _isOpen
                ? const Color(0xFF6C63FF)
                : const Color(0xFF2E5080),
            width: 1.5,
          ),
          boxShadow: _isOpen
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Icon(
          Icons.mic_rounded,
          color: _isOpen ? Colors.white : const Color(0xFF8AAECC),
          size: 22,
        ),
      ),
    );
  }
}

// ── Bottom Sheet do assistente ────────────────────────────────────────────────

class VoiceAssistantSheet extends StatefulWidget {
  final Function(int)? onNavigate;
  const VoiceAssistantSheet({super.key, this.onNavigate});

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet>
    with TickerProviderStateMixin {

  // ── Speech to Text ────────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  String _recognizedWords = '';
  double _soundLevel = 0.0;

  AssistantState _state = AssistantState.idle;
  String _displayText = 'Toque no microfone e fale seu comando';
  String _subText = '';
  VoiceCommand? _lastCommand; // ignore: unused_field
  bool _commandExecuted = false;

  // Fallback: campo de texto manual
  final _textController = TextEditingController();
  bool _showTextInput = false;
  bool _useFallback = false; // true se STT não disponível

  // Animação das ondas sonoras
  late AnimationController _waveCtrl;
  late AnimationController _dotCtrl;

  // Timer de segurança — para escuta após silêncio prolongado
  Timer? _silenceTimer;

  // Histórico de comandos
  final List<_HistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _initSpeech();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speech.stop();
    _waveCtrl.dispose();
    _dotCtrl.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── Inicialização do STT ─────────────────────────────────────────────────

  Future<void> _initSpeech() async {
    // 1. Verificar / solicitar permissão de microfone
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        // Sem permissão → usar fallback de texto
        if (mounted) {
          setState(() {
            _useFallback = true;
            _speechAvailable = false;
          });
        }
        return;
      }
    }

    // 2. Inicializar engine STT
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          if (mounted) {
            setState(() {
              _state = AssistantState.error;
              _displayText = 'Erro no microfone';
              _subText = error.errorMsg;
            });
            _waveCtrl.stop();
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_state == AssistantState.listening && _recognizedWords.isNotEmpty) {
              _finishListening();
            } else if (_state == AssistantState.listening && _recognizedWords.isEmpty) {
              if (mounted) {
                setState(() {
                  _state = AssistantState.idle;
                  _displayText = 'Não ouvi nada. Tente novamente.';
                  _subText = '';
                });
                _waveCtrl.stop();
              }
            }
          }
        },
      );
    } catch (e) {
      _speechAvailable = false;
    }

    if (!_speechAvailable && mounted) {
      setState(() {
        _useFallback = true;
        _subText = 'Modo texto ativo (microfone indisponível)';
      });
    }
  }

  // ── Fluxo principal ───────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (_useFallback || !_speechAvailable) {
      // Fallback: abrir campo de texto com teclado + microfone do teclado
      setState(() {
        _state = AssistantState.listening;
        _displayText = 'Digite ou use o mic do teclado';
        _subText = 'Pressione enviar quando terminar';
        _showTextInput = true;
        _commandExecuted = false;
      });
      _waveCtrl.repeat(reverse: true);
      return;
    }

    setState(() {
      _state = AssistantState.listening;
      _displayText = 'Ouvindo...';
      _subText = 'Fale seu comando agora';
      _recognizedWords = '';
      _commandExecuted = false;
    });
    _waveCtrl.repeat(reverse: true);

    // Timer de segurança: para após 10 segundos de silêncio
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 10), () {
      if (_state == AssistantState.listening) {
        _speech.stop();
      }
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _recognizedWords = result.recognizedWords;
            if (_recognizedWords.isNotEmpty) {
              _displayText = '"$_recognizedWords"';
              _subText = result.finalResult ? 'Processando...' : 'Ouvindo...';
            }
          });

          // Resultado final — processar imediatamente
          if (result.finalResult && _recognizedWords.isNotEmpty) {
            _silenceTimer?.cancel();
            _finishListening();
          }
        }
      },
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level);
      },
      localeId: 'pt_BR',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _finishListening() {
    _silenceTimer?.cancel();
    _waveCtrl.stop();
    _speech.stop();

    final text = _useFallback
        ? _textController.text.trim()
        : _recognizedWords.trim();

    if (text.isEmpty) {
      _resetToIdle();
      return;
    }
    _processCommand(text);
  }

  void _stopListeningManual() {
    _silenceTimer?.cancel();
    if (!_useFallback && _speechAvailable) {
      _speech.stop();
    }
    _finishListening();
  }

  Future<void> _processCommand(String text) async {
    setState(() {
      _state = AssistantState.processing;
      _displayText = 'Processando...';
      _subText = '"$text"';
      _showTextInput = false;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final command = VoiceService.interpret(text);
    setState(() {
      _lastCommand = command;
      _state = AssistantState.responding;
      _displayText = command.responseText;
      _subText = '';
    });

    await _executeCommand(command);
    _textController.clear();
    _recognizedWords = '';
  }

  Future<void> _executeCommand(VoiceCommand command) async {
    final agendaP = context.read<AgendaProvider>();
    final shoppingP = context.read<ShoppingProvider>();
    final financeP = context.read<FinanceProvider>();
    final taskP = context.read<UrgentTaskProvider>();

    try {
      switch (command.type) {
        case VoiceCommandType.agendarCompromisso:
          await _criarCompromisso(agendaP, command);
          break;

        case VoiceCommandType.adicionarCompra:
          await _criarItemCompra(shoppingP, command);
          break;

        case VoiceCommandType.adicionarReceita:
          await _criarTransacao(financeP, command, 'receita');
          break;

        case VoiceCommandType.adicionarDespesa:
          await _criarTransacao(financeP, command, 'despesa');
          break;

        case VoiceCommandType.criarTarefa:
          await _criarTarefa(taskP, command);
          break;

        case VoiceCommandType.consultarSaldo:
          widget.onNavigate?.call(2);
          break;

        case VoiceCommandType.consultarAgenda:
          widget.onNavigate?.call(1);
          break;

        case VoiceCommandType.consultarCompras:
          widget.onNavigate?.call(4);
          break;

        case VoiceCommandType.ajuda:
          break;

        case VoiceCommandType.desconhecido:
          setState(() {
            _state = AssistantState.error;
            _displayText = 'Não entendi 🤔';
            _subText = 'Diga "ajuda" para ver os comandos';
          });
          return;
      }

      setState(() => _commandExecuted = true);

      _history.insert(0, _HistoryItem(
        text: command.rawText,
        response: command.responseText,
        type: command.type,
        time: DateTime.now(),
      ));

      if (command.type == VoiceCommandType.consultarSaldo ||
          command.type == VoiceCommandType.consultarAgenda ||
          command.type == VoiceCommandType.consultarCompras) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop();
        return;
      }

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) _resetToIdle();

    } catch (e) {
      setState(() {
        _state = AssistantState.error;
        _displayText = 'Erro ao executar comando';
        _subText = 'Tente novamente';
      });
    }
  }

  // ── Criadores ─────────────────────────────────────────────────────────────

  Future<void> _criarCompromisso(AgendaProvider p, VoiceCommand cmd) async {
    final id = p.generateId();
    final data = cmd.params['data'] as DateTime? ?? DateTime.now().add(const Duration(hours: 1));
    final time = cmd.params['time'] as String? ?? '08:00';
    final titulo = cmd.params['titulo'] as String? ?? 'Compromisso';

    final appt = Appointment(
      id: id,
      title: titulo,
      description: 'Criado por assistente de voz',
      date: data,
      time: time,
      category: 'Geral',
      color: 'blue',
    );
    await p.add(appt);

    setState(() {
      _displayText = '✅ Compromisso agendado!';
      _subText = '"$titulo" em ${cmd.params['dataFormatada'] ?? time}';
    });
  }

  Future<void> _criarItemCompra(ShoppingProvider p, VoiceCommand cmd) async {
    final id = p.generateId();
    final nome = cmd.params['nome'] as String? ?? 'Item';
    final qtd = (cmd.params['quantidade'] as double?) ?? 1.0;
    final unit = cmd.params['unit'] as String? ?? 'un';
    final preco = cmd.params['preco'] as double?;
    final cat = cmd.params['categoria'] as String? ?? 'Supermercado';

    final item = ShoppingItem(
      id: id,
      name: nome,
      category: cat,
      quantity: qtd,
      unit: unit,
      estimatedPrice: preco,
      createdAt: DateTime.now(),
    );
    await p.add(item);

    setState(() {
      _displayText = '✅ Item adicionado!';
      _subText = '"$nome" na lista de ${cat.toLowerCase()}';
    });
  }

  Future<void> _criarTransacao(FinanceProvider p, VoiceCommand cmd, String tipo) async {
    final id = p.generateId();
    final titulo = cmd.params['titulo'] as String? ?? (tipo == 'receita' ? 'Receita' : 'Despesa');
    final valor = (cmd.params['valor'] as double?) ?? 0.0;

    final tx = Transaction(
      id: id,
      title: titulo,
      amount: valor,
      type: tipo,
      category: 'Outros',
      origin: tipo == 'receita' ? 'Voz' : '',
      date: DateTime.now(),
      description: 'Lançado por assistente de voz',
      isReceived: true,
      paymentMethod: 'Outros',
    );
    await p.add(tx);

    final label = tipo == 'receita' ? 'Receita' : 'Despesa';
    setState(() {
      _displayText = '✅ $label registrada!';
      _subText = valor > 0
          ? '"$titulo" — R\$ ${valor.toStringAsFixed(2)}'
          : '"$titulo" adicionada';
    });
  }

  Future<void> _criarTarefa(UrgentTaskProvider p, VoiceCommand cmd) async {
    final id = p.generateId();
    final titulo = cmd.params['titulo'] as String? ?? 'Tarefa urgente';

    final task = UrgentTask(
      id: id,
      title: titulo,
      type: 'tarefa',
      priority: 'urgente',
      dueDate: DateTime.now().add(const Duration(hours: 24)),
      note: 'Criado por assistente de voz',
      createdAt: DateTime.now(),
    );
    await p.add(task);

    setState(() {
      _displayText = '✅ Tarefa criada!';
      _subText = '"$titulo" adicionada às urgentes';
    });
  }

  void _resetToIdle() {
    if (!mounted) return;
    setState(() {
      _state = AssistantState.idle;
      _displayText = 'Toque no microfone e fale seu comando';
      _subText = _useFallback ? 'Modo texto (mic indisponível)' : '';
      _showTextInput = false;
      _commandExecuted = false;
      _lastCommand = null;
      _recognizedWords = '';
    });
    _waveCtrl.stop();
    _waveCtrl.reset();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4A47E8)],
                        ),
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assistente de Voz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _useFallback ? 'Modo texto' : 'TudoNaMão',
                          style: TextStyle(
                            color: _useFallback
                                ? const Color(0xFFFFAA00)
                                : const Color(0xFF6C63FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _showHelp,
                      icon: const Icon(Icons.help_outline_rounded,
                          color: Colors.white54, size: 22),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 22),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              // Área principal
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildStateVisualizer(),
                    const SizedBox(height: 20),

                    Text(
                      _displayText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _state == AssistantState.error
                            ? const Color(0xFFFF6B6B)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    if (_subText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _subText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF8899B0),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Campo de texto (fallback ou quando STT não disponível)
                    if (_showTextInput) _buildTextInput(),

                    // Botão principal de microfone
                    _buildMainButton(),
                    const SizedBox(height: 16),

                    if (_state == AssistantState.idle) _buildQuickExamples(),
                    if (_history.isNotEmpty && _state == AssistantState.idle)
                      _buildHistory(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateVisualizer() {
    return SizedBox(
      height: 80,
      child: _state == AssistantState.listening
          ? _soundLevel > 0 && !_useFallback
              ? _SoundLevelVisualizer(level: _soundLevel, controller: _waveCtrl)
              : _WaveVisualizer(controller: _waveCtrl)
          : _state == AssistantState.processing
              ? const _DotsLoader()
              : _state == AssistantState.responding && _commandExecuted
                  ? const _SuccessIcon()
                  : _state == AssistantState.error
                      ? const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFFF6B6B), size: 52)
                      : _buildIdleOrb(),
    );
  }

  Widget _buildIdleOrb() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.3),
            const Color(0xFF6C63FF).withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: const Icon(Icons.graphic_eq_rounded,
          color: Color(0xFF6C63FF), size: 36),
    );
  }

  Widget _buildTextInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2840),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: _textController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Digite ou use o mic do teclado...',
          hintStyle: const TextStyle(color: Color(0xFF4A5D73)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            onPressed: _stopListeningManual,
            icon: const Icon(Icons.send_rounded, color: Color(0xFF6C63FF)),
          ),
        ),
        onSubmitted: (_) => _stopListeningManual(),
        textInputAction: TextInputAction.send,
      ),
    );
  }

  Widget _buildMainButton() {
    final isListening = _state == AssistantState.listening;
    final isProcessing = _state == AssistantState.processing;

    return GestureDetector(
      onTap: isProcessing
          ? null
          : isListening
              ? _stopListeningManual
              : _startListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isListening ? 72 : 64,
        height: isListening ? 72 : 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isListening
                ? [const Color(0xFFFF4757), const Color(0xFFFF6B81)]
                : isProcessing
                    ? [const Color(0xFF4A5568), const Color(0xFF2D3748)]
                    : [const Color(0xFF6C63FF), const Color(0xFF4A47E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isListening
                      ? const Color(0xFFFF4757)
                      : const Color(0xFF6C63FF))
                  .withValues(alpha: 0.45),
              blurRadius: isListening ? 24 : 16,
              spreadRadius: isListening ? 4 : 0,
            ),
          ],
        ),
        child: Icon(
          isListening
              ? Icons.stop_rounded
              : isProcessing
                  ? Icons.hourglass_top_rounded
                  : Icons.mic_rounded,
          color: Colors.white,
          size: isListening ? 32 : 28,
        ),
      ),
    );
  }

  Widget _buildQuickExamples() {
    final examples = [
      ('📅', 'Reunião amanhã às 10h'),
      ('🛒', 'Adicionar arroz'),
      ('💰', 'Recebi R\$200'),
      ('⚡', 'Tarefa pagar conta'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Tente dizer:',
            style: TextStyle(
              color: Color(0xFF4A5D73),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: .5,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples.map((e) => GestureDetector(
            onTap: () => _processCommand(e.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2840),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.$1, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(e.$2,
                    style: const TextStyle(
                      color: Color(0xFF8899B0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: Text('Comandos recentes:',
            style: TextStyle(
              color: Color(0xFF4A5D73),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: .5,
            ),
          ),
        ),
        ..._history.take(3).map((h) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2840),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(_typeEmoji(h.type), style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(h.response,
                      style: const TextStyle(
                        color: Color(0xFF4A5D73),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _typeEmoji(VoiceCommandType t) {
    switch (t) {
      case VoiceCommandType.agendarCompromisso: return '📅';
      case VoiceCommandType.adicionarCompra: return '🛒';
      case VoiceCommandType.adicionarReceita: return '💚';
      case VoiceCommandType.adicionarDespesa: return '💸';
      case VoiceCommandType.criarTarefa: return '⚡';
      case VoiceCommandType.consultarSaldo: return '💰';
      case VoiceCommandType.consultarAgenda: return '📋';
      case VoiceCommandType.consultarCompras: return '🛍️';
      case VoiceCommandType.ajuda: return '❓';
      case VoiceCommandType.desconhecido: return '🤔';
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0F1B2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Text('🎤', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Text('Comandos de Voz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              _helpRow('📅', 'Agenda', '"Agendar reunião amanhã às 14h"\n"Marcar consulta sexta"'),
              _helpRow('🛒', 'Compras', '"Adicionar arroz na lista"\n"Comprar 2kg de feijão"'),
              _helpRow('💰', 'Finanças', '"Recebi R\$500 de salário"\n"Gastei R\$80 no mercado"'),
              _helpRow('⚡', 'Tarefas', '"Tarefa urgente ligar pro banco"'),
              _helpRow('📊', 'Consultar', '"Minha agenda de hoje"\n"Quanto é meu saldo?"'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar',
                  style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpRow(String emoji, String title, String examples) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(examples,
                  style: const TextStyle(
                    color: Color(0xFF6C7A8A),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Visualizador de nível de som real ────────────────────────────────────────

class _SoundLevelVisualizer extends StatelessWidget {
  final double level;
  final AnimationController controller;
  const _SoundLevelVisualizer({required this.level, required this.controller});

  @override
  Widget build(BuildContext context) {
    // level varia de -2 a 10 aprox; normaliza para 0..1
    final normalized = ((level + 2) / 12).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(9, (i) {
            final offset = (i / 9) * 2 * math.pi;
            final t = controller.value * 2 * math.pi;
            final base = 10.0 + 30.0 * math.sin(t + offset).abs();
            final h = base * (0.4 + 0.6 * normalized);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 5,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF),
                      const Color(0xFF4A47E8).withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Animações auxiliares ──────────────────────────────────────────────────────

class _WaveVisualizer extends StatefulWidget {
  final AnimationController controller;
  const _WaveVisualizer({required this.controller});

  @override
  State<_WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<_WaveVisualizer> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(9, (i) {
            final offset = (i / 9) * 2 * math.pi;
            final t = widget.controller.value * 2 * math.pi;
            final h = 10.0 + 30.0 * math.sin(t + offset).abs();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: 5,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF),
                      const Color(0xFF4A47E8).withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader();

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final scale = 0.6 + 0.6 * math.sin(t * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SuccessIcon extends StatefulWidget {
  const _SuccessIcon();

  @override
  State<_SuccessIcon> createState() => _SuccessIconState();
}

class _SuccessIconState extends State<_SuccessIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.scale(
        scale: _anim.value,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF22C55E), size: 38),
        ),
      ),
    );
  }
}

// ── Modelo de histórico ───────────────────────────────────────────────────────

class _HistoryItem {
  final String text;
  final String response;
  final VoiceCommandType type;
  final DateTime time;

  const _HistoryItem({
    required this.text,
    required this.response,
    required this.type,
    required this.time,
  });
}
