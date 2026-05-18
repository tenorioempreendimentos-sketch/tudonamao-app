import 'package:hive/hive.dart';

part 'urgent_task.g.dart';

@HiveType(typeId: 5)
class UrgentTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String type; // 'tarefa' ou 'conta'

  @HiveField(3)
  String priority; // 'urgente', 'importante', 'normal'

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  double? amount;

  @HiveField(6)
  bool isDone;

  @HiveField(7)
  String note;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String category;

  @HiveField(10)
  String recurrenceType; // 'nenhuma', 'diaria', 'semanal', 'mensal', 'anual'

  @HiveField(11)
  DateTime? nextOccurrence;

  UrgentTask({
    required this.id,
    required this.title,
    required this.type,
    this.priority = 'urgente',
    this.dueDate,
    this.amount,
    this.isDone = false,
    this.note = '',
    required this.createdAt,
    this.category = 'Geral',
    this.recurrenceType = 'nenhuma',
    this.nextOccurrence,
  });

  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isDone;

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }
}
