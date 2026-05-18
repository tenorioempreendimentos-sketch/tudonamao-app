import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class BudgetItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String description;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  String unit;

  @HiveField(4)
  double unitPrice;

  BudgetItem({
    required this.id,
    required this.description,
    required this.quantity,
    this.unit = 'un',
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

@HiveType(typeId: 3)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String clientName; // emitido: nome do cliente | recebido: nome do prestador

  @HiveField(3)
  String clientContact;

  @HiveField(4)
  List<BudgetItem> items;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? validUntil;

  @HiveField(7)
  String status; // 'rascunho', 'enviado', 'aprovado', 'recusado', 'analise', 'aceito', 'rejeitado'

  @HiveField(8)
  String notes;

  @HiveField(9)
  double discountPercent;

  @HiveField(10)
  String budgetType; // 'emitido' | 'recebido'

  @HiveField(11)
  String serviceCategory; // ex: 'Pedreiro', 'Elétrica', 'Pintura'...

  Budget({
    required this.id,
    required this.title,
    required this.clientName,
    this.clientContact = '',
    required this.items,
    required this.createdAt,
    this.validUntil,
    this.status = 'rascunho',
    this.notes = '',
    this.discountPercent = 0,
    this.budgetType = 'emitido',
    this.serviceCategory = '',
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get total => subtotal - discountAmount;

  bool get isRecebido => budgetType == 'recebido';
  bool get isEmitido => budgetType == 'emitido';
}
