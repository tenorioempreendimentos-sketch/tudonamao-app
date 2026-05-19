import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class UpdateService {
  static const String _versionUrl =
      'https://tudonamao-site-production.up.railway.app/api/version';

  // Caminho do APK salvo — reutilizado se já baixado
  static String? _apkPathCached;

  /// Verifica se há atualização e exibe dialog se houver.
  /// [silencioso] = true → sem feedback quando já está atualizado (uso no startup)
  /// [silencioso] = false → mostra resultado sempre (uso no botão manual)
  static Future<void> checarAtualizacao(
    BuildContext context, {
    bool silencioso = true,
  }) async {
    // Só funciona em Android
    if (!Platform.isAndroid) return;

    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        if (!silencioso && context.mounted) {
          _mostrarSnackbar(context,
              '⚠️ Servidor indisponível (${response.statusCode}). Tente novamente.',
              erro: true);
        }
        return;
      }

      final data = json.decode(response.body);
      final int buildRemoto = (data['build'] as num).toInt();
      final String versaoRemota = data['version'] ?? '';
      final bool obrigatorio = data['obrigatorio'] ?? false;
      final String urlDownload = data['url_download'] ??
          'https://tudonamao-site-production.up.railway.app/download/apk';
      final List<String> novidades =
          List<String>.from(data['novidades'] ?? []);

      final info = await PackageInfo.fromPlatform();
      final int buildInstalado = int.tryParse(info.buildNumber) ?? 1;

      // Sem atualização disponível
      if (buildRemoto <= buildInstalado) {
        if (!silencioso && context.mounted) {
          _mostrarSnackbar(context,
              '✅ Você já está na versão mais recente (v${info.version})');
        }
        return;
      }

      if (!context.mounted) return;
      await _mostrarDialog(
        context: context,
        versaoRemota: versaoRemota,
        obrigatorio: obrigatorio,
        urlDownload: urlDownload,
        novidades: novidades,
      );
    } catch (_) {
      // No modo automático (startup) falha silenciosamente
      if (!silencioso && context.mounted) {
        _mostrarSnackbar(context,
            '📵 Sem conexão. Verifique sua internet e tente novamente.',
            erro: true);
      }
    }
  }

  /// Exibe um SnackBar simples com mensagem de resultado.
  static void _mostrarSnackbar(BuildContext context, String msg,
      {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: erro ? const Color(0xFFdc2626) : const Color(0xFF16a34a),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Verifica permissão de instalar apps desconhecidos.
  /// No Android 8+ (API 26+) é necessário consentimento explícito do usuário.
  static Future<bool> _verificarPermissaoInstalacao(
      BuildContext context) async {
    // Abaixo do Android 8 não precisa de permissão extra
    if (!Platform.isAndroid) return true;

    final status = await Permission.requestInstallPackages.status;

    if (status.isGranted) return true;

    // Permissão não concedida — mostrar dialog explicativo
    if (!context.mounted) return false;

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: const Row(
          children: [
            Text('🔒', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Permissão necessária',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Para instalar a atualização, o Android precisa da sua '
          'autorização para "Instalar apps desconhecidos".\n\n'
          'Clique em Ir para Configurações, ative a opção e '
          'volte ao app — a instalação continuará automaticamente.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ir para Configurações'),
          ),
        ],
      ),
    );

    if (confirmar != true) return false;

    // Abre a tela de configurações de "Instalar apps desconhecidos"
    await openAppSettings();

    // Aguarda o usuário voltar (pequeno delay para o sistema processar)
    await Future.delayed(const Duration(milliseconds: 800));

    // Verifica novamente após retornar das configurações
    final novoStatus = await Permission.requestInstallPackages.status;
    return novoStatus.isGranted;
  }

  /// Baixa o APK com barra de progresso e abre o instalador nativo do Android.
  static Future<void> _baixarEInstalar({
    required BuildContext context,
    required String urlDownload,
  }) async {
    // 1. Verificar permissão ANTES de baixar
    final temPermissao = await _verificarPermissaoInstalacao(context);
    if (!temPermissao) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ Permissão negada. Ative "Instalar apps desconhecidos" nas configurações.'),
            backgroundColor: Color(0xFFf97316),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // 2. Verificar se APK já foi baixado anteriormente
    final dir = await getTemporaryDirectory();
    final apkPath = '${dir.path}/tudonamao_update.apk';
    final file = File(apkPath);

    if (_apkPathCached != null &&
        File(_apkPathCached!).existsSync() &&
        File(_apkPathCached!).lengthSync() > 1024 * 1024) {
      // APK já baixado — ir direto para instalação
      if (context.mounted) await _abrirInstalador(context, _apkPathCached!);
      return;
    }

    // 3. Mostrar dialog de progresso com ValueNotifier para atualização real
    final progressoNotifier = ValueNotifier<double>(0);
    bool cancelado = false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚀', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text(
                'Baixando atualização...',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<double>(
                valueListenable: progressoNotifier,
                builder: (_, val, __) => Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: val,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFf97316)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(val * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  cancelado = true;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancelar',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 4. Download com progresso real
      final request = http.Request('GET', Uri.parse(urlDownload));
      final streamedResponse = await http.Client()
          .send(request)
          .timeout(const Duration(minutes: 5));

      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in streamedResponse.stream) {
        if (cancelado) {
          await sink.close();
          if (file.existsSync()) file.deleteSync();
          progressoNotifier.dispose();
          return;
        }
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          progressoNotifier.value = receivedBytes / totalBytes;
        }
      }
      await sink.flush();
      await sink.close();

      if (cancelado) {
        if (file.existsSync()) file.deleteSync();
        progressoNotifier.dispose();
        return;
      }

      // 5. Fechar dialog de progresso
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progressoNotifier.dispose();

      // 6. Cache do caminho e abrir instalador
      _apkPathCached = apkPath;
      if (context.mounted) await _abrirInstalador(context, apkPath);
    } catch (e) {
      // Fechar dialog de progresso se ainda aberto
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '❌ Erro ao baixar atualização. Verifique sua conexão e tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      progressoNotifier.dispose();
      if (kDebugMode) debugPrint('UpdateService download error: $e');
    }
  }

  /// Abre o instalador nativo do Android para o APK baixado.
  static Future<void> _abrirInstalador(
      BuildContext context, String apkPath) async {
    final result = await OpenFile.open(
      apkPath,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done && context.mounted) {
      // Se ainda falhar, mostrar mensagem clara
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.contains('Permission')
                ? '⚠️ Permissão negada pelo Android. Vá em Configurações > Apps > TudoNaMão > Instalar apps desconhecidos.'
                : '❌ Erro ao abrir instalador: ${result.message}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  static Future<void> _mostrarDialog({
    required BuildContext context,
    required String versaoRemota,
    required bool obrigatorio,
    required String urlDownload,
    required List<String> novidades,
  }) async {
    // Segurança: nunca bloqueia o app indefinidamente.
    // Mesmo que obrigatorio=true, o usuário pode fechar tocando fora
    // (o app pode não funcionar 100% sem atualizar, mas não trava).
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PopScope(
        canPop: true,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header laranja
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFf97316),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const Text('🚀', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    const Text(
                      'Nova versão disponível!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v$versaoRemota',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Novidades
              if (novidades.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'O que há de novo:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1e293b)),
                      ),
                      const SizedBox(height: 10),
                      ...novidades.map(
                        (n) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: Color(0xFFf97316),
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  n,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Aviso obrigatório
              if (obrigatorio)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfef2f2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFfecaca)),
                    ),
                    child: const Row(
                      children: [
                        Text('⚠️', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Atualização obrigatória — necessária para continuar.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFdc2626),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Botões
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFf97316),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _baixarEInstalar(
                            context: context,
                            urlDownload: urlDownload,
                          );
                        },
                        child: const Text(
                          '⬇️  Baixar e instalar',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    if (!obrigatorio) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF94a3b8),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Agora não',
                              style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
