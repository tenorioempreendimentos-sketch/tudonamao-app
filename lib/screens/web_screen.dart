import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});
  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = 'https://tudonamao-site-production.up.railway.app';
  double _loadingProgress = 0;

  final List<Map<String, String>> _quickLinks = [
    {'label': 'Início', 'url': 'https://tudonamao-site-production.up.railway.app'},
    {'label': 'Download', 'url': 'https://tudonamao-site-production.up.railway.app/download/apk'},
    {'label': 'Privacidade', 'url': 'https://tudonamao-site-production.up.railway.app/privacidade.html'},
    {'label': 'Suporte', 'url': 'https://wa.me/5521965918527?text=Olá,%20preciso%20de%20ajuda%20com%20o%20TudoNaMão'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _loadingProgress = progress / 100);
          },
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          },
          onWebResourceError: (error) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Meu Site', style: TextStyle(fontSize: 16)),
            Text(
              _currentUrl.length > 40
                  ? '${_currentUrl.substring(0, 40)}...'
                  : _currentUrl,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: () => _showUrlDialog(),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: AppColors.primaryDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentOrange),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Links rápidos
          Container(
            height: 44,
            color: AppColors.primaryDark,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _quickLinks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final link = _quickLinks[i];
                return GestureDetector(
                  onTap: () {
                    _controller.loadRequest(Uri.parse(link['url']!));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.accentOrange.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      link['label']!,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          // Barra de navegação
          Container(
            height: 52,
            color: AppColors.primaryDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () async {
                    if (await _controller.canGoBack()) _controller.goBack();
                  },
                ),
                _NavBtn(
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: () async {
                    if (await _controller.canGoForward()) _controller.goForward();
                  },
                ),
                _NavBtn(
                  icon: Icons.home_rounded,
                  onTap: () => _controller.loadRequest(
                      Uri.parse('https://tudonamao-site-production.up.railway.app')),
                ),
                _NavBtn(
                  icon: Icons.refresh_rounded,
                  onTap: () => _controller.reload(),
                ),
                _NavBtn(
                  icon: Icons.language_rounded,
                  onTap: _showUrlDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog() {
    final ctrl = TextEditingController(text: _currentUrl);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Abrir URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Endereço do site',
            prefixIcon: Icon(Icons.language_rounded),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              var url = ctrl.text.trim();
              if (!url.startsWith('http')) url = 'https://$url';
              _controller.loadRequest(Uri.parse(url));
              Navigator.pop(context);
            },
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppColors.white.withValues(alpha: 0.8), size: 20),
      onPressed: onTap,
    );
  }
}
