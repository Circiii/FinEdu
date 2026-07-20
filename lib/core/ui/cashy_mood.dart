import '../../domain/engine/cashy_state.dart';
import 'tokens.dart';

/// Maparea din [CashyMood] către un path de asset al mascotei.
extension CashyMoodAsset on CashyMood {
  String get asset => switch (this) {
    CashyMood.happy => Cashy.cashyDefault,
    CashyMood.alert => Cashy.cashyPoint,
    CashyMood.worried => Cashy.cashyWorried,
  };
}
