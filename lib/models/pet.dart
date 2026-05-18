import 'package:hive/hive.dart';

part 'pet.g.dart';

@HiveType(typeId: 7)
class Pet extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  String especie; // cachorro, gato, ave, peixe, roedor, reptil, outro

  @HiveField(3)
  String raca;

  @HiveField(4)
  String sexo; // macho, femea

  @HiveField(5)
  DateTime? nascimento;

  @HiveField(6)
  double peso;

  @HiveField(7)
  bool castrado;

  @HiveField(8)
  String cor;

  @HiveField(9)
  String notas;

  @HiveField(10)
  DateTime createdAt;

  Pet({
    required this.id,
    required this.nome,
    this.especie = 'cachorro',
    this.raca = '',
    this.sexo = 'macho',
    this.nascimento,
    this.peso = 0,
    this.castrado = false,
    this.cor = '',
    this.notas = '',
    required this.createdAt,
  });

  String get emoji {
    const m = {
      'cachorro': '🐶',
      'gato': '🐱',
      'ave': '🐦',
      'peixe': '🐠',
      'roedor': '🐹',
      'reptil': '🦎',
      'outro': '🐾',
    };
    return m[especie] ?? '🐾';
  }

  String get idade {
    if (nascimento == null) return '–';
    final now = DateTime.now();
    int anos = now.year - nascimento!.year;
    final mDiff = now.month - nascimento!.month;
    if (mDiff < 0 || (mDiff == 0 && now.day < nascimento!.day)) anos--;
    if (anos <= 0) {
      int meses = (now.year - nascimento!.year) * 12 + (now.month - nascimento!.month);
      if (meses <= 0) return 'Recém-nascido';
      return meses == 1 ? '1 mês' : '$meses meses';
    }
    return anos == 1 ? '1 ano' : '$anos anos';
  }
}

@HiveType(typeId: 8)
class PetVacina extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String petId;

  @HiveField(2)
  String nome;

  @HiveField(3)
  DateTime dataAplicacao;

  @HiveField(4)
  DateTime? proximaDose;

  @HiveField(5)
  String veterinario;

  @HiveField(6)
  String notas;

  @HiveField(7)
  DateTime createdAt;

  PetVacina({
    required this.id,
    required this.petId,
    required this.nome,
    required this.dataAplicacao,
    this.proximaDose,
    this.veterinario = '',
    this.notas = '',
    required this.createdAt,
  });

  bool get isVencida =>
      proximaDose != null && proximaDose!.isBefore(DateTime.now());

  bool get isProxima {
    if (proximaDose == null) return false;
    final diff = proximaDose!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }
}

@HiveType(typeId: 9)
class PetConsulta extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String petId;

  @HiveField(2)
  DateTime data;

  @HiveField(3)
  String veterinario;

  @HiveField(4)
  String clinica;

  @HiveField(5)
  String motivo;

  @HiveField(6)
  String diagnostico;

  @HiveField(7)
  DateTime? proximaConsulta;

  @HiveField(8)
  String notas;

  @HiveField(9)
  DateTime createdAt;

  PetConsulta({
    required this.id,
    required this.petId,
    required this.data,
    this.veterinario = '',
    this.clinica = '',
    required this.motivo,
    this.diagnostico = '',
    this.proximaConsulta,
    this.notas = '',
    required this.createdAt,
  });
}

@HiveType(typeId: 10)
class PetMedicamento extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String petId;

  @HiveField(2)
  String nome;

  @HiveField(3)
  String tipo; // medicamento, antipulgas, vermifugo, suplemento, outro

  @HiveField(4)
  String dose;

  @HiveField(5)
  String frequencia;

  @HiveField(6)
  DateTime? dataInicio;

  @HiveField(7)
  DateTime? dataFim;

  @HiveField(8)
  bool ativo;

  @HiveField(9)
  String notas;

  @HiveField(10)
  DateTime createdAt;

  PetMedicamento({
    required this.id,
    required this.petId,
    required this.nome,
    this.tipo = 'medicamento',
    this.dose = '',
    this.frequencia = '',
    this.dataInicio,
    this.dataFim,
    this.ativo = true,
    this.notas = '',
    required this.createdAt,
  });

  String get tipoEmoji {
    const m = {
      'antipulgas': '🦟',
      'vermifugo': '🪱',
      'suplemento': '🌿',
      'medicamento': '💊',
      'outro': '🔹',
    };
    return m[tipo] ?? '💊';
  }
}
