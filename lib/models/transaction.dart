import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String type; // 'receita' ou 'despesa'

  @HiveField(4)
  String category;

  @HiveField(5)
  String origin; // Origem da receita (cliente, projeto, etc.)

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  String description;

  @HiveField(8)
  bool isReceived; // Se já foi recebido/pago

  @HiveField(9)
  String paymentMethod;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.origin = '',
    required this.date,
    this.description = '',
    this.isReceived = true,
    this.paymentMethod = 'Dinheiro',
  });
}
