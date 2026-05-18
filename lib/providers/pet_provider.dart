import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/pet.dart';

class PetProvider extends ChangeNotifier {
  static const _boxPets        = 'pets';
  static const _boxVacinas     = 'pet_vacinas';
  static const _boxConsultas   = 'pet_consultas';
  static const _boxMedicamentos = 'pet_medicamentos';

  late Box<Pet>            _petsBox;
  late Box<PetVacina>      _vacinasBox;
  late Box<PetConsulta>    _consultasBox;
  late Box<PetMedicamento> _medicamentosBox;

  final _uuid = const Uuid();

  List<Pet>            get pets          => _petsBox.values.toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

  int get totalPets => _petsBox.length;

  Future<void> init() async {
    _petsBox          = await Hive.openBox<Pet>(_boxPets);
    _vacinasBox       = await Hive.openBox<PetVacina>(_boxVacinas);
    _consultasBox     = await Hive.openBox<PetConsulta>(_boxConsultas);
    _medicamentosBox  = await Hive.openBox<PetMedicamento>(_boxMedicamentos);
    notifyListeners();
  }

  // ── PETS ────────────────────────────────────────────────────────────────────

  Future<Pet> addPet({
    required String nome,
    String especie = 'cachorro',
    String raca = '',
    String sexo = 'macho',
    DateTime? nascimento,
    double peso = 0,
    bool castrado = false,
    String cor = '',
    String notas = '',
  }) async {
    final pet = Pet(
      id: _uuid.v4(),
      nome: nome,
      especie: especie,
      raca: raca,
      sexo: sexo,
      nascimento: nascimento,
      peso: peso,
      castrado: castrado,
      cor: cor,
      notas: notas,
      createdAt: DateTime.now(),
    );
    await _petsBox.put(pet.id, pet);
    notifyListeners();
    return pet;
  }

  Future<void> updatePet(Pet pet) async {
    await _petsBox.put(pet.id, pet);
    notifyListeners();
  }

  Future<void> deletePet(String petId) async {
    // Cascade delete
    final vacKeys = _vacinasBox.values
        .where((v) => v.petId == petId).map((v) => v.id).toList();
    for (final k in vacKeys) await _vacinasBox.delete(k);

    final conKeys = _consultasBox.values
        .where((c) => c.petId == petId).map((c) => c.id).toList();
    for (final k in conKeys) await _consultasBox.delete(k);

    final medKeys = _medicamentosBox.values
        .where((m) => m.petId == petId).map((m) => m.id).toList();
    for (final k in medKeys) await _medicamentosBox.delete(k);

    await _petsBox.delete(petId);
    notifyListeners();
  }

  // ── VACINAS ─────────────────────────────────────────────────────────────────

  List<PetVacina> getVacinas(String petId) {
    return _vacinasBox.values
        .where((v) => v.petId == petId)
        .toList()
      ..sort((a, b) => b.dataAplicacao.compareTo(a.dataAplicacao));
  }

  Future<void> addVacina({
    required String petId,
    required String nome,
    required DateTime dataAplicacao,
    DateTime? proximaDose,
    String veterinario = '',
    String notas = '',
  }) async {
    final v = PetVacina(
      id: _uuid.v4(),
      petId: petId,
      nome: nome,
      dataAplicacao: dataAplicacao,
      proximaDose: proximaDose,
      veterinario: veterinario,
      notas: notas,
      createdAt: DateTime.now(),
    );
    await _vacinasBox.put(v.id, v);
    notifyListeners();
  }

  Future<void> deleteVacina(String id) async {
    await _vacinasBox.delete(id);
    notifyListeners();
  }

  // ── CONSULTAS ───────────────────────────────────────────────────────────────

  List<PetConsulta> getConsultas(String petId) {
    return _consultasBox.values
        .where((c) => c.petId == petId)
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  Future<void> addConsulta({
    required String petId,
    required DateTime data,
    required String motivo,
    String veterinario = '',
    String clinica = '',
    String diagnostico = '',
    DateTime? proximaConsulta,
    String notas = '',
  }) async {
    final c = PetConsulta(
      id: _uuid.v4(),
      petId: petId,
      data: data,
      motivo: motivo,
      veterinario: veterinario,
      clinica: clinica,
      diagnostico: diagnostico,
      proximaConsulta: proximaConsulta,
      notas: notas,
      createdAt: DateTime.now(),
    );
    await _consultasBox.put(c.id, c);
    notifyListeners();
  }

  Future<void> deleteConsulta(String id) async {
    await _consultasBox.delete(id);
    notifyListeners();
  }

  // ── MEDICAMENTOS ────────────────────────────────────────────────────────────

  List<PetMedicamento> getMedicamentos(String petId) {
    return _medicamentosBox.values
        .where((m) => m.petId == petId)
        .toList()
      ..sort((a, b) {
        if (a.ativo != b.ativo) return a.ativo ? -1 : 1;
        return a.nome.compareTo(b.nome);
      });
  }

  Future<void> addMedicamento({
    required String petId,
    required String nome,
    String tipo = 'medicamento',
    String dose = '',
    String frequencia = '',
    DateTime? dataInicio,
    DateTime? dataFim,
    String notas = '',
  }) async {
    final m = PetMedicamento(
      id: _uuid.v4(),
      petId: petId,
      nome: nome,
      tipo: tipo,
      dose: dose,
      frequencia: frequencia,
      dataInicio: dataInicio,
      dataFim: dataFim,
      ativo: true,
      notas: notas,
      createdAt: DateTime.now(),
    );
    await _medicamentosBox.put(m.id, m);
    notifyListeners();
  }

  Future<void> toggleMedicamento(String id) async {
    final med = _medicamentosBox.get(id);
    if (med == null) return;
    med.ativo = !med.ativo;
    await _medicamentosBox.put(id, med);
    notifyListeners();
  }

  Future<void> deleteMedicamento(String id) async {
    await _medicamentosBox.delete(id);
    notifyListeners();
  }

  // ── ALERTAS (para dashboard) ─────────────────────────────────────────────────

  /// Vacinas vencidas ou a vencer em 30 dias
  int get alertasVacinas {
    int count = 0;
    for (final v in _vacinasBox.values) {
      if (v.isVencida || v.isProxima) count++;
    }
    return count;
  }

  /// Medicamentos ativos
  int get medicamentosAtivos =>
      _medicamentosBox.values.where((m) => m.ativo).length;
}
