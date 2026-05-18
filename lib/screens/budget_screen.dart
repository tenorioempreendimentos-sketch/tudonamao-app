import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';

// ── Tela principal de Orçamentos ─────────────────────────────────────────────
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Orçamentos'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.accentOrange,
          labelColor: AppColors.accentOrange,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          tabs: [
            Tab(
              icon: const Icon(Icons.send_rounded, size: 18),
              text: 'Meus Orçamentos (${provider.emitidos.length})',
            ),
            Tab(
              icon: const Icon(Icons.inbox_rounded, size: 18),
              text: 'Recebidos (${provider.recebidos.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTypeSelection(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
        backgroundColor: AppColors.accentOrange,
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _EmitidosTab(fmt: fmt),
          _RecebidosTab(fmt: fmt),
        ],
      ),
    );
  }

  // Diálogo de seleção do tipo de orçamento
  void _showTypeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Qual tipo de orçamento?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escolha como deseja registrar este orçamento',
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Opção 1 — Emitir orçamento
            _TypeOptionCard(
              icon: Icons.send_rounded,
              color: AppColors.primaryBlue,
              title: 'Fazer um Orçamento',
              subtitle:
                  'Você é o prestador de serviço.\nCrie um orçamento para enviar ao seu cliente.',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddBudgetScreen(type: 'emitido')),
                );
              },
            ),
            const SizedBox(height: 14),

            // Opção 2 — Receber orçamento
            _TypeOptionCard(
              icon: Icons.inbox_rounded,
              color: AppColors.accentOrange,
              title: 'Anotar Orçamento Recebido',
              subtitle:
                  'Você recebeu um orçamento de alguém.\nAnote os serviços e valores para comparar depois.',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddBudgetScreen(type: 'recebido')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Card de seleção de tipo ───────────────────────────────────────────────────
class _TypeOptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  const _TypeOptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMedium, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Aba: Meus Orçamentos (emitidos) ──────────────────────────────────────────
class _EmitidosTab extends StatelessWidget {
  final NumberFormat fmt;
  const _EmitidosTab({required this.fmt});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final budgets = provider.emitidos;

    final statusColors = {
      'rascunho': AppColors.textLight,
      'enviado': AppColors.primaryBlue,
      'aprovado': AppColors.success,
      'recusado': AppColors.danger,
    };
    final statusLabels = {
      'rascunho': 'Rascunho',
      'enviado': 'Enviado',
      'aprovado': 'Aprovado',
      'recusado': 'Recusado',
    };

    if (budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined,
                size: 72, color: AppColors.textLight.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Nenhum orçamento criado ainda',
                style: TextStyle(fontSize: 16, color: AppColors.textLight)),
            const SizedBox(height: 6),
            const Text(
              'Crie orçamentos para enviar\naos seus clientes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                  label: 'Total',
                  value: '${budgets.length}',
                  icon: Icons.description_outlined),
              _StatItem(
                  label: 'Aprovados',
                  value: '${provider.getByStatus('aprovado').where((b) => b.budgetType == 'emitido').length}',
                  icon: Icons.check_circle_outline),
              _StatItem(
                  label: 'Valor aprovado',
                  value: fmt.format(provider.totalAprovado),
                  icon: Icons.monetization_on_outlined),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...budgets.map((b) => _BudgetCard(
              budget: b,
              statusColor: statusColors[b.status] ?? AppColors.textLight,
              statusLabel: statusLabels[b.status] ?? b.status,
              fmt: fmt,
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Aba: Orçamentos Recebidos ─────────────────────────────────────────────────
class _RecebidosTab extends StatelessWidget {
  final NumberFormat fmt;
  const _RecebidosTab({required this.fmt});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final budgets = provider.recebidos;

    final statusColors = {
      'analise': AppColors.primaryBlue,
      'aceito': AppColors.success,
      'rejeitado': AppColors.danger,
    };
    final statusLabels = {
      'analise': 'Em análise',
      'aceito': 'Aceito',
      'rejeitado': 'Rejeitado',
    };

    if (budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 72, color: AppColors.textLight.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Nenhum orçamento anotado',
                style: TextStyle(fontSize: 16, color: AppColors.textLight)),
            const SizedBox(height: 6),
            const Text(
              'Anote aqui os orçamentos que você\nrecebe de prestadores de serviço',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accentOrange.withValues(alpha: 0.2)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.accentOrange, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Exemplo: Você conversou com um pedreiro que te passou os valores dos serviços. Anote tudo aqui para comparar com outros orçamentos e tomar a melhor decisão!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar por categoria de serviço para facilitar comparação
    final byCategory = <String, List<Budget>>{};
    for (final b in budgets) {
      final cat = b.serviceCategory.isEmpty ? 'Outros' : b.serviceCategory;
      byCategory[cat] = [...(byCategory[cat] ?? []), b];
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentOrange,
                AppColors.accentOrangeLight.withValues(alpha: 0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                  label: 'Recebidos',
                  value: '${budgets.length}',
                  icon: Icons.inbox_outlined),
              _StatItem(
                  label: 'Em análise',
                  value: '${budgets.where((b) => b.status == 'analise').length}',
                  icon: Icons.pending_outlined),
              _StatItem(
                  label: 'Aceitos',
                  value: '${budgets.where((b) => b.status == 'aceito').length}',
                  icon: Icons.check_circle_outline),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dica de comparação
        if (byCategory.values.any((list) => list.length > 1)) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.compare_arrows_rounded,
                    color: AppColors.primaryBlue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Você tem orçamentos da mesma categoria para comparar!',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],

        ...budgets.map((b) => _ReceivedBudgetCard(
              budget: b,
              statusColor: statusColors[b.status] ?? AppColors.textLight,
              statusLabel: statusLabels[b.status] ?? b.status,
              fmt: fmt,
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Card de orçamento emitido ─────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final Color statusColor;
  final String statusLabel;
  final NumberFormat fmt;

  const _BudgetCard({
    required this.budget,
    required this.statusColor,
    required this.statusLabel,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BudgetProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BudgetDetailScreen(budget: budget)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.send_rounded,
                      size: 14, color: AppColors.primaryBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(budget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(budget.clientName,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMedium)),
                  ),
                  Text(
                    fmt.format(budget.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentOrange,
                        fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(budget.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.list_alt_outlined,
                      size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    '${budget.items.length} item${budget.items.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
              if (budget.status == 'rascunho' ||
                  budget.status == 'enviado') ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: 'Aprovar',
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        onTap: () => provider.updateStatus(budget, 'aprovado'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Enviar',
                        icon: Icons.send_rounded,
                        color: AppColors.primaryBlue,
                        onTap: () => provider.updateStatus(budget, 'enviado'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Excluir',
                        icon: Icons.delete_outline,
                        color: AppColors.danger,
                        onTap: () => provider.delete(budget.id),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de orçamento recebido ────────────────────────────────────────────────
class _ReceivedBudgetCard extends StatelessWidget {
  final Budget budget;
  final Color statusColor;
  final String statusLabel;
  final NumberFormat fmt;

  const _ReceivedBudgetCard({
    required this.budget,
    required this.statusColor,
    required this.statusLabel,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BudgetProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: budget.status == 'aceito'
              ? AppColors.success.withValues(alpha: 0.3)
              : budget.status == 'rejeitado'
                  ? AppColors.danger.withValues(alpha: 0.2)
                  : AppColors.accentOrange.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BudgetDetailScreen(budget: budget)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inbox_rounded,
                      size: 14, color: AppColors.accentOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(budget.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        if (budget.serviceCategory.isNotEmpty)
                          Text(
                            budget.serviceCategory,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accentOrange,
                                fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.handyman_outlined,
                      size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      budget.clientName, // prestador
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMedium),
                    ),
                  ),
                  Text(
                    fmt.format(budget.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentOrange,
                        fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(budget.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.build_outlined,
                      size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    '${budget.items.length} serviço${budget.items.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
              if (budget.status == 'analise') ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: 'Aceitar',
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        onTap: () => provider.updateStatus(budget, 'aceito'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Rejeitar',
                        icon: Icons.close_rounded,
                        color: AppColors.danger,
                        onTap: () =>
                            provider.updateStatus(budget, 'rejeitado'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Excluir',
                        icon: Icons.delete_outline,
                        color: AppColors.textLight,
                        onTap: () => provider.delete(budget.id),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// ── Detalhe do Orçamento ──────────────────────────────────────────────────────
class BudgetDetailScreen extends StatelessWidget {
  final Budget budget;
  const BudgetDetailScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isRecebido = budget.isRecebido;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(budget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareBudget(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isRecebido
                  ? LinearGradient(
                      colors: [
                        AppColors.accentOrange,
                        AppColors.accentOrangeLight.withValues(alpha: 0.85)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isRecebido ? Icons.inbox_rounded : Icons.send_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRecebido ? 'Orçamento Recebido' : 'Orçamento Emitido',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      '#${budget.id.substring(0, 6).toUpperCase()}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(budget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                if (budget.serviceCategory.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      budget.serviceCategory,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isRecebido
                          ? Icons.handyman_outlined
                          : Icons.person_outline,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRecebido
                          ? 'Prestador: ${budget.clientName}'
                          : 'Cliente: ${budget.clientName}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                if (budget.clientContact.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(budget.clientContact,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Total: ${fmt.format(budget.total)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Itens / Serviços
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    isRecebido ? 'Serviços / Itens do Orçamento' : 'Itens do Orçamento',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ...budget.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                if (item.quantity != 1 || item.unit != 'un')
                                  Text(
                                    '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)} ${item.unit} × ${fmt.format(item.unitPrice)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight),
                                  ),
                              ],
                            ),
                          ),
                          Text(fmt.format(item.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  fontSize: 14)),
                        ],
                      ),
                    )),
                const Divider(height: 1, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _TotalRow(
                          label: 'Subtotal',
                          value: fmt.format(budget.subtotal)),
                      if (budget.discountPercent > 0)
                        _TotalRow(
                          label:
                              'Desconto (${budget.discountPercent.toStringAsFixed(0)}%)',
                          value: '- ${fmt.format(budget.discountAmount)}',
                          color: AppColors.danger,
                        ),
                      const Divider(height: 16, color: AppColors.divider),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.textDark)),
                          Text(fmt.format(budget.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppColors.accentOrange)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (budget.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 16, color: AppColors.primaryBlue),
                      SizedBox(width: 6),
                      Text('Observações / Anotações',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(budget.notes,
                      style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14,
                          height: 1.5)),
                ],
              ),
            ),
          ],

          // Validade
          if (budget.validUntil != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined,
                      size: 16, color: AppColors.textLight),
                  const SizedBox(width: 8),
                  Text(
                    isRecebido
                        ? 'Válido até: ${DateFormat('dd/MM/yyyy').format(budget.validUntil!)}'
                        : 'Validade: ${DateFormat('dd/MM/yyyy').format(budget.validUntil!)}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _shareBudget(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final buffer = StringBuffer();
    if (budget.isRecebido) {
      buffer.writeln('📥 ORÇAMENTO RECEBIDO - ${budget.title}');
      buffer.writeln('Prestador: ${budget.clientName}');
      if (budget.serviceCategory.isNotEmpty) {
        buffer.writeln('Serviço: ${budget.serviceCategory}');
      }
    } else {
      buffer.writeln('📋 ORÇAMENTO - ${budget.title}');
      buffer.writeln('Cliente: ${budget.clientName}');
    }
    buffer.writeln('Data: ${DateFormat('dd/MM/yyyy').format(budget.createdAt)}');
    buffer.writeln('');
    buffer.writeln('ITENS:');
    for (final item in budget.items) {
      buffer.writeln('• ${item.description}: ${fmt.format(item.total)}');
    }
    buffer.writeln('');
    if (budget.discountPercent > 0) {
      buffer.writeln(
          'Desconto: ${budget.discountPercent.toStringAsFixed(0)}%');
    }
    buffer.writeln('TOTAL: ${fmt.format(budget.total)}');
    if (budget.notes.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Obs: ${budget.notes}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Orçamento copiado para compartilhar!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _TotalRow(
      {required this.label,
      required this.value,
      this.color = AppColors.textMedium});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Tela de criação (emitido ou recebido) ────────────────────────────────────
class AddBudgetScreen extends StatefulWidget {
  final String type; // 'emitido' | 'recebido'
  const AddBudgetScreen({super.key, required this.type});
  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _titleCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // cliente ou prestador
  final _contactCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _categoryCtrl = TextEditingController();
  final List<BudgetItem> _items = [];
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));

  bool get _isRecebido => widget.type == 'recebido';

  // Categorias de serviço para orçamentos recebidos
  static const _serviceCategories = [
    'Pedreiro / Alvenaria',
    'Pintura',
    'Elétrica',
    'Hidráulica / Encanamento',
    'Marcenaria / Móveis',
    'Telhado / Impermeabilização',
    'Gesso / Drywall',
    'Piso / Revestimento',
    'Paisagismo / Jardim',
    'Limpeza',
    'Informática / TI',
    'Mecânica / Auto',
    'Contabilidade',
    'Advocacia / Jurídico',
    'Design / Marketing',
    'Fotografia / Vídeo',
    'Reformas em Geral',
    'Outro Serviço',
  ];

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final subtotal = _items.fold<double>(0, (s, i) => s + i.total);
    final discount = double.tryParse(_discountCtrl.text) ?? 0;
    final total = subtotal * (1 - discount / 100);

    final accentColor =
        _isRecebido ? AppColors.accentOrange : AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isRecebido ? 'Anotar Orçamento Recebido' : 'Novo Orçamento'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Salvar',
                style: TextStyle(
                    color: accentColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner informativo para tipo recebido
          if (_isRecebido) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accentOrange.withValues(alpha: 0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.accentOrange, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anote aqui tudo que o prestador te informou: os serviços, os valores e qualquer detalhe importante. Isso vai te ajudar a comparar e tomar a melhor decisão!',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Seção: Informações básicas
          _Section(
            title: _isRecebido ? 'Dados do Prestador' : 'Informações do Orçamento',
            accentColor: accentColor,
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _isRecebido
                        ? 'Título / Descrição do Serviço *'
                        : 'Título do Orçamento *',
                    hintText: _isRecebido
                        ? 'Ex: Reforma da sala, Pintura do apartamento...'
                        : 'Ex: Orçamento de pintura',
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Categoria de serviço (só para recebidos)
                if (_isRecebido) ...[
                  DropdownButtonFormField<String>(
                    value: _categoryCtrl.text.isEmpty
                        ? null
                        : _categoryCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Serviço',
                      prefixIcon: Icon(Icons.handyman_outlined),
                    ),
                    hint: const Text('Selecione o tipo de serviço'),
                    isExpanded: true,
                    items: _serviceCategories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _categoryCtrl.text = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _isRecebido
                        ? 'Nome do Prestador *'
                        : 'Nome do Cliente *',
                    hintText: _isRecebido
                        ? 'Ex: João Pedreiro, Empresa XYZ...'
                        : 'Nome do cliente',
                    prefixIcon: Icon(
                      _isRecebido
                          ? Icons.handyman_outlined
                          : Icons.person_outline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _isRecebido
                        ? 'Telefone / WhatsApp do Prestador'
                        : 'Contato do Cliente',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Serviços / Itens
          _Section(
            title: _isRecebido ? 'Serviços e Valores' : 'Itens do Orçamento',
            accentColor: accentColor,
            child: Column(
              children: [
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _isRecebido
                          ? 'Adicione os serviços e valores informados pelo prestador'
                          : 'Adicione os itens do orçamento',
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ..._items.asMap().entries.map((entry) {
                  final item = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text(
                                '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)} ${item.unit} × ${fmt.format(item.unitPrice)} = ${fmt.format(item.total)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.danger, size: 20),
                          onPressed: () =>
                              setState(() => _items.removeAt(entry.key)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showAddItem(context, accentColor),
                  icon: Icon(Icons.add, color: accentColor),
                  label: Text(
                    _isRecebido ? 'Adicionar Serviço/Item' : 'Adicionar Item',
                    style: TextStyle(color: accentColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accentColor),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Totais
          if (_items.isNotEmpty)
            _Section(
              title: 'Valores',
              accentColor: accentColor,
              child: Column(
                children: [
                  if (!_isRecebido) ...[
                    TextField(
                      controller: _discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Desconto (%)',
                        prefixIcon: Icon(Icons.discount_outlined),
                        suffixText: '%',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal',
                                style: TextStyle(color: AppColors.textMedium)),
                            Text(fmt.format(subtotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Desconto ($discount%)',
                                  style: const TextStyle(
                                      color: AppColors.danger)),
                              Text(
                                  '- ${fmt.format(subtotal * discount / 100)}',
                                  style: const TextStyle(
                                      color: AppColors.danger)),
                            ],
                          ),
                        ],
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            Text(fmt.format(total),
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: accentColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Seção: Validade e Observações
          _Section(
            title: 'Validade e Anotações',
            accentColor: accentColor,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.event_outlined, color: accentColor),
                  title: Text(
                    _isRecebido
                        ? 'Validade do orçamento: ${DateFormat('dd/MM/yyyy').format(_validUntil)}'
                        : 'Válido até: ${DateFormat('dd/MM/yyyy').format(_validUntil)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _validUntil,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _validUntil = date);
                    },
                    child: Text('Alterar',
                        style: TextStyle(color: accentColor)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: _isRecebido
                        ? 'Anotações importantes (condições, prazo, garantia...)'
                        : 'Observações do orçamento',
                    hintText: _isRecebido
                        ? 'Ex: Prazo de execução 5 dias, inclui mão de obra e material, garantia de 6 meses...'
                        : 'Observações, condições especiais...',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botão salvar
          ElevatedButton.icon(
            onPressed: _save,
            icon: Icon(
                _isRecebido ? Icons.save_alt_rounded : Icons.save_rounded),
            label: Text(
                _isRecebido ? 'Salvar Orçamento Recebido' : 'Salvar Orçamento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAddItem(BuildContext context, Color accentColor) {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    String unit = 'un';
    final units = ['un', 'h', 'm²', 'm', 'kg', 'L', 'cx', 'pct', 'dias'];
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
          final price =
              double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
          final total = qty * price;

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
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isRecebido
                              ? Icons.build_outlined
                              : Icons.add_box_outlined,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isRecebido ? 'Adicionar Serviço' : 'Adicionar Item',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: _isRecebido
                          ? 'Descrição do serviço *'
                          : 'Descrição do item *',
                      hintText: _isRecebido
                          ? 'Ex: Pintura da sala, Instalação da pia...'
                          : 'Ex: Tinta acrílica, Mão de obra...',
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setModalState(() {}),
                          decoration:
                              const InputDecoration(labelText: 'Qtd'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          decoration:
                              const InputDecoration(labelText: 'Unid.'),
                          items: units
                              .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => unit = v ?? 'un'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Valor unit.',
                            prefixText: 'R\$ ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total deste item:',
                              style: TextStyle(
                                  color: accentColor, fontSize: 13)),
                          Text(fmt.format(total),
                              style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (descCtrl.text.trim().isEmpty) return;
                        final item = BudgetItem(
                          id: const Uuid().v4(),
                          description: descCtrl.text.trim(),
                          quantity: double.tryParse(
                                  qtyCtrl.text.replaceAll(',', '.')) ??
                              1,
                          unit: unit,
                          unitPrice: double.tryParse(
                                  priceCtrl.text.replaceAll(',', '.')) ??
                              0,
                        );
                        setState(() => _items.add(item));
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o título e o nome!')),
      );
      return;
    }
    final provider = context.read<BudgetProvider>();
    final budget = Budget(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      clientName: _nameCtrl.text.trim(),
      clientContact: _contactCtrl.text.trim(),
      items: _items,
      createdAt: DateTime.now(),
      validUntil: _validUntil,
      status: _isRecebido ? 'analise' : 'rascunho',
      notes: _notesCtrl.text.trim(),
      discountPercent:
          double.tryParse(_discountCtrl.text.replaceAll(',', '.')) ?? 0,
      budgetType: widget.type,
      serviceCategory: _categoryCtrl.text.trim(),
    );
    provider.add(budget);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecebido
            ? '✅ Orçamento recebido salvo!'
            : '✅ Orçamento criado!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Widget auxiliar de seção ─────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Color accentColor;

  const _Section({
    required this.title,
    required this.child,
    this.accentColor = AppColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: accentColor)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
