import 'package:hive/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 0)
class Appointment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String time;

  @HiveField(5)
  String category;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  String color;

  Appointment({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.time,
    this.category = 'Geral',
    this.isCompleted = false,
    this.color = 'blue',
  });
}
