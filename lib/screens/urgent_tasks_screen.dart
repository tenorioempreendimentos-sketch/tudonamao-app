import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../providers/urgent_task_provider.dart';
import '../models/urgent_task.dart';

class UrgentTasksScreen extends StatefulWidget {
  const UrgentTasksScreen({super.key});
  @override
  State<UrgentTasksScreen> createState() => _UrgentTasksScreenState();
}

class _UrgentTasksScreenState extends State<UrgentTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UrgentTaskProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Tarefas & Contas'),
            if (provider.pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.pendingCount}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentOrange,
          labelColor: AppColors.accentOrangeLight,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.5),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Tarefas (${provider.tarefas.where((t) => !t.isDone).length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Contas (${provider.contas.where((t) => !t.isDone).length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Adicionar'),
      ),
      body: Column(
        children: [
          // Alertas em destaque
          if (provider.overdueItems.isNotEmpty || provider.dueTodayItems.isNotEmpty)
            _AlertBanner(provider: provider, fmt: fmt),

          // Contas pendentes resumo
          if (provider.totalContasPendentes > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total a pagar: ${fmt.format(provider.totalContasPendentes)}',
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(tasks: provider.tarefas, fmt: fmt),
                _TaskList(tasks: provider.contas, fmt: fmt, isContas: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final UrgentTaskProvider provider;
  final NumberFormat fmt;
  const _AlertBanner({required this.provider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), AppColors.danger],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text('⚠️ Atenção necessária!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
          if (provider.overdueItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${provider.overdueItems.length} item(s) em atraso!',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (provider.dueTodayItems.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${provider.dueTodayItems.length} item(s) vencem HOJE!',
              style: const TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<UrgentTask> tasks;
  final NumberFormat fmt;
  final bool isContas;
  const _TaskList(
      {required this.tasks, required this.fmt, this.isContas = false});

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => !t.isDone).toList();
    final done = tasks.where((t) => t.isDone).toList();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isContas ? Icons.receipt_long_outlined : Icons.task_outlined,
              size: 72,
              color: AppColors.textLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isContas
                  ? 'Nenhuma conta registrada'
                  : 'Nenhuma tarefa registrada',
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (pending.isNotEmpty) ...[
          const _ListHeader(title: 'Pendentes', icon: Icons.pending_actions),
          ...pending.map((t) => _TaskCard(task: t, fmt: fmt)),
          const SizedBox(height: 8),
        ],
        if (done.isNotEmpty) ...[
          const _ListHeader(
              title: 'Concluídos', icon: Icons.check_circle_outline),
          ...done.map((t) => _TaskCard(task: t, fmt: fmt)),
        ],
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ListHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

String _recurrenceLabel(String type) {
  switch (type) {
    case 'diaria':  return 'Diária';
    case 'semanal': return 'Semanal';
    case 'mensal':  return 'Mensal';
    case 'anual':   return 'Anual';
    default:        return '';
  }
}

class _TaskCard extends StatelessWidget {
  final UrgentTask task;
  final NumberFormat fmt;
  const _TaskCard({required this.task, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<UrgentTaskProvider>();
    final priorityData = {
      'urgente': {'color': AppColors.danger, 'label': 'Urgente', 'icon': Icons.priority_high},
      'importante': {'color': AppColors.accentOrange, 'label': 'Importante', 'icon': Icons.flag_outlined},
      'normal': {'color': AppColors.primaryBlue, 'label': 'Normal', 'icon': Icons.low_priority},
    };
    final pData = priorityData[task.priority] ?? priorityData['normal']!;
    final pColor = pData['color'] as Color;

    return Dismissible(
      key: Key(task.id),
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
      onDismissed: (_) => provider.delete(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: task.isDone
              ? AppColors.background
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isOverdue
                ? AppColors.danger.withValues(alpha: 0.5)
                : task.isDueToday && !task.isDone
                    ? AppColors.accentOrange.withValues(alpha: 0.5)
                    : AppColors.divider,
            width: task.isOverdue || (task.isDueToday && !task.isDone) ? 1.5 : 1,
          ),
          boxShadow: [
            if (!task.isDone)
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => provider.toggleDone(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: task.isDone ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: task.isDone ? AppColors.success : pColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isDone
                                  ? AppColors.textLight
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                        // Badge prioridade
                        if (!task.isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: pColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pData['label'] as String,
                              style: TextStyle(
                                  color: pColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (task.amount != null) ...[
                          Icon(Icons.attach_money,
                              size: 13, color: AppColors.accentOrange),
                          Text(fmt.format(task.amount!),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.accentOrange,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                        ],
                        if (task.dueDate != null) ...[
                          Icon(
                            Icons.event_outlined,
                            size: 13,
                            color: task.isOverdue
                                ? AppColors.danger
                                : task.isDueToday
                                    ? AppColors.accentOrange
                                    : AppColors.textLight,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            task.isOverdue
                                ? 'VENCIDO! ${DateFormat('dd/MM').format(task.dueDate!)}'
                                : task.isDueToday
                                    ? 'HOJE!'
                                    : DateFormat('dd/MM/yyyy').format(task.dueDate!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: task.isOverdue || task.isDueToday
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: task.isOverdue
                                  ? AppColors.danger
                                  : task.isDueToday
                                      ? AppColors.accentOrange
                                      : AppColors.textLight,
                            ),
                          ),
                        ],
                        if (task.category.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text('• ${task.category}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textLight)),
                        ],
                        if (task.recurrenceType != 'nenhuma') ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.repeat_rounded,
                                    size: 10, color: AppColors.primaryBlue),
                                const SizedBox(width: 3),
                                Text(
                                  _recurrenceLabel(task.recurrenceType),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(task.note,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
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

// ── Formulário ───────────────────────────────────────────────────────────────
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'tarefa';
  String _priority = 'urgente';
  String _category = 'Geral';
  DateTime? _dueDate;
  String _recurrenceType = 'nenhuma';

  static const _recurrenceOptions = [
    ('nenhuma',  '🚫 Sem recorrência'),
    ('diaria',   '📅 Diária'),
    ('semanal',  '📆 Semanal'),
    ('mensal',   '🗓️ Mensal'),
    ('anual',    '📅 Anual'),
  ];

  final _tarefaCategories = ['Geral', 'Casa', 'Trabalho', 'Saúde', 'Financeiro', 'Pessoal'];
  final _contaCategories = ['Água', 'Luz', 'Internet', 'Aluguel', 'Telefone', 'Cartão', 'Imposto', 'Outros'];

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'tarefa' ? _tarefaCategories : _contaCategories;

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
            const Text('Novo Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            // Tipo
            Row(
              children: [
                Expanded(
                  child: _TypeBtn(
                    label: '✅ Tarefa',
                    selected: _type == 'tarefa',
                    color: AppColors.primaryBlue,
                    onTap: () => setState(() {
                      _type = 'tarefa';
                      _category = 'Geral';
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeBtn(
                    label: '💸 Conta',
                    selected: _type == 'conta',
                    color: AppColors.danger,
                    onTap: () => setState(() {
                      _type = 'conta';
                      _category = 'Outros';
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _type == 'tarefa' ? 'Tarefa *' : 'Nome da conta *',
                prefixIcon: Icon(
                    _type == 'tarefa' ? Icons.task_alt_rounded : Icons.receipt_long_rounded),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Prioridade'),
                    items: [
                      DropdownMenuItem(
                          value: 'urgente',
                          child: Row(children: [
                            Icon(Icons.priority_high, color: AppColors.danger, size: 16),
                            const SizedBox(width: 4),
                            const Text('Urgente'),
                          ])),
                      DropdownMenuItem(
                          value: 'importante',
                          child: Row(children: [
                            Icon(Icons.flag_outlined, color: AppColors.accentOrange, size: 16),
                            const SizedBox(width: 4),
                            const Text('Importante'),
                          ])),
                      DropdownMenuItem(
                          value: 'normal',
                          child: Row(children: [
                            Icon(Icons.low_priority, color: AppColors.primaryBlue, size: 16),
                            const SizedBox(width: 4),
                            const Text('Normal'),
                          ])),
                    ],
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
                const SizedBox(width: 10),
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
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                if (_type == 'conta')
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Valor (R\$)',
                          prefixIcon: Icon(Icons.attach_money)),
                    ),
                  ),
                if (_type == 'conta') const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _dueDate = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Vencimento',
                          prefixIcon: Icon(Icons.event_outlined)),
                      child: Text(
                        _dueDate != null
                            ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                            : 'Selecionar',
                        style: TextStyle(
                            fontSize: 14,
                            color: _dueDate != null
                                ? AppColors.textDark
                                : AppColors.textLight),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Observação',
                  prefixIcon: Icon(Icons.notes_outlined)),
            ),
            const SizedBox(height: 12),

            // ── Recorrência ───────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _recurrenceType,
              decoration: const InputDecoration(
                labelText: 'Recorrência',
                prefixIcon: Icon(Icons.repeat_rounded),
              ),
              items: _recurrenceOptions
                  .map((opt) => DropdownMenuItem(
                        value: opt.$1,
                        child: Text(opt.$2),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _recurrenceType = v!),
            ),
            if (_recurrenceType != 'nenhuma') ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ao concluir, uma nova tarefa será criada automaticamente com a próxima data.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    context.read<UrgentTaskProvider>().add(UrgentTask(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      type: _type,
      priority: _priority,
      dueDate: _dueDate,
      amount: _amountCtrl.text.isNotEmpty
          ? double.tryParse(_amountCtrl.text.replaceAll(',', '.'))
          : null,
      note: _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
      category: _category,
      recurrenceType: _recurrenceType,
      nextOccurrence: _calcularProximaOcorrencia(_dueDate, _recurrenceType),
    ));
    Navigator.pop(context);
  }

  DateTime? _calcularProximaOcorrencia(DateTime? base, String tipo) {
    if (tipo == 'nenhuma' || base == null) return null;
    switch (tipo) {
      case 'diaria':  return base.add(const Duration(days: 1));
      case 'semanal': return base.add(const Duration(days: 7));
      case 'mensal':  return DateTime(base.year, base.month + 1, base.day);
      case 'anual':   return DateTime(base.year + 1, base.month, base.day);
      default:        return null;
    }
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ),
    );
  }
}
