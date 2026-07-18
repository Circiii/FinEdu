import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/juice.dart';
import '../../../../core/ui/svg_icon.dart';
import '../../../../core/ui/tokens.dart';
import '../../../../domain/engine/life_sim/life_sim_commentary.dart';

/// Bara de sus comună celor trei ecrane „30 de Zile": buton de închidere + titlu.
Widget lifeMonthTopBar(BuildContext context, String title, {VoidCallback? onClose}) {
  return Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 4),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
            Juice.tick();
            if (onClose != null) {
              onClose();
            } else {
              context.pop();
            }
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.line, width: 1),
              boxShadow: Sh.raise,
            ),
            alignment: Alignment.center,
            child: const SvgIcon(Ic.x, size: 16, color: C.text2, strokeWidth: 2.4),
          ),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: T.display(size: 18, weight: FontWeight.w800, color: C.text)),
      ],
    ),
  );
}

/// Curăță o cheie brută de conținut ('masina_veche' → 'Masina veche') pentru
/// afișaj.
String lifeMonthPretty(String raw) {
  if (raw.isEmpty) return ', ';
  final spaced = raw.replaceAll('_', ' ').trim();
  if (spaced.isEmpty) return ', ';
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Etichete cu diacritice pentru id-urile snake_case de housing/transport din
/// roles.json. Orice id nou, necunoscut, cade pe [lifeMonthPretty] ca fallback.
const _housingTransportLabels = <String, String>{
  'chirie_colocatar': 'Chirie cu colocatar',
  'acasa_contributie': 'Stă cu părinții (contribuie)',
  'chirie_garsoniera': 'Garsonieră închiriată',
  'masina_veche': 'Mașină veche',
  'stb': 'Abonament STB',
  'pe_jos': 'Mers pe jos',
};

/// Display label pentru id-ul de housing/transport al unui rol.
String lifeMonthHousingTransportLabel(String raw) =>
    _housingTransportLabels[raw] ?? lifeMonthPretty(raw);

/// Mapează cheia de ilustrație a unui eveniment la un sprite Cashy, pe
/// cuvinte-cheie, cu [difficulty] ca semnal secundar și `cashyPoint` fallback.
String cashyForIllustration(String illustration, {int difficulty = 1}) {
  final k = illustration.toLowerCase();
  bool has(List<String> words) => words.any(k.contains);

  if (has(['celebr', 'bonus', 'win', 'reward', 'gift', 'happy', 'prize', 'lucky'])) {
    return Cashy.cashyCelebrate;
  }
  if (has([
    'scam',
    'phish',
    'danger',
    'warn',
    'worried',
    'sick',
    'health',
    'bill',
    'debt',
    'fine',
    'broke',
    'stress',
    'fraud',
    'theft',
  ])) {
    return Cashy.cashyWorried;
  }
  if (has(['work', 'study', 'learn', 'job', 'office', 'laptop'])) {
    return Cashy.cashyStudy;
  }
  // Fără cheie utilă: intensitatea decide tonul.
  if (illustration.isEmpty) {
    return difficulty >= 2 ? Cashy.cashyWorried : Cashy.cashyPoint;
  }
  return Cashy.cashyPoint;
}

/// Mapează mood-ul din motorul de comentarii la sprite-ul lui Cashy, folosit
/// și pe ecranul de joc, și pe raport, ca interpretarea să nu diverge.
String assetForCashyMood(CashyMoodGame mood) => switch (mood) {
      CashyMoodGame.happy => Cashy.cashyDefault,
      CashyMoodGame.worried => Cashy.cashyWorried,
      CashyMoodGame.thinking => Cashy.cashyStudy,
      CashyMoodGame.celebrate => Cashy.cashyCelebrate,
    };

/// Scale-in la apariție (0.8 → 1.0) care respectă reduce-motion (instant).
/// JuiceBounce sare pe schimbarea trigger-ului; asta animează prima afișare.
class LifeMonthScaleIn extends StatefulWidget {
  const LifeMonthScaleIn({
    super.key,
    required this.child,
    this.duration = Dur.emph,
  });

  final Widget child;
  final Duration duration;

  @override
  State<LifeMonthScaleIn> createState() => _LifeMonthScaleInState();
}

class _LifeMonthScaleInState extends State<LifeMonthScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _scale = Tween<double>(begin: 0.82, end: 1.0)
      .chain(CurveTween(curve: Curves.easeOutBack))
      .animate(_c);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
