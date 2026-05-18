// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasswordEntryAdapter extends TypeAdapter<PasswordEntry> {
  @override
  final int typeId = 6;

  @override
  PasswordEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasswordEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      username: fields[3] as String,
      password: fields[4] as String,
      url: fields[5] as String,
      note: fields[6] as String,
      createdAt: fields[7] as DateTime,
      extraField1Label: fields[8] as String,
      extraField1Value: fields[9] as String,
      extraField2Label: fields[10] as String,
      extraField2Value: fields[11] as String,
      extraField3Label: fields[12] as String,
      extraField3Value: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PasswordEntry obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
      ..write(obj.url)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.extraField1Label)
      ..writeByte(9)
      ..write(obj.extraField1Value)
      ..writeByte(10)
      ..write(obj.extraField2Label)
      ..writeByte(11)
      ..write(obj.extraField2Value)
      ..writeByte(12)
      ..write(obj.extraField3Label)
      ..writeByte(13)
      ..write(obj.extraField3Value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
