import 'package:hive/hive.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 4)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  String unit;

  @HiveField(5)
  double? estimatedPrice;

  @HiveField(6)
  bool isChecked;

  @HiveField(7)
  String note;

  @HiveField(8)
  DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.unit = 'un',
    this.estimatedPrice,
    this.isChecked = false,
    this.note = '',
    required this.createdAt,
  });
}
