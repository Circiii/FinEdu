// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: json['id'] as String,
  amount: (json['amount'] as num).toDouble(),
  category: json['category'] as String,
  type:
      $enumDecodeNullable(_$TransactionTypeEnumMap, json['type']) ??
      TransactionType.expense,
  merchant: json['merchant'] as String?,
  note: json['note'] as String?,
  transactionDate: DateTime.parse(json['transactionDate'] as String),
  source:
      $enumDecodeNullable(_$TransactionSourceEnumMap, json['source']) ??
      TransactionSource.manual,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deleted: json['deleted'] as bool? ?? false,
  pendingSync: json['pendingSync'] as bool? ?? true,
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'category': instance.category,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'merchant': instance.merchant,
      'note': instance.note,
      'transactionDate': instance.transactionDate.toIso8601String(),
      'source': _$TransactionSourceEnumMap[instance.source]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deleted': instance.deleted,
      'pendingSync': instance.pendingSync,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.expense: 'expense',
  TransactionType.saving: 'saving',
};

const _$TransactionSourceEnumMap = {
  TransactionSource.manual: 'manual',
  TransactionSource.receipt: 'receipt',
  TransactionSource.voice: 'voice',
  TransactionSource.recurring: 'recurring',
};
