// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetItemAdapter extends TypeAdapter<BudgetItem> {
  @override
  final int typeId = 2;

  @override
  BudgetItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetItem(
      id: fields[0] as String,
      description: fields[1] as String,
      quantity: fields[2] as double,
      unit: fields[3] as String,
      unitPrice: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.unitPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 3;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      id: fields[0] as String,
      title: fields[1] as String,
      clientName: fields[2] as String,
      clientContact: fields[3] as String,
      items: (fields[4] as List).cast<BudgetItem>(),
      createdAt: fields[5] as DateTime,
      validUntil: fields[6] as DateTime?,
      status: fields[7] as String,
      notes: fields[8] as String,
      discountPercent: fields[9] as double,
      budgetType: fields[10] as String,
      serviceCategory: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.clientName)
      ..writeByte(3)
      ..write(obj.clientContact)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.validUntil)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.discountPercent)
      ..writeByte(10)
      ..write(obj.budgetType)
      ..writeByte(11)
      ..write(obj.serviceCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
