import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/agenda_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/urgent_task_provider.dart';
import '../providers/pet_provider.dart';
import '../models/appointment.dart';
import '../models/transaction.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/nav_service.dart';
import 'agenda_screen.dart';
import 'finance_screen.dart';
import 'urgent_tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final agenda   = context.watch<AgendaProvider>();
    final finance  = context.watch<FinanceProvider>();
    final budget   = context.watch<BudgetProvider>();
    final urgent   = context.watch<UrgentTaskProvider>();
    final pets     = context.watch<PetProvider>();
    final auth     = context.watch<AuthService>();
    final sync     = context.watch<SyncService>();

    // Tarefas vencidas e para hoje
    final vencidas = urgent.tasks.where((t) => !t.isDone && t.isOverdue).toList();
    final hoje     = urgent.tasks.where((t) => !t.isDone && t.isDueToday).toList();
    final totalAlerta = vencidas.length + hoje.length;
    final now     = DateTime.now();
    final fmt     = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final hora    = now.hour;
    final saudacao = hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$saudacao! 👋',
                                  style: TextStyle(
                                    color: AppColors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  auth.primeiroNome,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentOrange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    DateFormat('dd MMM', 'pt_BR').format(now),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7, height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: sync.sincronizando
                                            ? Colors.amber
                                            : sync.online
                                                ? const Color(0xFF4ade80)
                                                : Colors.redAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      sync.sincronizando
                                          ? 'Sincronizando...'
                                          : sync.online
                                              ? (sync.pendentes > 0
                                                  ? '${sync.pendentes} pendente${sync.pendentes > 1 ? 's' : ''}'
                                                  : 'Online')
                                              : 'Offline',
                                      style: TextStyle(
                                        color: AppColors.white.withValues(alpha: 0.75),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _SummaryChip(
                              icon: Icons.calendar_today,
                              label: '${agenda.getByDate(now).length} hoje',
                              color: AppColors.accentOrangeLight,
                            ),
                            const SizedBox(width: 8),
                            _SummaryChip(
                              icon: Icons.trending_up,
                              label: fmt.format(finance.saldoMesAtual),
                              color: finance.saldoMesAtual >= 0 ? AppColors.success : AppColors.danger,
                              tooltip: 'Saldo do mês atual',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Banner de alertas de vacinas pets ─────────────────────
                  if (pets.alertasVacinas > 0) ...[                    
                    _PetVacinaAlertBanner(
                      total: pets.alertasVacinas,
                      onTap: () => NavService.go(7),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Banner de alertas de tarefas ──────────────────────────
                  if (totalAlerta > 0) ...[
                    _UrgentBanner(
                      vencidas: vencidas.length,
                      hoje: hoje.length,
                      onTap: () => _navegarPara(context, 4),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Cards financeiros clicáveis ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _FinanceCard(
                          label: 'Receitas',
                          value: fmt.format(finance.totalReceitas),
                          icon: Icons.arrow_upward_rounded,
                          color: AppColors.success,
                          onTap: () => _navegarPara(context, 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FinanceCard(
                          label: 'Despesas',
                          value: fmt.format(finance.totalDespesas),
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.danger,
                          onTap: () => _navegarPara(context, 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FinanceCard(
                          label: 'A Receber',
                          value: fmt.format(finance.totalAReceber),
                          icon: Icons.schedule_rounded,
                          color: AppColors.accentOrange,
                          onTap: () => _navegarPara(context, 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FinanceCard(
                          label: 'Orçamentos',
                          value: '${budget.budgets.length} total',
                          icon: Icons.description_outlined,
                          color: AppColors.primaryBlue,
                          onTap: () => _navegarPara(context, 5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Atalho rápido — adicionar transação ─────────────────────
                  const _QuickAddBar(),

                  const SizedBox(height: 24),

                  // ── Próximos compromissos ───────────────────────────────────
                  _SectionHeader(
                    title: 'Próximos Compromissos',
                    icon: Icons.event_note_rounded,
                    actionLabel: 'Ver todos',
                    onAction: () => _navegarPara(context, 1),
                  ),
                  const SizedBox(height: 8),
                  if (agenda.getUpcoming().isEmpty)
                    _EmptyCard(
                      message: 'Nenhum compromisso próximo',
                      actionLabel: 'Adicionar na Agenda',
                      onAction: () => _navegarPara(context, 1),
                    )
                  else
                    ...agenda.getUpcoming().map((a) => _AppointmentTile(
                          appointment: a,
                          onTap: () => _navegarPara(context, 1),
                        )),

                  const SizedBox(height: 24),

                  // ── Últimas transações ──────────────────────────────────────
                  _SectionHeader(
                    title: 'Últimas Movimentações',
                    icon: Icons.swap_horiz_rounded,
                    actionLabel: 'Ver todas',
                    onAction: () => _navegarPara(context, 2),
                  ),
                  const SizedBox(height: 8),
                  if (finance.getRecent().isEmpty)
                    _EmptyCard(
                      message: 'Nenhuma movimentação registrada',
                      actionLabel: 'Adicionar lançamento',
                      onAction: () => _navegarPara(context, 2),
                    )
                  else
                    ...finance.getRecent().map((t) => _TransactionTile(
                          transaction: t,
                          onTap: () => _navegarPara(context, 2),
                        )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navegarPara(BuildContext context, int index) {
    NavService.go(index);
  }
}

// ── Barra de atalho rápido ───────────────────────────────────────────────────

class _QuickAddBar extends StatelessWidget {
  const _QuickAddBar();

  void _abrirReceita(BuildContext context) {
    NavService.go(2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTransactionSheet(initialType: 'receita'),
      );
    });
  }

  void _abrirDespesa(BuildContext context) {
    NavService.go(2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTransactionSheet(initialType: 'despesa'),
      );
    });
  }

  void _abrirEvento(BuildContext context) {
    NavService.go(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddAppointmentSheet(selectedDate: DateTime.now()),
      );
    });
  }

  void _abrirTarefa(BuildContext context) {
    NavService.go(4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTaskSheet(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _QuickBtn(
            icon: Icons.add_circle_rounded,
            label: '+ Receita',
            color: AppColors.success,
            onTap: () => _abrirReceita(context),
          ),
          _QuickDivider(),
          _QuickBtn(
            icon: Icons.remove_circle_rounded,
            label: '+ Despesa',
            color: AppColors.danger,
            onTap: () => _abrirDespesa(context),
          ),
          _QuickDivider(),
          _QuickBtn(
            icon: Icons.calendar_month_rounded,
            label: '+ Evento',
            color: AppColors.accentOrange,
            onTap: () => _abrirEvento(context),
          ),
          _QuickDivider(),
          _QuickBtn(
            icon: Icons.task_alt_rounded,
            label: '+ Tarefa',
            color: AppColors.primaryBlue,
            onTap: () => _abrirTarefa(context),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _QuickDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? tooltip;
  const _SummaryChip({required this.icon, required this.label, required this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          if (tooltip != null) ...[  
            const SizedBox(width: 4),
            Text('mês', style: TextStyle(color: color.withValues(alpha: 0.65), fontSize: 9)),
          ],
        ],
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: chip);
    }
    return chip;
  }
}

class _FinanceCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _FinanceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textLight.withValues(alpha: 0.4), size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ],
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyCard({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Banner de alertas de vacinas dos pets ─────────────────────────────────

class _PetVacinaAlertBanner extends StatelessWidget {
  final int total;
  final VoidCallback onTap;
  const _PetVacinaAlertBanner({required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFf97316).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFf97316).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFf97316).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('💉', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vacinas do seu pet!',
                    style: TextStyle(
                      color: Color(0xFFf97316),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$total vacina${total > 1 ? 's' : ''} vencida${total > 1 ? 's' : ''} ou a vencer em 30 dias',
                    style: TextStyle(
                        color: const Color(0xFFf97316).withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: const Color(0xFFf97316), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Banner de tarefas vencidas/hoje ─────────────────────────────────────────

class _UrgentBanner extends StatelessWidget {
  final int vencidas;
  final int hoje;
  final VoidCallback onTap;
  const _UrgentBanner({required this.vencidas, required this.hoje, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final somenteHoje = vencidas == 0 && hoje > 0;
    final cor    = somenteHoje ? AppColors.accentOrange : AppColors.danger;
    final icone  = somenteHoje ? Icons.today_rounded    : Icons.warning_rounded;

    final partes = <String>[];
    if (vencidas > 0) partes.add('$vencidas vencida${vencidas > 1 ? 's' : ''}');
    if (hoje     > 0) partes.add('$hoje para hoje');
    final texto = partes.join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: cor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    somenteHoje ? 'Tarefas para hoje' : 'Tarefas em atraso!',
                    style: TextStyle(
                      color: cor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    texto,
                    style: TextStyle(color: cor.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  const _AppointmentTile({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${appointment.time} • ${appointment.category}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('dd/MM', 'pt_BR').format(appointment.date),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isReceita = transaction.type == 'receita';
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isReceita ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isReceita ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: isReceita ? AppColors.success : AppColors.danger,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (transaction.origin.isNotEmpty)
                    Text(transaction.origin,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isReceita ? '+' : '-'} ${fmt.format(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isReceita ? AppColors.success : AppColors.danger,
                    fontSize: 14,
                  ),
                ),
                if (!transaction.isReceived)
                  const Text('Pendente',
                      style: TextStyle(fontSize: 11, color: AppColors.accentOrange)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 16),
          ],
        ),
      ),
    );
  }
}
