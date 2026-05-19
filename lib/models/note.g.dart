// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 11;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      titulo: fields[1] as String,
      conteudo: fields[2] as String,
      criadoEm: fields[3] as DateTime,
      atualizadoEm: fields[4] as DateTime,
      cor: fields[5] as String,
      fixada: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titulo)
      ..writeByte(2)
      ..write(obj.conteudo)
      ..writeByte(3)
      ..write(obj.criadoEm)
      ..writeByte(4)
      ..write(obj.atualizadoEm)
      ..writeByte(5)
      ..write(obj.cor)
      ..writeByte(6)
      ..write(obj.fixada);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
