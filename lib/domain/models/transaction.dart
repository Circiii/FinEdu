import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// Tipul mișcării de bani. Oglindește CHECK-ul `type` de pe server.
enum TransactionType {
  expense,
  saving;

  String get key => name; // 'expense' | 'saving'

  static TransactionType fromKey(String key) => switch (key) {
        'expense' => TransactionType.expense,
        'saving' => TransactionType.saving,
        _ => throw ArgumentError('Unknown transaction type: $key'),
      };
}

/// Cum a fost înregistrată tranzacția. Oglindește CHECK-ul `source` de pe server.
enum TransactionSource {
  manual,
  receipt,
  voice,
  recurring;

  String get key => name;

  static TransactionSource fromKey(String key) => switch (key) {
        'manual' => TransactionSource.manual,
        'receipt' => TransactionSource.receipt,
        'voice' => TransactionSource.voice,
        'recurring' => TransactionSource.recurring,
        _ => throw ArgumentError('Unknown transaction source: $key'),
      };
}

/// Model de domeniu pur-Dart pentru o tranzacție. Agnostic de framework/
/// storage; maparea drift row <-> domain e în data layer (`TransactionMapper`).
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    /// uuid v4 client-generat. Devine `client_id` pe server, cheie de
    /// idempotență pentru sync (UNIQUE(user_id, client_id)).
    required String id,
    required double amount,
    required String category,
    @Default(TransactionType.expense) TransactionType type,
    String? merchant,
    String? note,
    required DateTime transactionDate,
    @Default(TransactionSource.manual) TransactionSource source,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool deleted,
    @Default(true) bool pendingSync,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
