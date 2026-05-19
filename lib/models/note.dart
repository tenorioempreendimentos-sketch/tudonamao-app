import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 11)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String titulo;

  @HiveField(2)
  late String conteudo;

  @HiveField(3)
  late DateTime criadoEm;

  @HiveField(4)
  late DateTime atualizadoEm;

  @HiveField(5)
  late String cor; // hex da cor do cartão

  @HiveField(6)
  late bool fixada;

  Note({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.criadoEm,
    required this.atualizadoEm,
    this.cor = '#1E3A5F',
    this.fixada = false,
  });
}
