import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../providers/agenda_provider.dart';
import '../models/appointment.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();
    final selectedEvents = provider.getByDate(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          // Toggle visão semanal / mensal
          IconButton(
            tooltip: _calendarFormat == CalendarFormat.week
                ? 'Visão mensal'
                : 'Visão semanal',
            icon: Icon(
              _calendarFormat == CalendarFormat.week
                  ? Icons.calendar_month_rounded
                  : Icons.view_week_rounded,
            ),
            onPressed: () => setState(() {
              _calendarFormat = _calendarFormat == CalendarFormat.week
                  ? CalendarFormat.month
                  : CalendarFormat.week;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () => setState(() {
              _selectedDay = DateTime.now();
              _focusedDay = DateTime.now();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Compromisso'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TableCalendar(
              locale: 'pt_BR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: (day) => provider.getByDate(day),
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.accentOrange,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: AppColors.danger),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                formatButtonTextStyle: TextStyle(color: AppColors.white, fontSize: 12),
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.event, color: AppColors.primaryBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat("dd 'de' MMMM", 'pt_BR').format(_selectedDay),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedEvents.length} evento${selectedEvents.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 48,
                            color: AppColors.textLight.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('Nenhum compromisso neste dia',
                            style: TextStyle(color: AppColors.textLight)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                  )
                : _AppointmentListView(events: selectedEvents),
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
      builder: (_) => AddAppointmentSheet(selectedDate: _selectedDay),
    );
  }
}

// ── Lista separada: pendentes primeiro, concluídos depois ────────────────────

class _AppointmentListView extends StatelessWidget {
  final List<Appointment> events;
  const _AppointmentListView({required this.events});

  @override
  Widget build(BuildContext context) {
    final pendentes  = events.where((a) => !a.isCompleted).toList();
    final concluidos = events.where((a) => a.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (pendentes.isNotEmpty) ...[
          if (concluidos.isNotEmpty)
            _ListLabel(
              label: 'Pendentes (${pendentes.length})',
              icon: Icons.pending_actions_rounded,
              color: AppColors.primaryBlue,
            ),
          ...pendentes.map((a) => _AppointmentCard(appointment: a)),
        ],
        if (concluidos.isNotEmpty) ...[
          _ListLabel(
            label: 'Concluídos (${concluidos.length})',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          ...concluidos.map((a) => _AppointmentCard(appointment: a)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ListLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _ListLabel({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AgendaProvider>();
    final categoryColors = {
      'Reunião': AppColors.primaryBlue,
      'Pessoal': AppColors.accentOrange,
      'Médico': AppColors.danger,
      'Financeiro': AppColors.success,
      'Geral': AppColors.primaryBlueMedium,
    };
    final color = categoryColors[appointment.category] ?? AppColors.primaryBlue;

    return Dismissible(
      key: Key(appointment.id),
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
      onDismissed: (_) => provider.delete(appointment.id),
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
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                decoration: appointment.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: appointment.isCompleted
                                    ? AppColors.textLight
                                    : AppColors.textDark,
                              ),
                            ),
                            if (appointment.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(appointment.description,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textMedium)),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(appointment.time,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: color,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(appointment.category,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: color,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: appointment.isCompleted,
                        activeColor: AppColors.success,
                        onChanged: (_) => provider.toggleComplete(appointment),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddAppointmentSheet extends StatefulWidget {
  final DateTime selectedDate;
  const AddAppointmentSheet({super.key, required this.selectedDate});

  @override
  State<AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<AddAppointmentSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Geral';
  TimeOfDay _time = TimeOfDay.now();
  final _categories = ['Geral', 'Reunião', 'Pessoal', 'Médico', 'Financeiro'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Novo Compromisso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Título *', prefixIcon: Icon(Icons.title)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: 'Descrição', prefixIcon: Icon(Icons.notes)),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Horário'),
                    child: Text(_time.format(context),
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Salvar Compromisso'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final provider = context.read<AgendaProvider>();
    provider.add(Appointment(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      date: widget.selectedDate,
      time: _time.format(context),
      category: _category,
    ));
    Navigator.pop(context);
  }
}
