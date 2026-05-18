import 'package:hive/hive.dart';

part 'password_entry.g.dart';

@HiveType(typeId: 6)
class PasswordEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String category; // 'Rede Social', 'Banco', 'Cartão', 'Email', 'Streaming', 'Outros'

  @HiveField(3)
  String username;

  @HiveField(4)
  String password;

  @HiveField(5)
  String url;

  @HiveField(6)
  String note;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String extraField1Label; // Ex: "Número do Cartão", "Agência"

  @HiveField(9)
  String extraField1Value;

  @HiveField(10)
  String extraField2Label; // Ex: "CVV", "Conta"

  @HiveField(11)
  String extraField2Value;

  @HiveField(12)
  String extraField3Label; // Ex: "CPF", "Validade"

  @HiveField(13)
  String extraField3Value;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.category,
    this.username = '',
    this.password = '',
    this.url = '',
    this.note = '',
    required this.createdAt,
    this.extraField1Label = '',
    this.extraField1Value = '',
    this.extraField2Label = '',
    this.extraField2Value = '',
    this.extraField3Label = '',
    this.extraField3Value = '',
  });
}
