/// PRNG determinist SplitMix64 pentru „30 de Zile", trebuie să dea același
/// run din același seed, pe orice telefon.
///
/// Ne bazăm pe int-ul 64-biți nativ al Dart (mod 2^64, ca în C). Shift-urile
/// din finalizer sunt UNSIGNED (`>>>`), obligatoriu, altfel semnul s-ar
/// extinde și ar strica valorile. Zero BigInt: rezultatul e identic bit-cu-bit
/// pe VM, AOT și desktop.
library;

class LifeSimRng {
  /// Pornește din [seed]. Starea internă începe de la seed; primul [nextU64]
  /// avansează cu γ înainte de a amesteca (convenția SplitMix64).
  LifeSimRng(int seed)
      : _seed = seed,
        _state = seed;

  /// Reconstituie un generator dintr-o stare brută (folosit intern de [fork]).
  LifeSimRng._fromState(this._seed, this._state);

  static const int _gamma = 0x9E3779B97F4A7C15;

  /// Seed-ul original, imuabil, [fork] derivă din EL, nu din starea curentă,
  /// ca `LifeSimRng(seed).fork(zi)` să dea mereu același sub-generator
  /// indiferent câte extrageri a consumat părintele între timp.
  final int _seed;
  int _state;

  /// Următorul u64 brut (biții pot arăta „negativ" în reprezentarea cu semn,
  /// e normal, e doar tiparul de biți). Avansează starea.
  int nextU64() {
    _state += _gamma;
    return _mix(_state);
  }

  /// Finalizer-ul SplitMix64: două runde de (xor cu shift-ul propriu) ×
  /// constantă, apoi un xor final. `>>>` = shift dreapta fără semn.
  static int _mix(int z) {
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }

  /// Întreg în [0, bound). `>>> 1` ridică semnul → valoare pe 63 biți mereu
  /// pozitivă; modulo introduce un bias infim (neglijabil la bound-urile mici
  /// ale jocului).
  int nextInt(int bound) {
    assert(bound > 0, 'bound trebuie să fie pozitiv');
    return (nextU64() >>> 1) % bound;
  }

  /// Double în [0, 1). Metoda canonică: cei mai semnificativi 53 de biți
  /// (mantisa unui double) împărțiți la 2^53, uniform, fără găuri.
  double nextDouble() => (nextU64() >>> 11) * (1.0 / (1 << 53));

  /// Un sub-generator independent pentru [streamId] (ex. ziua), derivat din
  /// seed-ul original, nu din starea curentă a părintelui.
  LifeSimRng fork(int streamId) {
    final combined = _mix(_seed ^ _mix(streamId + _gamma));
    return LifeSimRng._fromState(combined, combined);
  }
}
