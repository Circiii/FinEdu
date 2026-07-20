/// PRNG determinist SplitMix64 pentru „30 de Zile": același seed trebuie să
/// dea aceeași rundă pe orice platformă, inclusiv în browser.
///
/// Aritmetica pe 64 de biți e făcută de mână, pe două jumătăți de câte 32 de
/// biți. Motivul: în JavaScript toate numerele sunt double-uri, deci un `int`
/// din Dart ține exact doar 53 de biți acolo. Cu întregi de 64 de biți nativi
/// codul ar da alte numere în browser decât pe telefon, iar o rundă începută
/// pe Android ar arăta alte evenimente dacă o deschizi pe web.
///
/// Înmulțirea sparge fiecare jumătate în sferturi de câte 16 biți, ca niciun
/// produs parțial să nu depășească 53 de biți. Împărțirile și resturile sunt
/// exacte, iar `%` din Dart întoarce mereu un rezultat pozitiv pentru un
/// împărțitor pozitiv, ceea ce ține jumătățile în intervalul [0, 2^32).
///
/// Rezultatele sunt identice bit cu bit cu implementarea de 64 de biți de
/// dinainte; `test/life_sim_rng_test.dart` compară cu vectori de aur captați
/// din ea.
library;

import 'dart:math' as math;

/// O valoare pe 64 de biți, ca pereche de jumătăți fără semn de câte 32.
typedef _U64 = (int hi, int lo);

const int _p32 = 4294967296; // 2^32
const int _p16 = 65536; // 2^16
const double _p53 = 9007199254740992.0; // 2^53

/// Puterile lui 2 până la 2^32, calculate o dată la prima folosire. Nu
/// folosim `1 << n`, fiindcă în browser deplasarea lucrează pe 32 de biți
/// și s-ar pierde exact capătul de care avem nevoie.
final List<int> _pow2 = List<int>.generate(33, (i) => math.pow(2, i).toInt());

class LifeSimRng {
  /// Pornește din [seed]. Starea internă începe de la seed; primul rezultat
  /// avansează cu γ înainte de a amesteca (convenția SplitMix64).
  ///
  /// În browser un `int` ține exact doar 53 de biți, deci seed-urile trebuie
  /// să stea sub pragul ăsta ca runda să fie reproductibilă peste tot. Cele
  /// generate de joc pornesc din `millisecondsSinceEpoch`, adică vreo 41 de
  /// biți, deci încap cu mult loc de rezervă.
  LifeSimRng(int seed) : _seed = _lanes(seed), _state = _lanes(seed) {
    assert(
      seed.abs() < 9007199254740992,
      'seed trebuie să încapă în 53 de biți ca să dea aceeași rundă în browser',
    );
  }

  LifeSimRng._fromState(this._seed, this._state);

  /// Constantele SplitMix64, fiecare ca pereche de jumătăți.
  static const _U64 _gamma = (0x9E3779B9, 0x7F4A7C15);
  static const _U64 _c1 = (0xBF58476D, 0x1CE4E5B9);
  static const _U64 _c2 = (0x94D049BB, 0x133111EB);

  /// Seed-ul original, imuabil. [fork] derivă din EL, nu din starea curentă,
  /// ca `LifeSimRng(seed).fork(zi)` să dea mereu același sub-generator
  /// indiferent câte extrageri a consumat părintele între timp.
  final _U64 _seed;
  _U64 _state;

  // -------------------------------------------------------------------------
  // Aritmetică pe 64 de biți, în jumătăți de 32
  // -------------------------------------------------------------------------

  /// Readuce o valoare în intervalul [0, 2^32). Pe web operatorii pe biți pot
  /// întoarce un rezultat negativ, iar `%` îl aduce înapoi la complementul
  /// față de doi corect, deci merge la fel pe ambele platforme.
  static int _u32(int v) => v % _p32;

  /// Desface un `int` cu semn în cele două jumătăți ale reprezentării pe 64
  /// de biți în complement față de doi.
  static _U64 _lanes(int v) {
    final lo = v % _p32;
    return (((v - lo) ~/ _p32) % _p32, lo);
  }

  static _U64 _xor(_U64 a, _U64 b) => (_u32(a.$1 ^ b.$1), _u32(a.$2 ^ b.$2));

  static _U64 _add(_U64 a, _U64 b) {
    final lo = a.$2 + b.$2;
    final carry = lo >= _p32 ? 1 : 0;
    return (_u32(a.$1 + b.$1 + carry), lo - carry * _p32);
  }

  /// Deplasare la dreapta fără semn, cu [n] între 1 și 63.
  static _U64 _shr(_U64 a, int n) {
    if (n >= 32) return (0, a.$1 ~/ _pow2[n - 32]);
    final k = _pow2[n];
    return (a.$1 ~/ k, (a.$1 % k) * _pow2[32 - n] + a.$2 ~/ k);
  }

  /// Cei mai puțin semnificativi 64 de biți ai produsului. Fiecare jumătate se
  /// sparge în două sferturi de 16 biți, așa că produsele parțiale rămân sub
  /// 2^34 și încap exact într-un double.
  static _U64 _mul(_U64 a, _U64 b) {
    final a0 = a.$2 % _p16, a1 = a.$2 ~/ _p16;
    final a2 = a.$1 % _p16, a3 = a.$1 ~/ _p16;
    final b0 = b.$2 % _p16, b1 = b.$2 ~/ _p16;
    final b2 = b.$1 % _p16, b3 = b.$1 ~/ _p16;

    final c0 = a0 * b0;
    var c1 = a0 * b1 + a1 * b0;
    var c2 = a0 * b2 + a1 * b1 + a2 * b0;
    var c3 = a0 * b3 + a1 * b2 + a2 * b1 + a3 * b0;

    final r0 = c0 % _p16;
    c1 += c0 ~/ _p16;
    final r1 = c1 % _p16;
    c2 += c1 ~/ _p16;
    final r2 = c2 % _p16;
    c3 += c2 ~/ _p16;
    final r3 = c3 % _p16;

    return (r3 * _p16 + r2, r1 * _p16 + r0);
  }

  /// Finalizer-ul SplitMix64: două runde de (xor cu deplasarea proprie) ×
  /// constantă, apoi un xor final.
  static _U64 _mix(_U64 z) {
    z = _mul(_xor(z, _shr(z, 30)), _c1);
    z = _mul(_xor(z, _shr(z, 27)), _c2);
    return _xor(z, _shr(z, 31));
  }

  // -------------------------------------------------------------------------
  // Interfața publică
  // -------------------------------------------------------------------------

  /// Următoarea valoare brută pe 64 de biți. Avansează starea.
  _U64 _next() {
    _state = _add(_state, _gamma);
    return _mix(_state);
  }

  /// Următoarea valoare brută, ca 16 cifre hexazecimale. E forma exactă pe
  /// orice platformă, spre deosebire de un `int`, care în browser ar pierde
  /// biții de dincolo de 53. Folosită de teste; jocul cere numere prin
  /// [nextInt] și [nextDouble].
  String nextHex() {
    final v = _next();
    return v.$1.toRadixString(16).padLeft(8, '0') +
        v.$2.toRadixString(16).padLeft(8, '0');
  }

  /// Întreg în [0, bound). Prima deplasare ridică bitul de semn, deci valoarea
  /// e mereu pozitivă; restul introduce un bias infim, neglijabil la
  /// bound-urile mici ale jocului.
  ///
  /// Restul se calculează pe jumătăți, ca produsul intermediar să nu treacă de
  /// 53 de biți: de aici plafonul de 2^26 pe [bound], mult peste ce cere jocul.
  int nextInt(int bound) {
    assert(bound > 0, 'bound trebuie să fie pozitiv');
    assert(bound <= 67108864, 'bound trebuie să încapă în 26 de biți');
    final v = _shr(_next(), 1);
    return ((v.$1 % bound) * (_p32 % bound) + (v.$2 % bound)) % bound;
  }

  /// Double în [0, 1). Metoda canonică: cei mai semnificativi 53 de biți
  /// (mantisa unui double) împărțiți la 2^53, uniform, fără găuri.
  double nextDouble() {
    final v = _shr(_next(), 11);
    return (v.$1 * _p32 + v.$2) / _p53;
  }

  /// Un sub-generator independent pentru [streamId] (de exemplu ziua), derivat
  /// din seed-ul original, nu din starea curentă a părintelui.
  LifeSimRng fork(int streamId) {
    final combined = _mix(_xor(_seed, _mix(_add(_lanes(streamId), _gamma))));
    return LifeSimRng._fromState(combined, combined);
  }
}
