// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'urgent_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UrgentTaskAdapter extends TypeAdapter<UrgentTask> {
  @override
  final int typeId = 5;

  @override
  UrgentTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UrgentTask(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      priority: fields[3] as String,
      dueDate: fields[4] as DateTime?,
      amount: fields[5] as double?,
      isDone: fields[6] as bool,
      note: fields[7] as String,
      createdAt: fields[8] as DateTime,
      category: fields[9] as String,
      recurrenceType: fields[10] as String,
      nextOccurrence: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UrgentTask obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.isDone)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.category)
      ..writeByte(10)
      ..write(obj.recurrenceType)
      ..writeByte(11)
      ..write(obj.nextOccurrence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UrgentTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
