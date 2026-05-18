import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../providers/shopping_provider.dart';
import '../models/shopping_item.dart';

// ── Tela principal com menu de grupos ────────────────────────────────────────
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});
  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _ShoppingSearchDelegate(
          context.read<ShoppingProvider>()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Compras Diversas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar item',
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'Ver toda a lista',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FullShoppingListScreen(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _AddItemSheet(),
        ),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Adicionar Item'),
        backgroundColor: AppColors.accentOrange,
      ),
      body: CustomScrollView(
        slivers: [
          // Banner de resumo
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Minha Lista de Compras',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${provider.totalItems} itens • ${provider.checkedItems} comprados',
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                            if (provider.estimatedTotal > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Total estimado: ${fmt.format(provider.estimatedTotal)}',
                                style: const TextStyle(
                                  color: AppColors.accentOrangeLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FullShoppingListScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.shopping_cart_checkout_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                  if (provider.totalItems > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: provider.totalItems > 0
                                  ? provider.checkedItems / provider.totalItems
                                  : 0,
                              backgroundColor:
                                  AppColors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.success),
                              minHeight: 7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${((provider.checkedItems / provider.totalItems) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.checkedItems == provider.totalItems && provider.totalItems > 0
                          ? provider.estimatedTotal > 0
                              ? '✅ Tudo comprado! Total: ${fmt.format(provider.estimatedTotal)}'
                              : '✅ Tudo comprado!'
                          : '${provider.totalItems - provider.checkedItems} item(s) restante(s)',
                      style: TextStyle(
                        color: provider.checkedItems == provider.totalItems && provider.totalItems > 0
                            ? AppColors.accentOrangeLight
                            : AppColors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: provider.checkedItems == provider.totalItems && provider.totalItems > 0
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Acesso rápido - botões de atalho
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionBtn(
                      icon: Icons.list_alt_rounded,
                      label: 'Lista Completa',
                      color: AppColors.primaryBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FullShoppingListScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionBtn(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Já Comprados',
                      color: AppColors.success,
                      badge: provider.checkedItems > 0
                          ? provider.checkedItems
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FullShoppingListScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionBtn(
                      icon: Icons.delete_sweep_rounded,
                      label: 'Limpar ✓',
                      color: AppColors.danger,
                      onTap: provider.checkedItems > 0
                          ? () {
                              provider.clearChecked();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Itens comprados removidos!')),
                              );
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Título dos grupos
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 18, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    'Categorias por Setor',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grid de grupos de categorias
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final groupName =
                    ShoppingProvider.categoryGroups.keys.toList()[i];
                final groupCats =
                    ShoppingProvider.categoryGroups[groupName]!;
                final groupIcon =
                    ShoppingProvider.groupIcons[groupName] ?? '📦';
                final groupColor = Color(
                    ShoppingProvider.groupColors[groupName] ?? 0xFF7F8C8D);

                // Contagem total do grupo
                int groupTotal = 0;
                int groupPending = 0;
                for (final cat in groupCats) {
                  groupTotal += provider.countByCategory(cat);
                  groupPending += provider.countPendingByCategory(cat);
                }

                return _GroupSection(
                  groupName: groupName,
                  groupIcon: groupIcon,
                  groupColor: groupColor,
                  categories: groupCats,
                  provider: provider,
                  groupTotal: groupTotal,
                  groupPending: groupPending,
                );
              },
              childCount: ShoppingProvider.categoryGroups.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ── Botão de ação rápida ─────────────────────────────────────────────────────
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int? badge;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.divider.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled
                ? AppColors.divider
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    size: 22,
                    color: disabled ? AppColors.textLight : color),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge! > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: disabled ? AppColors.textLight : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delegate de busca ────────────────────────────────────────────────────────
class _ShoppingSearchDelegate extends SearchDelegate<String> {
  final ShoppingProvider provider;

  _ShoppingSearchDelegate(this.provider);

  @override
  String get searchFieldLabel => 'Buscar item na lista...';

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final results = query.isEmpty
        ? provider.items
        : provider.items
            .where((item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.category.toLowerCase().contains(query.toLowerCase()))
            .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'Digite para buscar itens'
                  : 'Nenhum item encontrado para "$query"',
              style: const TextStyle(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final item = results[i];
        final groupColor = _getGroupColor(item.category);
        return _ItemTile(
            item: item, color: Color(groupColor), fmt: fmt);
      },
    );
  }

  int _getGroupColor(String category) {
    for (final entry in ShoppingProvider.categoryGroups.entries) {
      if (entry.value.contains(category)) {
        return ShoppingProvider.groupColors[entry.key] ?? 0xFF7F8C8D;
      }
    }
    return 0xFF7F8C8D;
  }
}

// ── Seção de grupo com cards de categoria ────────────────────────────────────
class _GroupSection extends StatefulWidget {
  final String groupName, groupIcon;
  final Color groupColor;
  final List<String> categories;
  final ShoppingProvider provider;
  final int groupTotal, groupPending;

  const _GroupSection({
    required this.groupName,
    required this.groupIcon,
    required this.groupColor,
    required this.categories,
    required this.provider,
    required this.groupTotal,
    required this.groupPending,
  });

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho do grupo
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: widget.groupColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.groupColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(widget.groupIcon,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.groupName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: widget.groupColor,
                          ),
                        ),
                        Text(
                          '${widget.categories.length} categorias'
                          '${widget.groupTotal > 0 ? ' • ${widget.groupPending} item(s) pendente(s)' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.groupColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.groupPending > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.groupColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.groupPending}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: widget.groupColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),

          // Grid de categorias
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: widget.categories.length,
                itemBuilder: (ctx, i) {
                  final cat = widget.categories[i];
                  final icon = ShoppingProvider.categoryIcons[cat] ?? '📦';
                  final total = widget.provider.countByCategory(cat);
                  final pending = widget.provider.countPendingByCategory(cat);

                  return _CategoryCard(
                    category: cat,
                    icon: icon,
                    color: widget.groupColor,
                    total: total,
                    pending: pending,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryShoppingScreen(
                          category: cat,
                          icon: icon,
                          color: widget.groupColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Card de categoria ────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String category, icon;
  final Color color;
  final int total, pending;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.color,
    required this.total,
    required this.pending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = total > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasItems
              ? color.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasItems
                ? color.withValues(alpha: 0.35)
                : AppColors.divider,
            width: hasItems ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      category,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasItems ? color : AppColors.textMedium,
                        height: 1.2,
                      ),
                    ),
                    if (hasItems) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$pending/$total',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Badge de pendentes
            if (pending > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tela de lista por categoria ───────────────────────────────────────────────
class CategoryShoppingScreen extends StatelessWidget {
  final String category, icon;
  final Color color;

  const CategoryShoppingScreen({
    super.key,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final items = provider.getByCategory(category);
    final pending = items.where((i) => !i.isChecked).toList();
    final done = items.where((i) => i.isChecked).toList();

    final estimatedTotal = items
        .where((i) => !i.isChecked && i.estimatedPrice != null)
        .fold<double>(0, (s, i) => s + i.estimatedPrice! * i.quantity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(category),
          ],
        ),
        actions: [
          if (items.any((i) => i.isChecked))
            TextButton(
              onPressed: () => provider.clearChecked(),
              child: const Text('Limpar ✓',
                  style: TextStyle(
                      color: AppColors.accentOrangeLight, fontSize: 12)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItem(context, category),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Adicionar'),
      ),
      body: Column(
        children: [
          // Cabeçalho colorido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              border: Border(
                  bottom: BorderSide(color: color.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pending.length} item(s) a comprar',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (estimatedTotal > 0)
                        Text(
                          'Estimado: ${fmt.format(estimatedTotal)}',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
                  CircularProgressIndicator(
                    value: items.isNotEmpty
                        ? done.length / items.length
                        : 0,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 5,
                  ),
              ],
            ),
          ),

          // Lista de itens
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(icon,
                            style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum item em $category',
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddItem(context, category),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar item'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _ListHeader(
                            label: 'A comprar (${pending.length})',
                            color: color),
                        ...pending.map((item) =>
                            _ItemTile(item: item, color: color, fmt: fmt)),
                        const SizedBox(height: 8),
                      ],
                      if (done.isNotEmpty) ...[
                        _ListHeader(
                            label: 'Comprado (${done.length})',
                            color: AppColors.success),
                        ...done.map((item) => _ItemTile(
                            item: item,
                            color: AppColors.success,
                            fmt: fmt)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddItem(BuildContext context, String preCategory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(preSelectedCategory: preCategory),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _ListHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ShoppingItem item;
  final Color color;
  final NumberFormat fmt;
  const _ItemTile(
      {required this.item, required this.color, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShoppingProvider>();
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.horizontal,
      // Swipe para direita → marcar/desmarcar como comprado
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: item.isChecked ? AppColors.accentOrange : AppColors.success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.isChecked ? Icons.remove_circle_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              item.isChecked ? 'Desmarcar' : 'Comprado!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      // Swipe para esquerda → deletar
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          provider.toggleCheck(item);
          return false; // não remove o widget
        }
        return true; // endToStart → confirma exclusão
      },
      onDismissed: (_) => provider.delete(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: item.isChecked
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isChecked
                ? AppColors.success.withValues(alpha: 0.25)
                : AppColors.divider,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: GestureDetector(
            onTap: () => provider.toggleCheck(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.isChecked ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color:
                      item.isChecked ? AppColors.success : color,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: item.isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color:
                  item.isChecked ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} ${item.unit}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textLight),
              ),
              if (item.note.isNotEmpty) ...[
                const Text(' • ',
                    style: TextStyle(color: AppColors.textLight)),
                Expanded(
                  child: Text(
                    item.note,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                ),
              ],
            ],
          ),
          trailing: item.estimatedPrice != null
              ? Text(
                  fmt.format(item.estimatedPrice! * item.quantity),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: item.isChecked ? AppColors.textLight : color,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ── Lista completa (todas as categorias) ──────────────────────────────────────
class FullShoppingListScreen extends StatefulWidget {
  const FullShoppingListScreen({super.key});
  @override
  State<FullShoppingListScreen> createState() =>
      _FullShoppingListScreenState();
}

class _FullShoppingListScreenState extends State<FullShoppingListScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final byCategory = provider.itemsByCategory;

    final filteredCats = _selectedCategory == null
        ? byCategory.keys.toList()
        : (byCategory.containsKey(_selectedCategory!)
            ? [_selectedCategory!]
            : <String>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lista Completa'),
        actions: [
          if (provider.checkedItems > 0)
            TextButton(
              onPressed: () => _confirmClear(context, provider),
              child: const Text('Limpar ✓',
                  style: TextStyle(
                      color: AppColors.accentOrangeLight, fontSize: 12)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItem(context),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Adicionar'),
      ),
      body: Column(
        children: [
          // Resumo e filtros
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${provider.totalItems} itens • ${provider.checkedItems} comprados',
                      style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                    if (provider.estimatedTotal > 0)
                      Text(
                        '≈ ${fmt.format(provider.estimatedTotal)}',
                        style: const TextStyle(
                            color: AppColors.accentOrangeLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                  ],
                ),
                if (provider.totalItems > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: provider.checkedItems / provider.totalItems,
                      backgroundColor:
                          AppColors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.success),
                      minHeight: 5,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Todas',
                        selected: _selectedCategory == null,
                        onTap: () =>
                            setState(() => _selectedCategory = null),
                      ),
                      ...byCategory.keys.map((c) => _FilterChip(
                            label:
                                '${ShoppingProvider.categoryIcons[c] ?? '📦'} $c',
                            selected: _selectedCategory == c,
                            onTap: () =>
                                setState(() => _selectedCategory = c),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.totalItems == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 72,
                            color:
                                AppColors.textLight.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('Lista vazia',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.textLight)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddItem(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar item'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: filteredCats.length,
                    itemBuilder: (ctx, i) {
                      final cat = filteredCats[i];
                      final catItems = byCategory[cat] ?? [];
                      final color = Color(_getGroupColor(cat));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Row(
                              children: [
                                Text(
                                    ShoppingProvider.categoryIcons[cat] ??
                                        '📦',
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(cat,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: color)),
                                const SizedBox(width: 8),
                                Text(
                                    '(${catItems.where((i) => !i.isChecked).length}/${catItems.length})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight)),
                              ],
                            ),
                          ),
                          ...catItems.map((item) => _ItemTile(
                              item: item, color: color, fmt: fmt)),
                          const SizedBox(height: 4),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _getGroupColor(String category) {
    for (final entry in ShoppingProvider.categoryGroups.entries) {
      if (entry.value.contains(category)) {
        return ShoppingProvider.groupColors[entry.key] ?? 0xFF7F8C8D;
      }
    }
    return 0xFF7F8C8D;
  }

  void _showAddItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddItemSheet(),
    );
  }

  void _confirmClear(BuildContext context, ShoppingProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Limpar itens comprados?'),
        content: Text(
            'Serão removidos ${provider.checkedItems} itens já marcados.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              provider.clearChecked();
              Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentOrange
              : AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.accentOrange
                : AppColors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected
                    ? Colors.white
                    : AppColors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

// ── Formulário de adição ──────────────────────────────────────────────────────
class _AddItemSheet extends StatefulWidget {
  final String? preSelectedCategory;
  const _AddItemSheet({this.preSelectedCategory});
  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late String _category;
  String _unit = 'un';

  final _units = ['un', 'kg', 'g', 'L', 'ml', 'cx', 'pct', 'dz', 'm', 'm²', 'rolo', 'saco'];

  @override
  void initState() {
    super.initState();
    _category =
        widget.preSelectedCategory ?? ShoppingProvider.categories.first;
  }

  @override
  Widget build(BuildContext context) {
    final catColor = Color(_getGroupColor(_category));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ShoppingProvider.categoryIcons[_category] ?? '📦',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Adicionar Item',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Nome do item *',
                  prefixIcon: Icon(Icons.shopping_basket_outlined)),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined)),
              isExpanded: true,
              items: ShoppingProvider.categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Text(ShoppingProvider.categoryIcons[c] ?? '📦',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(c,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Qtd'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration:
                        const InputDecoration(labelText: 'Unid.'),
                    items: _units
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Preço est.',
                        prefixText: 'R\$ '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Observação (marca, tamanho...)',
                  prefixIcon: Icon(Icons.notes_outlined)),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Adicionar à Lista'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getGroupColor(String category) {
    for (final entry in ShoppingProvider.categoryGroups.entries) {
      if (entry.value.contains(category)) {
        return ShoppingProvider.groupColors[entry.key] ?? 0xFF7F8C8D;
      }
    }
    return 0xFF7F8C8D;
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    context.read<ShoppingProvider>().add(ShoppingItem(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      category: _category,
      quantity:
          double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 1,
      unit: _unit,
      estimatedPrice: _priceCtrl.text.isNotEmpty
          ? double.tryParse(_priceCtrl.text.replaceAll(',', '.'))
          : null,
      note: _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }
}
