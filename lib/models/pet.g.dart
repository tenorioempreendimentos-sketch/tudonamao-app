// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetAdapter extends TypeAdapter<Pet> {
  @override
  final int typeId = 7;

  @override
  Pet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pet(
      id: fields[0] as String,
      nome: fields[1] as String,
      especie: fields[2] as String,
      raca: fields[3] as String,
      sexo: fields[4] as String,
      nascimento: fields[5] as DateTime?,
      peso: fields[6] as double,
      castrado: fields[7] as bool,
      cor: fields[8] as String,
      notas: fields[9] as String,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Pet obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.especie)
      ..writeByte(3)
      ..write(obj.raca)
      ..writeByte(4)
      ..write(obj.sexo)
      ..writeByte(5)
      ..write(obj.nascimento)
      ..writeByte(6)
      ..write(obj.peso)
      ..writeByte(7)
      ..write(obj.castrado)
      ..writeByte(8)
      ..write(obj.cor)
      ..writeByte(9)
      ..write(obj.notas)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PetVacinaAdapter extends TypeAdapter<PetVacina> {
  @override
  final int typeId = 8;

  @override
  PetVacina read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetVacina(
      id: fields[0] as String,
      petId: fields[1] as String,
      nome: fields[2] as String,
      dataAplicacao: fields[3] as DateTime,
      proximaDose: fields[4] as DateTime?,
      veterinario: fields[5] as String,
      notas: fields[6] as String,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PetVacina obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.petId)
      ..writeByte(2)
      ..write(obj.nome)
      ..writeByte(3)
      ..write(obj.dataAplicacao)
      ..writeByte(4)
      ..write(obj.proximaDose)
      ..writeByte(5)
      ..write(obj.veterinario)
      ..writeByte(6)
      ..write(obj.notas)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetVacinaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PetConsultaAdapter extends TypeAdapter<PetConsulta> {
  @override
  final int typeId = 9;

  @override
  PetConsulta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetConsulta(
      id: fields[0] as String,
      petId: fields[1] as String,
      data: fields[2] as DateTime,
      veterinario: fields[3] as String,
      clinica: fields[4] as String,
      motivo: fields[5] as String,
      diagnostico: fields[6] as String,
      proximaConsulta: fields[7] as DateTime?,
      notas: fields[8] as String,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PetConsulta obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.petId)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.veterinario)
      ..writeByte(4)
      ..write(obj.clinica)
      ..writeByte(5)
      ..write(obj.motivo)
      ..writeByte(6)
      ..write(obj.diagnostico)
      ..writeByte(7)
      ..write(obj.proximaConsulta)
      ..writeByte(8)
      ..write(obj.notas)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetConsultaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PetMedicamentoAdapter extends TypeAdapter<PetMedicamento> {
  @override
  final int typeId = 10;

  @override
  PetMedicamento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetMedicamento(
      id: fields[0] as String,
      petId: fields[1] as String,
      nome: fields[2] as String,
      tipo: fields[3] as String,
      dose: fields[4] as String,
      frequencia: fields[5] as String,
      dataInicio: fields[6] as DateTime?,
      dataFim: fields[7] as DateTime?,
      ativo: fields[8] as bool,
      notas: fields[9] as String,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PetMedicamento obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.petId)
      ..writeByte(2)
      ..write(obj.nome)
      ..writeByte(3)
      ..write(obj.tipo)
      ..writeByte(4)
      ..write(obj.dose)
      ..writeByte(5)
      ..write(obj.frequencia)
      ..writeByte(6)
      ..write(obj.dataInicio)
      ..writeByte(7)
      ..write(obj.dataFim)
      ..writeByte(8)
      ..write(obj.ativo)
      ..writeByte(9)
      ..write(obj.notas)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetMedicamentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
