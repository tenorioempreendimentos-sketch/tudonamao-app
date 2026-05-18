import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado  = DateTime.now().year;

  static const _meses = [
    'Janeiro','Fevereiro','Março','Abril','Maio','Junho',
    'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _mesAnterior() {
    setState(() {
      if (_mesSelecionado == 1) {
        _mesSelecionado = 12;
        _anoSelecionado--;
      } else {
        _mesSelecionado--;
      }
    });
  }

  void _mesSeguinte() {
    final now = DateTime.now();
    if (_anoSelecionado > now.year ||
        (_anoSelecionado == now.year && _mesSelecionado >= now.month)) return;
    setState(() {
      if (_mesSelecionado == 12) {
        _mesSelecionado = 1;
        _anoSelecionado++;
      } else {
        _mesSelecionado++;
      }
    });
  }

  bool get _isMesAtual {
    final now = DateTime.now();
    return _mesSelecionado == now.month && _anoSelecionado == now.year;
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Transações filtradas pelo mês selecionado
    final receitasMes = finance.getByMonth(_mesSelecionado, _anoSelecionado)
        .where((t) => t.type == 'receita').toList();
    final despesasMes = finance.getByMonth(_mesSelecionado, _anoSelecionado)
        .where((t) => t.type == 'despesa').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finanças'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentOrange,
          labelColor: AppColors.accentOrangeLight,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'Resumo'),
            Tab(text: 'Receitas'),
            Tab(text: 'Despesas'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Lançamento'),
      ),
      body: Column(
        children: [
          // ── Seletor de mês ──────────────────────────────────────────────
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white70, size: 26),
                  onPressed: _mesAnterior,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_meses[_mesSelecionado - 1]} $_anoSelecionado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: _isMesAtual
                        ? Colors.white24
                        : Colors.white70,
                    size: 26,
                  ),
                  onPressed: _isMesAtual ? null : _mesSeguinte,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          // ── Abas de conteúdo ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ResumoTab(finance: finance, fmt: fmt),
                _TransactionList(
                  transactions: receitasMes,
                  type: 'receita',
                  fmt: fmt,
                ),
                _TransactionList(
                  transactions: despesasMes,
                  type: 'despesa',
                  fmt: fmt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }
}

// ── Aba Resumo ──────────────────────────────────────────────────────────────
class _ResumoTab extends StatelessWidget {
  final FinanceProvider finance;
  final NumberFormat fmt;
  const _ResumoTab({required this.finance, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Saldo principal
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: finance.saldo >= 0
                ? AppColors.primaryGradient
                : const LinearGradient(
                    colors: [Color(0xFF8B0000), AppColors.danger]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('Saldo Atual',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                fmt.format(finance.saldo),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BalanceItem(
                      label: 'Receitas',
                      value: fmt.format(finance.totalReceitas),
                      icon: Icons.arrow_upward,
                      color: const Color(0xFF4ADE80)),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _BalanceItem(
                      label: 'Despesas',
                      value: fmt.format(finance.totalDespesas),
                      icon: Icons.arrow_downward,
                      color: const Color(0xFFFF8080)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // A receber
        if (finance.totalAReceber > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.accentOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.accentOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('A Receber (Pendente)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(fmt.format(finance.totalAReceber),
                          style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Gráfico de pizza — Despesas por categoria ───────────────────
        if (finance.despesasPorCategoria.isNotEmpty) ...[
          _SectionTitle(
              title: 'Despesas por Categoria',
              icon: Icons.pie_chart_rounded),
          const SizedBox(height: 12),
          _DespesasPieChart(
            data: finance.despesasPorCategoria,
            total: finance.totalDespesas,
            fmt: fmt,
          ),
          const SizedBox(height: 16),
        ],

        // ── Barras — detalhamento por categoria ─────────────────────────
        if (finance.despesasPorCategoria.isNotEmpty) ...[
          ...finance.despesasPorCategoria.entries.map(
            (e) => _OrigemBar(
              label: e.key,
              value: e.value,
              total: finance.totalDespesas,
              fmt: fmt,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Gráfico de pizza — Receitas por origem ──────────────────────
        if (finance.receitasPorOrigem.isNotEmpty) ...[
          _SectionTitle(title: 'Origem das Receitas', icon: Icons.donut_large_rounded),
          const SizedBox(height: 12),
          _DespesasPieChart(
            data: finance.receitasPorOrigem,
            total: finance.totalReceitas,
            fmt: fmt,
            isReceita: true,
          ),
          const SizedBox(height: 12),
          ...finance.receitasPorOrigem.entries.map(
            (e) => _OrigemBar(
              label: e.key,
              value: e.value,
              total: finance.totalReceitas,
              fmt: fmt,
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Gráfico de pizza com fl_chart ────────────────────────────────────────────
class _DespesasPieChart extends StatefulWidget {
  final Map<String, double> data;
  final double total;
  final NumberFormat fmt;
  final bool isReceita;
  const _DespesasPieChart({
    required this.data,
    required this.total,
    required this.fmt,
    this.isReceita = false,
  });

  @override
  State<_DespesasPieChart> createState() => _DespesasPieChartState();
}

class _DespesasPieChartState extends State<_DespesasPieChart> {
  int _touched = -1;

  static const _colors = [
    Color(0xFFE74C3C), Color(0xFF3498DB), Color(0xFF2ECC71),
    Color(0xFFF39C12), Color(0xFF9B59B6), Color(0xFF1ABC9C),
    Color(0xFFE67E22), Color(0xFF34495E), Color(0xFFEC407A),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (response?.touchedSection != null) {
                              _touched = response!.touchedSection!.touchedSectionIndex;
                            } else {
                              _touched = -1;
                            }
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: entries.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        final pct = widget.total > 0 ? e.value / widget.total * 100 : 0.0;
                        final isTouched = i == _touched;
                        final color = _colors[i % _colors.length];
                        return PieChartSectionData(
                          color: color,
                          value: e.value,
                          title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                          radius: isTouched ? 56 : 46,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.asMap().entries.take(6).map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      final pct = widget.total > 0 ? e.value / widget.total * 100 : 0.0;
                      final color = _colors[i % _colors.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.key,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isReceita ? 'Total de receitas' : 'Total de despesas',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
              Text(
                widget.fmt.format(widget.total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: widget.isReceita ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _BalanceItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textDark)),
      ],
    );
  }
}

class _OrigemBar extends StatelessWidget {
  final String label;
  final double value, total;
  final NumberFormat fmt;
  final Color color;
  const _OrigemBar(
      {required this.label,
      required this.value,
      required this.total,
      required this.fmt,
      this.color = AppColors.success});

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? value / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Text(fmt.format(value),
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(percent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Lista de Transações ──────────────────────────────────────────────────────
class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final String type;
  final NumberFormat fmt;
  const _TransactionList(
      {required this.transactions, required this.type, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'receita'
                  ? Icons.savings_outlined
                  : Icons.money_off_outlined,
              size: 64,
              color: AppColors.textLight.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'receita'
                  ? 'Nenhuma receita registrada'
                  : 'Nenhuma despesa registrada',
              style: const TextStyle(color: AppColors.textLight, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (ctx, i) {
        final t = transactions[i];
        return _TransactionCard(transaction: t, fmt: fmt);
      },
    );
  }
}

// ── Card da transação ────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat fmt;
  const _TransactionCard({required this.transaction, required this.fmt});

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(
        transaction: transaction,
        fmt: fmt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    final isReceita = transaction.type == 'receita';
    final color = isReceita ? AppColors.success : AppColors.danger;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => provider.delete(transaction.id),
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
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
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isReceita
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
                size: 20,
              ),
            ),
            title: Text(transaction.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isReceita && transaction.origin.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.business_center_outlined,
                          size: 12, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('Origem: ${transaction.origin}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                Text(
                  '${transaction.category} • ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(transaction.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: color, fontSize: 15),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.isReceived
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.isReceived
                        ? (isReceita ? 'Recebido' : 'Pago')
                        : 'Pendente',
                    style: TextStyle(
                      fontSize: 10,
                      color: transaction.isReceived
                          ? AppColors.success
                          : AppColors.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom Sheet de Detalhes ─────────────────────────────────────────────────
class _TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat fmt;
  const _TransactionDetailSheet(
      {required this.transaction, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    final isReceita = transaction.type == 'receita';
    final color = isReceita ? AppColors.success : AppColors.danger;
    final colorBg = isReceita
        ? AppColors.success.withValues(alpha: 0.08)
        : AppColors.danger.withValues(alpha: 0.08);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header — tipo + valor
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isReceita
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceita ? 'RECEITA' : 'DESPESA',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmt.format(transaction.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Informações detalhadas
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Data',
            value: DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR')
                .format(transaction.date),
          ),
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Categoria',
            value: transaction.category,
          ),
          _DetailRow(
            icon: Icons.payment_outlined,
            label: 'Forma de pagamento',
            value: transaction.paymentMethod.isNotEmpty
                ? transaction.paymentMethod
                : '—',
          ),
          if (isReceita && transaction.origin.isNotEmpty)
            _DetailRow(
              icon: Icons.business_center_outlined,
              label: 'Origem',
              value: transaction.origin,
              valueColor: AppColors.primaryBlue,
            ),
          if (!isReceita && transaction.origin.isNotEmpty)
            _DetailRow(
              icon: Icons.store_outlined,
              label: 'Fornecedor / Origem',
              value: transaction.origin,
            ),
          if (transaction.description.isNotEmpty)
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Observação',
              value: transaction.description,
            ),

          // Status — com botão toggle
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(
                  transaction.isReceived
                      ? Icons.check_circle_outline
                      : Icons.schedule_outlined,
                  color: transaction.isReceived
                      ? AppColors.success
                      : AppColors.accentOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500)),
                      Text(
                        transaction.isReceived
                            ? (isReceita ? 'Recebido' : 'Pago')
                            : 'Pendente',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: transaction.isReceived
                              ? AppColors.success
                              : AppColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle rápido de status
                GestureDetector(
                  onTap: () {
                    provider.toggleReceived(transaction);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: transaction.isReceived
                          ? AppColors.accentOrange.withValues(alpha: 0.12)
                          : AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: transaction.isReceived
                            ? AppColors.accentOrange.withValues(alpha: 0.3)
                            : AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      transaction.isReceived
                          ? 'Marcar pendente'
                          : (isReceita ? 'Marcar recebido' : 'Marcar pago'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: transaction.isReceived
                            ? AppColors.accentOrange
                            : AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botões — Editar e Excluir
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddTransactionSheet(
                        transactionToEdit: transaction,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: BorderSide(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        title: const Text('Excluir lançamento?'),
                        content: Text(
                            'Tem certeza que deseja excluir "${transaction.title}"? Esta ação não pode ser desfeita.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger),
                            onPressed: () {
                              provider.delete(transaction.id);
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Excluir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Linha de detalhe reutilizável ─────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formulário de Lançamento (criar + editar) ────────────────────────────────
class AddTransactionSheet extends StatefulWidget {
  final Transaction? transactionToEdit;
  final String? initialType; // 'receita' ou 'despesa' — usado pelos atalhos da Home
  const AddTransactionSheet({super.key, this.transactionToEdit, this.initialType});
  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'receita';
  String _category = 'Serviços';
  String _paymentMethod = 'Transferência';
  bool _isReceived = true;
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    // Se veio um tipo inicial dos atalhos da Home, usa ele
    if (widget.initialType != null && widget.transactionToEdit == null) {
      _type = widget.initialType!;
      _category = _type == 'receita' ? 'Serviços' : 'Fornecedor';
    }
    final t = widget.transactionToEdit;
    if (t != null) {
      _titleCtrl.text = t.title;
      _amountCtrl.text = t.amount.toStringAsFixed(2).replaceAll('.', ',');
      _originCtrl.text = t.origin;
      _descCtrl.text = t.description;
      _type = t.type;
      _category = t.category;
      _paymentMethod = t.paymentMethod.isNotEmpty ? t.paymentMethod : 'Transferência';
      _isReceived = t.isReceived;
      _date = t.date;
    }
  }

  final _receitaCategories = [
    'Serviços', 'Produto', 'Consultoria', 'Mensalidade', 'Projeto', 'Outros'
  ];
  final _despesaCategories = [
    'Fornecedor', 'Aluguel', 'Salário', 'Impostos', 'Marketing',
    'Equipamentos', 'Outros'
  ];
  final _paymentMethods = [
    'Dinheiro', 'PIX', 'Transferência', 'Cartão Crédito', 'Cartão Débito',
    'Boleto', 'Cheque'
  ];

  @override
  Widget build(BuildContext context) {
    final isReceita = _type == 'receita';
    final categories = isReceita ? _receitaCategories : _despesaCategories;

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
            Text(
              _isEditing ? 'Editar Lançamento' : 'Novo Lançamento',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Tipo
            Row(
              children: [
                Expanded(child: _TypeButton(
                  label: 'Receita',
                  icon: Icons.arrow_upward_rounded,
                  selected: _type == 'receita',
                  color: AppColors.success,
                  onTap: () => setState(() {
                    _type = 'receita';
                    _category = 'Serviços';
                  }),
                )),
                const SizedBox(width: 12),
                Expanded(child: _TypeButton(
                  label: 'Despesa',
                  icon: Icons.arrow_downward_rounded,
                  selected: _type == 'despesa',
                  color: AppColors.danger,
                  onTap: () => setState(() {
                    _type = 'despesa';
                    _category = 'Fornecedor';
                  }),
                )),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Título / Descrição *',
                  prefixIcon: Icon(Icons.label_outline)),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Valor (R\$) *',
                        prefixIcon: Icon(Icons.attach_money)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data'),
                      child: Text(
                          DateFormat('dd/MM/yyyy').format(_date),
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Origem (só para receita)
            if (isReceita) ...[
              TextField(
                controller: _originCtrl,
                decoration: const InputDecoration(
                  labelText: 'Origem da Receita (cliente, projeto...)',
                  prefixIcon: Icon(Icons.business_center_outlined),
                  hintText: 'Ex: Cliente ABC, Projeto XYZ',
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Pagamento'),
                    items: _paymentMethods
                        .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                isReceita ? 'Já recebido?' : 'Já pago?',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              value: _isReceived,
              activeColor: AppColors.success,
              onChanged: (v) => setState(() => _isReceived = v),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_isEditing ? Icons.check_rounded : Icons.save_outlined),
                label: Text(_isEditing ? 'Salvar alterações' : 'Salvar Lançamento'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) {
      return;
    }
    final amount = double.tryParse(
            _amountCtrl.text.replaceAll(',', '.')) ??
        0;
    if (amount <= 0) return;

    final provider = context.read<FinanceProvider>();

    if (_isEditing) {
      // Edição — atualiza os campos do objeto existente
      final t = widget.transactionToEdit!;
      t.title = _titleCtrl.text.trim();
      t.amount = amount;
      t.type = _type;
      t.category = _category;
      t.origin = _originCtrl.text.trim();
      t.date = _date;
      t.description = _descCtrl.text.trim();
      t.isReceived = _isReceived;
      t.paymentMethod = _paymentMethod;
      provider.update(t);
    } else {
      // Novo lançamento
      provider.add(Transaction(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        amount: amount,
        type: _type,
        category: _category,
        origin: _originCtrl.text.trim(),
        date: _date,
        description: _descCtrl.text.trim(),
        isReceived: _isReceived,
        paymentMethod: _paymentMethod,
      ));
    }
    Navigator.pop(context);
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeButton({
    required this.label, required this.icon,
    required this.selected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
