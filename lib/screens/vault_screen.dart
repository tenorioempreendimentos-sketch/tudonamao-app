import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../providers/password_provider.dart';
import '../models/password_entry.dart';

// ── Tela de bloqueio do cofre ─────────────────────────────────────────────────
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with WidgetsBindingObserver {
  final _pinCtrl = TextEditingController();
  bool _obscure = true;
  String _error = '';
  String _savedPin = '1234'; // PIN padrão até carregar do SharedPreferences

  static const _kPinKey = 'vault_pin';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregarPin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinCtrl.dispose();
    super.dispose();
  }

  // ── Trava o cofre quando o app vai para background ──────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (mounted) {
        context.read<PasswordProvider>().lock();
        _pinCtrl.clear();
        if (mounted) setState(() => _error = '');
      }
    }
  }

  Future<void> _carregarPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_kPinKey);
    if (mounted) {
      setState(() => _savedPin = pin ?? '1234');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PasswordProvider>();

    if (provider.isUnlocked) {
      return _VaultContent(savedPin: _savedPin, onPinChanged: _onPinChanged);
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone cadeado
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentOrange.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 50),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Cofre Seguro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Digite seu PIN para acessar',
                  style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.6),
                      fontSize: 15),
                ),
                const SizedBox(height: 40),

                // Campo PIN
                TextField(
                  controller: _pinCtrl,
                  obscureText: _obscure,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.white.withValues(alpha: 0.08),
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.3),
                        letterSpacing: 12,
                        fontSize: 28),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: AppColors.accentOrange, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.white.withValues(alpha: 0.5),
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onChanged: (_) => setState(() => _error = ''),
                  onSubmitted: (_) => _unlock(),
                ),

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 16),
                      const SizedBox(width: 6),
                      Text(_error,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13)),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Teclado numérico visual
                _PinKeyboard(
                  onTap: (num) {
                    if (_pinCtrl.text.length < 6) {
                      setState(() {
                        _pinCtrl.text += num;
                        _error = '';
                      });
                    }
                  },
                  onDelete: () {
                    if (_pinCtrl.text.isNotEmpty) {
                      setState(() {
                        _pinCtrl.text = _pinCtrl.text
                            .substring(0, _pinCtrl.text.length - 1);
                      });
                    }
                  },
                  onConfirm: _unlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _unlock() {
    if (_pinCtrl.text == _savedPin) {
      context.read<PasswordProvider>().unlock();
    } else {
      setState(() {
        _error = 'PIN incorreto. Tente novamente.';
        _pinCtrl.clear();
      });
    }
  }

  void _onPinChanged(String newPin) {
    setState(() => _savedPin = newPin);
  }
}

class _PinKeyboard extends StatelessWidget {
  final Function(String) onTap;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  const _PinKeyboard(
      {required this.onTap,
      required this.onDelete,
      required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        ...keys.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((k) => _KeyBtn(label: k, onTap: () => onTap(k))).toList(),
              ),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _KeyBtn(label: '⌫', onTap: onDelete, isAction: true),
            _KeyBtn(label: '0', onTap: () => onTap('0')),
            _KeyBtn(
                label: '✓',
                onTap: onConfirm,
                isAction: true,
                actionColor: AppColors.accentOrange),
          ],
        ),
      ],
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;
  final Color? actionColor;
  const _KeyBtn(
      {required this.label,
      required this.onTap,
      this.isAction = false,
      this.actionColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isAction
              ? (actionColor ?? AppColors.white.withValues(alpha: 0.08))
              : AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isAction
                  ? (actionColor ?? AppColors.white.withValues(alpha: 0.15))
                  : AppColors.white.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isAction && actionColor != null
                  ? actionColor
                  : Colors.white,
              fontSize: label.length > 1 ? 18 : 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Conteúdo do cofre desbloqueado ────────────────────────────────────────────
class _VaultContent extends StatefulWidget {
  final String savedPin;
  final void Function(String) onPinChanged;
  const _VaultContent({required this.savedPin, required this.onPinChanged});
  @override
  State<_VaultContent> createState() => _VaultContentState();
}

class _VaultContentState extends State<_VaultContent> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PasswordProvider>();
    final byCategory = provider.entriesByCategory;
    final entries = _searchQuery.isNotEmpty
        ? provider.search(_searchQuery)
        : (_selectedCategory != null
            ? provider.getByCategory(_selectedCategory!)
            : provider.entries);

    final groupedEntries = <String, List<PasswordEntry>>{};
    for (final e in entries) {
      groupedEntries[e.category] = [...(groupedEntries[e.category] ?? []), e];
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cofre de Senhas'),
        actions: [
          // Botão de troca de PIN
          IconButton(
            icon: const Icon(Icons.pin_outlined,
                color: AppColors.accentOrangeLight),
            tooltip: 'Alterar PIN',
            onPressed: () => _showChangePinDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.lock_open_rounded,
                color: AppColors.accentOrangeLight),
            tooltip: 'Bloquear cofre',
            onPressed: () => provider.lock(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntry(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Senha'),
      ),
      body: Column(
        children: [
          // Barra de busca e categorias
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Busca
                TextField(
                  onChanged: (v) =>
                      setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar senhas...',
                    hintStyle: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.4),
                        fontSize: 14),
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: AppColors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                // Filtros
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CatChip(
                        label: '🔐 Todos (${provider.entries.length})',
                        selected: _selectedCategory == null,
                        onTap: () =>
                            setState(() => _selectedCategory = null),
                      ),
                      ...PasswordProvider.categories
                          .where((c) => byCategory.containsKey(c))
                          .map((c) => _CatChip(
                                label:
                                    '${PasswordProvider.categoryIcons[c]} $c (${byCategory[c]?.length ?? 0})',
                                selected: _selectedCategory == c,
                                onTap: () => setState(
                                    () => _selectedCategory = c),
                              )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de senhas
          Expanded(
            child: provider.entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 72,
                            color: AppColors.textLight.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('Nenhuma senha salva',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.textLight)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddEntry(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar primeira senha'),
                        ),
                      ],
                    ),
                  )
                : entries.isEmpty
                    ? const Center(
                        child: Text('Nenhum resultado encontrado',
                            style: TextStyle(color: AppColors.textLight)))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: groupedEntries.entries.map((entry) {
                          return _CategoryGroup(
                            category: entry.key,
                            entries: entry.value,
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddEntrySheet(),
    );
  }

  // ── Dialog de troca de PIN ────────────────────────────────────────────────
  void _showChangePinDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    String localError = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F2240),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.pin_outlined, color: AppColors.accentOrange, size: 22),
              SizedBox(width: 10),
              Text('Alterar PIN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PinField(
                controller: currentCtrl,
                label: 'PIN atual',
                onChanged: (_) => setDialogState(() => localError = ''),
              ),
              const SizedBox(height: 12),
              _PinField(
                controller: newCtrl,
                label: 'Novo PIN (4–6 dígitos)',
                onChanged: (_) => setDialogState(() => localError = ''),
              ),
              const SizedBox(height: 12),
              _PinField(
                controller: confirmCtrl,
                label: 'Confirmar novo PIN',
                onChanged: (_) => setDialogState(() => localError = ''),
              ),
              if (localError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.danger, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(localError,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF64748b))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final current = currentCtrl.text.trim();
                final novo    = newCtrl.text.trim();
                final conf    = confirmCtrl.text.trim();

                if (current != widget.savedPin) {
                  setDialogState(() => localError = 'PIN atual incorreto.');
                  return;
                }
                if (novo.length < 4) {
                  setDialogState(() => localError = 'O novo PIN deve ter ao menos 4 dígitos.');
                  return;
                }
                if (novo != conf) {
                  setDialogState(() => localError = 'Os PINs não conferem.');
                  return;
                }

                // Salva no SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('vault_pin', novo);
                widget.onPinChanged(novo);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN alterado com sucesso!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Salvar PIN'),
            ),
          ],
        ),
      ),
    );
  }
}

// Campo PIN reutilizável no dialog
class _PinField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  const _PinField({required this.controller, required this.label, this.onChanged});

  @override
  State<_PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<_PinField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: TextInputType.number,
      maxLength: 6,
      onChanged: widget.onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: Color(0xFF64748b), fontSize: 13),
        counterText: '',
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white38,
            size: 18,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentOrange
              : AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected
                    ? Colors.white
                    : AppColors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<PasswordEntry> entries;
  const _CategoryGroup(
      {required this.category, required this.entries});

  @override
  Widget build(BuildContext context) {
    final icon = PasswordProvider.categoryIcons[category] ?? '🔐';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(category,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark)),
              const SizedBox(width: 6),
              Text('(${entries.length})',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight)),
            ],
          ),
        ),
        ...entries.map((e) => _PasswordCard(entry: e)),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _PasswordCard extends StatefulWidget {
  final PasswordEntry entry;
  const _PasswordCard({required this.entry});
  @override
  State<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<_PasswordCard> {
  bool _expanded = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PasswordProvider>();
    final e = widget.entry;
    final icon = PasswordProvider.categoryIcons[e.category] ?? '🔐';

    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => provider.delete(e.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(icon,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textDark)),
                          if (e.username.isNotEmpty)
                            Text(e.username,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_outlined,
                              size: 18, color: AppColors.primaryBlue),
                          tooltip: 'Copiar senha',
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: e.password));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Senha copiada!'),
                                duration: Duration(seconds: 2),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: AppColors.textLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.username.isNotEmpty)
                      _DetailRow(
                        label: 'Usuário / Email',
                        value: e.username,
                        onCopy: () => _copy(context, e.username, 'Usuário copiado!'),
                      ),
                    if (e.password.isNotEmpty)
                      _SecretRow(
                        label: 'Senha',
                        value: e.password,
                        show: _showPassword,
                        onToggle: () =>
                            setState(() => _showPassword = !_showPassword),
                        onCopy: () => _copy(context, e.password, 'Senha copiada!'),
                      ),
                    if (e.extraField1Label.isNotEmpty && e.extraField1Value.isNotEmpty)
                      _DetailRow(
                        label: e.extraField1Label,
                        value: e.extraField1Value,
                        onCopy: () => _copy(context, e.extraField1Value, '${e.extraField1Label} copiado!'),
                      ),
                    if (e.extraField2Label.isNotEmpty && e.extraField2Value.isNotEmpty)
                      _SecretRow(
                        label: e.extraField2Label,
                        value: e.extraField2Value,
                        show: false,
                        onToggle: () {},
                        onCopy: () => _copy(context, e.extraField2Value, '${e.extraField2Label} copiado!'),
                        alwaysHide: e.extraField2Label.toLowerCase().contains('cvv') ||
                            e.extraField2Label.toLowerCase().contains('senha'),
                      ),
                    if (e.extraField3Label.isNotEmpty && e.extraField3Value.isNotEmpty)
                      _DetailRow(
                        label: e.extraField3Label,
                        value: e.extraField3Value,
                        onCopy: () => _copy(context, e.extraField3Value, '${e.extraField3Label} copiado!'),
                      ),
                    if (e.url.isNotEmpty)
                      _DetailRow(
                        label: 'Site / URL',
                        value: e.url,
                        icon: Icons.language_outlined,
                        onCopy: () => _copy(context, e.url, 'URL copiada!'),
                      ),
                    if (e.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes_outlined,
                                size: 14, color: AppColors.textLight),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(e.note,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMedium)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir senha?'),
        content: Text('Deseja excluir "${widget.entry.title}" permanentemente?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback onCopy;
  const _DetailRow({
    required this.label,
    required this.value,
    this.icon = Icons.info_outline,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined,
                size: 16, color: AppColors.primaryBlue),
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _SecretRow extends StatelessWidget {
  final String label, value;
  final bool show;
  final bool alwaysHide;
  final VoidCallback onToggle, onCopy;
  const _SecretRow({
    required this.label,
    required this.value,
    required this.show,
    required this.onToggle,
    required this.onCopy,
    this.alwaysHide = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (!show || alwaysHide) ? '•' * value.length.clamp(6, 12) : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(displayValue,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        letterSpacing: show && !alwaysHide ? 0 : 2)),
              ],
            ),
          ),
          if (!alwaysHide)
            IconButton(
              icon: Icon(show ? Icons.visibility_off : Icons.visibility,
                  size: 16, color: AppColors.textLight),
              onPressed: onToggle,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_outlined,
                size: 16, color: AppColors.primaryBlue),
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Formulário para adicionar senha ──────────────────────────────────────────
class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();
  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _titleCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _extra1Ctrl = TextEditingController();
  final _extra2Ctrl = TextEditingController();
  final _extra3Ctrl = TextEditingController();
  String _category = 'Rede Social';
  bool _obscurePass = true;

  List<Map<String, String>> get _extraFields =>
      PasswordProvider.categoryExtraFields[_category] ?? [];

  @override
  Widget build(BuildContext context) {
    final extras = _extraFields;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  PasswordProvider.categoryIcons[_category] ?? '🔐',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                const Text('Nova Senha',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                  labelText: 'Tipo de conta',
                  prefixIcon: Icon(Icons.category_outlined)),
              items: PasswordProvider.categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(children: [
                          Text(PasswordProvider.categoryIcons[c] ?? '🔐'),
                          const SizedBox(width: 8),
                          Text(c),
                        ]),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Nome (Ex: Instagram, Nubank) *',
                  prefixIcon: Icon(Icons.label_outline)),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                  labelText: 'Usuário / Email / Login',
                  prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Senha / PIN *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (extras.isNotEmpty && extras[0]['label']!.isNotEmpty) ...[
              TextField(
                controller: _extra1Ctrl,
                decoration: InputDecoration(
                    labelText: extras[0]['label'],
                    hintText: extras[0]['hint'],
                    prefixIcon: const Icon(Icons.info_outline)),
              ),
              const SizedBox(height: 12),
            ],
            if (extras.length > 1 && extras[1]['label']!.isNotEmpty) ...[
              TextField(
                controller: _extra2Ctrl,
                decoration: InputDecoration(
                    labelText: extras[1]['label'],
                    hintText: extras[1]['hint'],
                    prefixIcon: const Icon(Icons.info_outline)),
              ),
              const SizedBox(height: 12),
            ],
            if (extras.length > 2 && extras[2]['label']!.isNotEmpty) ...[
              TextField(
                controller: _extra3Ctrl,
                decoration: InputDecoration(
                    labelText: extras[2]['label'],
                    hintText: extras[2]['hint'],
                    prefixIcon: const Icon(Icons.info_outline)),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                  labelText: 'Site / URL (opcional)',
                  prefixIcon: Icon(Icons.language_outlined)),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.notes_outlined)),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar no Cofre'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) return;
    final extras = _extraFields;
    context.read<PasswordProvider>().add(PasswordEntry(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      category: _category,
      username: _userCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      url: _urlCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
      extraField1Label: extras.isNotEmpty ? extras[0]['label'] ?? '' : '',
      extraField1Value: _extra1Ctrl.text.trim(),
      extraField2Label: extras.length > 1 ? extras[1]['label'] ?? '' : '',
      extraField2Value: _extra2Ctrl.text.trim(),
      extraField3Label: extras.length > 2 ? extras[2]['label'] ?? '' : '',
      extraField3Value: _extra3Ctrl.text.trim(),
    ));
    Navigator.pop(context);
  }
}
