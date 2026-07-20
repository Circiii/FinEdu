import '../../../core/db/app_db.dart';
import '../../../domain/models/transaction.dart';

/// Mapează între rândul drift (`LocalTransaction`) și modelul de domeniu
/// (`Transaction`); separat ca domeniul să rămână agnostic de storage.
extension LocalTransactionToDomain on LocalTransaction {
  Transaction toDomain() => Transaction(
    id: id,
    amount: amount,
    category: category,
    type: TransactionType.fromKey(type),
    merchant: merchant,
    note: note,
    transactionDate: transactionDate,
    source: TransactionSource.fromKey(source),
    createdAt: createdAt,
    updatedAt: updatedAt,
    deleted: deleted,
    pendingSync: pendingSync,
  );
}

extension DomainTransactionToRow on Transaction {
  LocalTransaction toRow() => LocalTransaction(
    id: id,
    amount: amount,
    category: category,
    type: type.key,
    merchant: merchant,
    note: note,
    transactionDate: transactionDate,
    source: source.key,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deleted: deleted,
    pendingSync: pendingSync,
  );
}
