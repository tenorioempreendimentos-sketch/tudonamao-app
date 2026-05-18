import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  // Chave injetada via --dart-define=GROQ_API_KEY=xxx no build (APK/web)
  // Para builds locais, configure a variável de ambiente GROQ_API_KEY
  static const String _apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model   = 'llama-3.1-8b-instant'; // substituto do llama3-8b-8192

  static const String _systemPrompt =
      '''Você é o Assistente IA do TudoNaMão, um app de organização pessoal brasileiro.

Seu papel é ajudar o usuário a entender suas finanças, tarefas e agenda de forma clara e direta.

Regras:
- Responda SEMPRE em português brasileiro
- Seja direto, amigável e prático
- Use emojis com moderação para deixar a conversa mais leve
- Quando tiver dados do app, analise-os e dê insights úteis
- Quando o usuário perguntar sobre finanças pessoais em geral, dê dicas práticas
- Nunca invente dados que não foram fornecidos
- Mantenha respostas concisas (máximo 3-4 parágrafos)
- Se o usuário perguntar algo fora do seu escopo, redirecione gentilmente para finanças/organização pessoal''';

  static Future<String> enviarMensagem({
    required String mensagem,
    required List<Map<String, String>> historico,
    required Map<String, dynamic> contextoApp,
  }) async {
    final contextoStr = _montarContexto(contextoApp);

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      if (contextoStr.isNotEmpty)
        {'role': 'system', 'content': 'Dados atuais do app do usuário:\n$contextoStr'},
      ...historico,
      {'role': 'user', 'content': mensagem},
    ];

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 512,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String;
      } else if (response.statusCode == 429) {
        throw Exception('_LIMITE_ATINGIDO_');
      } else if (response.statusCode == 401) {
        throw Exception('_CHAVE_INVALIDA_');
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error']?['message'] ?? 'Erro ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('_TIMEOUT_');
      }
      rethrow;
    }
  }

  static String _montarContexto(Map<String, dynamic> ctx) {
    if (ctx.isEmpty) return '';
    final buf = StringBuffer();

    if (ctx['saldo'] != null) {
      buf.writeln('💰 Saldo atual: R\$ ${ctx['saldo']}');
    }
    if (ctx['totalReceitas'] != null) {
      buf.writeln('📈 Total de receitas do mês: R\$ ${ctx['totalReceitas']}');
    }
    if (ctx['totalDespesas'] != null) {
      buf.writeln('📉 Total de despesas do mês: R\$ ${ctx['totalDespesas']}');
    }
    if (ctx['totalAReceber'] != null && ctx['totalAReceber'] != '0,00') {
      buf.writeln('⏳ A receber: R\$ ${ctx['totalAReceber']}');
    }
    if (ctx['categoriasTop'] != null) {
      buf.writeln('🏷️ Maiores categorias de despesa: ${ctx['categoriasTop']}');
    }
    if (ctx['tarefasPendentes'] != null) {
      buf.writeln('✅ Tarefas pendentes: ${ctx['tarefasPendentes']}');
    }
    if (ctx['tarefasUrgentes'] != null && ctx['tarefasUrgentes'] != '0') {
      buf.writeln('🚨 Tarefas urgentes: ${ctx['tarefasUrgentes']}');
    }
    if (ctx['proximosEventos'] != null) {
      buf.writeln('📅 Próximos eventos: ${ctx['proximosEventos']}');
    }
    if (ctx['mesAno'] != null) {
      buf.writeln('📆 Mês de referência: ${ctx['mesAno']}');
    }

    return buf.toString();
  }
}
