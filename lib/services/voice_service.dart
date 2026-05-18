/// Resultado de um comando de voz interpretado
class VoiceCommand {
  final VoiceCommandType type;
  final Map<String, dynamic> params;
  final String rawText;
  final String responseText;

  const VoiceCommand({
    required this.type,
    required this.params,
    required this.rawText,
    required this.responseText,
  });
}

enum VoiceCommandType {
  agendarCompromisso,
  adicionarCompra,
  adicionarReceita,
  adicionarDespesa,
  consultarSaldo,
  consultarAgenda,
  consultarCompras,
  criarTarefa,
  ajuda,
  desconhecido,
}

/// Serviço de processamento de comandos de voz
/// Interpreta texto reconhecido e mapeia para ações do app
class VoiceService {
  // ── Palavras-chave por intenção ──────────────────────────────────────────

  static const _keywordsAgendar = [
    'agendar', 'agende', 'marcar', 'marque', 'criar compromisso',
    'novo compromisso', 'criar evento', 'novo evento', 'reunião',
    'consulta', 'compromisso', 'lembrar', 'lembrete',
  ];

  static const _keywordsCompra = [
    'adicionar', 'adicione', 'comprar', 'compra', 'colocar na lista',
    'lista de compras', 'preciso de', 'preciso comprar', 'falta',
    'colocar', 'anotar', 'anote', 'incluir',
  ];

  static const _keywordsReceita = [
    'receita', 'recebi', 'ganhei', 'entrada', 'salário',
    'pagamento recebido', 'recebi pagamento', 'entrou',
  ];

  static const _keywordsDespesa = [
    'despesa', 'gasto', 'gastei', 'paguei', 'saída', 'pagar',
    'conta', 'débito', 'comprei', 'saiu',
  ];

  static const _keywordsSaldo = [
    'saldo', 'quanto tenho', 'quanto gastei', 'quanto recebi',
    'meu dinheiro', 'finanças', 'balanço', 'quanto sobrou',
    'situação financeira',
  ];

  static const _keywordsAgenda = [
    'minha agenda', 'meus compromissos', 'o que tenho', 'compromissos de hoje',
    'agenda de hoje', 'o que está marcado', 'próximos eventos',
    'próximos compromissos',
  ];

  static const _keywordsListaCompras = [
    'minha lista', 'lista de compras', 'o que falta comprar',
    'itens da lista', 'ver lista', 'mostrar lista',
  ];

  static const _keywordsTarefa = [
    'tarefa urgente', 'urgente', 'tarefa', 'lembrar urgente',
    'não esquecer', 'importante', 'criar tarefa',
  ];

  static const _keywordsAjuda = [
    'ajuda', 'help', 'o que posso', 'comandos', 'o que você faz',
    'como usar', 'o que sabe fazer',
  ];

  // ── Dias da semana ───────────────────────────────────────────────────────

  static const _diasSemana = {
    'segunda': 1, 'segunda-feira': 1,
    'terça': 2, 'terca': 2, 'terça-feira': 2,
    'quarta': 3, 'quarta-feira': 3,
    'quinta': 4, 'quinta-feira': 4,
    'sexta': 5, 'sexta-feira': 5,
    'sábado': 6, 'sabado': 6,
    'domingo': 7,
  };

  static const _meses = {
    'janeiro': 1, 'fevereiro': 2, 'março': 3, 'marco': 3,
    'abril': 4, 'maio': 5, 'junho': 6,
    'julho': 7, 'agosto': 8, 'setembro': 9,
    'outubro': 10, 'novembro': 11, 'dezembro': 12,
  };

  // ── Método principal: interpreta o texto ────────────────────────────────

  static VoiceCommand interpret(String rawText) {
    final text = rawText.toLowerCase().trim();

    // Ajuda
    if (_matchesAny(text, _keywordsAjuda)) {
      return VoiceCommand(
        type: VoiceCommandType.ajuda,
        params: {},
        rawText: rawText,
        responseText: _helpText(),
      );
    }

    // Consultar saldo / finanças
    if (_matchesAny(text, _keywordsSaldo)) {
      return VoiceCommand(
        type: VoiceCommandType.consultarSaldo,
        params: {},
        rawText: rawText,
        responseText: 'Abrindo suas finanças...',
      );
    }

    // Consultar agenda
    if (_matchesAny(text, _keywordsAgenda)) {
      return VoiceCommand(
        type: VoiceCommandType.consultarAgenda,
        params: {},
        rawText: rawText,
        responseText: 'Abrindo sua agenda...',
      );
    }

    // Consultar lista de compras
    if (_matchesAny(text, _keywordsListaCompras)) {
      return VoiceCommand(
        type: VoiceCommandType.consultarCompras,
        params: {},
        rawText: rawText,
        responseText: 'Abrindo sua lista de compras...',
      );
    }

    // Adicionar receita
    if (_matchesAny(text, _keywordsReceita)) {
      final params = _extrairValorETitulo(text);
      final titulo = params['titulo'] as String? ?? 'Receita';
      final valor = params['valor'] as double?;
      return VoiceCommand(
        type: VoiceCommandType.adicionarReceita,
        params: params,
        rawText: rawText,
        responseText: valor != null
            ? 'Adicionando receita "$titulo" de R\$ ${valor.toStringAsFixed(2)}...'
            : 'Adicionando receita "$titulo"...',
      );
    }

    // Adicionar despesa
    if (_matchesAny(text, _keywordsDespesa)) {
      final params = _extrairValorETitulo(text);
      final titulo = params['titulo'] as String? ?? 'Despesa';
      final valor = params['valor'] as double?;
      return VoiceCommand(
        type: VoiceCommandType.adicionarDespesa,
        params: params,
        rawText: rawText,
        responseText: valor != null
            ? 'Adicionando despesa "$titulo" de R\$ ${valor.toStringAsFixed(2)}...'
            : 'Adicionando despesa "$titulo"...',
      );
    }

    // Agendar compromisso
    if (_matchesAny(text, _keywordsAgendar)) {
      final params = _extrairDadosCompromisso(text);
      final titulo = params['titulo'] as String? ?? 'Compromisso';
      final dataStr = params['dataFormatada'] as String? ?? '';
      return VoiceCommand(
        type: VoiceCommandType.agendarCompromisso,
        params: params,
        rawText: rawText,
        responseText: dataStr.isNotEmpty
            ? 'Agendando "$titulo" para $dataStr...'
            : 'Criando compromisso "$titulo"...',
      );
    }

    // Tarefa urgente
    if (_matchesAny(text, _keywordsTarefa)) {
      final titulo = _extrairTituloSimples(text, _keywordsTarefa);
      return VoiceCommand(
        type: VoiceCommandType.criarTarefa,
        params: {'titulo': titulo},
        rawText: rawText,
        responseText: 'Criando tarefa urgente "$titulo"...',
      );
    }

    // Adicionar item de compra
    if (_matchesAny(text, _keywordsCompra)) {
      final params = _extrairItemCompra(text);
      final nome = params['nome'] as String? ?? 'Item';
      final qtd = params['quantidade'] as double? ?? 1.0;
      return VoiceCommand(
        type: VoiceCommandType.adicionarCompra,
        params: params,
        rawText: rawText,
        responseText: qtd > 1
            ? 'Adicionando ${qtd.toStringAsFixed(0)}x "$nome" à lista...'
            : 'Adicionando "$nome" à lista de compras...',
      );
    }

    // Desconhecido
    return VoiceCommand(
      type: VoiceCommandType.desconhecido,
      params: {},
      rawText: rawText,
      responseText: 'Não entendi o comando. Diga "ajuda" para ver o que posso fazer.',
    );
  }

  // ── Extratores ──────────────────────────────────────────────────────────

  /// Extrai dados de um compromisso do texto
  static Map<String, dynamic> _extrairDadosCompromisso(String text) {
    final result = <String, dynamic>{};

    // Extrair hora
    final horaRegex = RegExp(r'(\d{1,2})[h:]\s?(\d{0,2})', caseSensitive: false);
    final horaMatch = horaRegex.firstMatch(text);
    String timeStr = '08:00';
    if (horaMatch != null) {
      final h = int.tryParse(horaMatch.group(1) ?? '8') ?? 8;
      final m = int.tryParse(horaMatch.group(2) ?? '0') ?? 0;
      timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      result['hora'] = timeStr;
    }

    // Extrair data
    final now = DateTime.now();
    DateTime targetDate = now;
    String dataFormatada = '';

    if (text.contains('hoje')) {
      targetDate = now;
      dataFormatada = 'hoje às $timeStr';
    } else if (text.contains('amanhã') || text.contains('amanha')) {
      targetDate = now.add(const Duration(days: 1));
      dataFormatada = 'amanhã às $timeStr';
    } else if (text.contains('depois de amanhã') || text.contains('depois de amanha')) {
      targetDate = now.add(const Duration(days: 2));
      dataFormatada = 'depois de amanhã às $timeStr';
    } else {
      // Dia da semana
      for (final entry in _diasSemana.entries) {
        if (text.contains(entry.key)) {
          final diasAteProximo = _diasAteProximo(now.weekday, entry.value);
          targetDate = now.add(Duration(days: diasAteProximo));
          dataFormatada = '${entry.key} às $timeStr';
          break;
        }
      }
      // Dia/mês numérico: "dia 15", "15 de março"
      if (dataFormatada.isEmpty) {
        final diaRegex = RegExp(r'dia\s+(\d{1,2})', caseSensitive: false);
        final diaMatch = diaRegex.firstMatch(text);
        if (diaMatch != null) {
          final dia = int.tryParse(diaMatch.group(1) ?? '') ?? now.day;
          int mes = now.month;
          for (final m in _meses.entries) {
            if (text.contains(m.key)) { mes = m.value; break; }
          }
          targetDate = DateTime(now.year, mes, dia);
          if (targetDate.isBefore(now)) {
            targetDate = DateTime(now.year + 1, mes, dia);
          }
          dataFormatada = 'dia $dia/${mes.toString().padLeft(2, '0')} às $timeStr';
        }
      }
    }

    result['data'] = targetDate;
    result['dataFormatada'] = dataFormatada;
    result['time'] = timeStr;

    // Extrair título: remover palavras-chave e info de data/hora
    String titulo = text;
    for (final kw in _keywordsAgendar) {
      titulo = titulo.replaceAll(kw, '');
    }
    titulo = titulo
        .replaceAll(RegExp(r'\d{1,2}[h:]\d{0,2}'), '')
        .replaceAll(RegExp(r'hoje|amanhã|amanha|depois de amanhã'), '')
        .replaceAll(RegExp(r'às|as|para|no dia|dia'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    for (final entry in _diasSemana.keys) {
      titulo = titulo.replaceAll(entry, '');
    }
    for (final m in _meses.keys) {
      titulo = titulo.replaceAll(m, '');
    }

    titulo = titulo.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (titulo.isEmpty || titulo.length < 2) titulo = 'Compromisso';
    result['titulo'] = _capitalize(titulo);

    return result;
  }

  /// Extrai item de compra do texto
  static Map<String, dynamic> _extrairItemCompra(String text) {
    String nome = text;
    for (final kw in _keywordsCompra) {
      nome = nome.replaceAll(kw, '');
    }

    // Extrair quantidade
    double quantidade = 1.0;
    String unit = 'un';
    final qtdRegex = RegExp(
      r'(\d+[\.,]?\d*)\s*(kg|kilo|kilos|g|gramas|litro|litros|l|pacote|pacotes|caixa|caixas|un|unidades?)?',
      caseSensitive: false,
    );
    final qtdMatch = qtdRegex.firstMatch(nome);
    if (qtdMatch != null) {
      quantidade = double.tryParse(
        qtdMatch.group(1)?.replaceAll(',', '.') ?? '1',
      ) ?? 1.0;
      final u = qtdMatch.group(2)?.toLowerCase() ?? '';
      if (u.startsWith('kg') || u.startsWith('kilo')) {
        unit = 'kg';
      } else if (u == 'g' || u.startsWith('grama')) {
        unit = 'g';
      } else if (u.startsWith('litro') || u == 'l') {
        unit = 'L';
      } else if (u.startsWith('pacote')) {
        unit = 'pct';
      } else if (u.startsWith('caixa')) {
        unit = 'cx';
      }
      nome = nome.replaceAll(qtdMatch.group(0) ?? '', '');
    }

    // Preço
    double? preco;
    final precoRegex = RegExp(r'r\$?\s*(\d+[\.,]?\d*)', caseSensitive: false);
    final precoMatch = precoRegex.firstMatch(nome);
    if (precoMatch != null) {
      preco = double.tryParse(
        precoMatch.group(1)?.replaceAll(',', '.') ?? '',
      );
      nome = nome.replaceAll(precoMatch.group(0) ?? '', '');
    }

    nome = nome
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^(de|o|a|os|as|um|uma)\s+'), '')
        .trim();
    if (nome.isEmpty) nome = 'Item';

    return {
      'nome': _capitalize(nome),
      'quantidade': quantidade,
      'unit': unit,
      'preco': preco,
      'categoria': _detectarCategoria(nome),
    };
  }

  /// Extrai valor e título de uma transação financeira
  static Map<String, dynamic> _extrairValorETitulo(String text) {
    // Valor monetário
    double? valor;
    final regexes = [
      RegExp(r'r\$\s*(\d+[\.,]?\d*)', caseSensitive: false),
      RegExp(r'(\d+[\.,]?\d*)\s*reais', caseSensitive: false),
      RegExp(r'(\d{3,}[\.,]?\d*)', caseSensitive: false),
    ];
    for (final r in regexes) {
      final m = r.firstMatch(text);
      if (m != null) {
        valor = double.tryParse(m.group(1)?.replaceAll(',', '.') ?? '');
        if (valor != null) break;
      }
    }

    // Título
    String titulo = text;
    for (final kw in [..._keywordsReceita, ..._keywordsDespesa]) {
      titulo = titulo.replaceAll(kw, '');
    }
    titulo = titulo
        .replaceAll(RegExp(r'r\$\s*\d+[\.,]?\d*'), '')
        .replaceAll(RegExp(r'\d+[\.,]?\d*\s*reais'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (titulo.isEmpty || titulo.length < 2) titulo = 'Lançamento';

    return {
      'titulo': _capitalize(titulo),
      'valor': valor,
    };
  }

  /// Extrai título simples removendo palavras-chave
  static String _extrairTituloSimples(String text, List<String> keywords) {
    String titulo = text;
    for (final kw in keywords) {
      titulo = titulo.replaceAll(kw, '');
    }
    titulo = titulo.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (titulo.isEmpty || titulo.length < 2) titulo = 'Tarefa';
    return _capitalize(titulo);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  static int _diasAteProximo(int hoje, int alvo) {
    int diff = alvo - hoje;
    if (diff <= 0) diff += 7;
    return diff;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _detectarCategoria(String nome) {
    final n = nome.toLowerCase();
    if (_matchesAny(n, ['arroz', 'feijão', 'feijao', 'macarrão', 'farinha', 'açúcar', 'sal', 'óleo', 'azeite', 'molho'])) return 'Mercearia';
    if (_matchesAny(n, ['frango', 'carne', 'bife', 'costela', 'linguiça', 'salsicha', 'bacon'])) return 'Açougue';
    if (_matchesAny(n, ['leite', 'queijo', 'iogurte', 'manteiga', 'nata', 'creme'])) return 'Laticínios';
    if (_matchesAny(n, ['pão', 'bolo', 'biscoito', 'bolacha'])) return 'Padaria';
    if (_matchesAny(n, ['alface', 'tomate', 'cebola', 'alho', 'batata', 'cenoura', 'couve', 'brócolis', 'fruta', 'maçã', 'banana'])) return 'Hortifruti';
    if (_matchesAny(n, ['shampoo', 'sabonete', 'creme', 'desodorante', 'escova', 'pasta', 'fio dental'])) return 'Higiene Pessoal';
    if (_matchesAny(n, ['detergente', 'sabão', 'amaciante', 'água sanitária', 'vassoura', 'esponja'])) return 'Limpeza';
    if (_matchesAny(n, ['remédio', 'medicamento', 'vitamina', 'pomada', 'band-aid'])) return 'Farmácia';
    if (_matchesAny(n, ['refrigerante', 'suco', 'água', 'cerveja', 'vinho', 'bebida'])) return 'Bebidas';
    return 'Supermercado';
  }

  static String _helpText() => '''Posso ajudar com:

📅 AGENDA
• "Agendar reunião amanhã às 14h"
• "Marcar consulta sexta às 9h"
• "Compromisso com João dia 20"

🛒 COMPRAS
• "Adicionar arroz na lista"
• "Comprar 2kg de feijão"
• "Preciso de leite e pão"

💰 FINANÇAS
• "Recebi R\$500 de salário"
• "Gastei R\$80 no mercado"
• "Quanto é meu saldo?"

⚡ TAREFAS
• "Tarefa urgente ligar pro banco"
• "Não esquecer pagar conta de luz"

📊 CONSULTAS
• "Minha agenda de hoje"
• "Minha lista de compras"
• "Minha situação financeira"''';
}
