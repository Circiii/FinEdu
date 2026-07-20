import 'dart:math' as math;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

import '../../../../core/ui/clay.dart';
import '../../../../core/ui/juice.dart';
import '../../../../core/ui/svg_icon.dart';
import '../../../../core/ui/tokens.dart';
import '../../../../core/utils/profanity.dart';
import '../../../../l10n/app_localizations.dart';
import 'onb_shared.dart';

/// Oul + ceremonia de eclozare: shake → burst → apariția lui Cashy, apoi [onHatched].
class EggStep extends StatefulWidget {
  const EggStep({super.key, required this.onHatched});

  final VoidCallback onHatched;

  @override
  State<EggStep> createState() => _EggStepState();
}

class _EggStepState extends State<EggStep> with TickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final AnimationController _hatch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _hatching = false;

  @override
  void dispose() {
    _shake.dispose();
    _hatch.dispose();
    super.dispose();
  }

  Future<void> _crack() async {
    if (_hatching) return;
    Juice.tick();
    setState(() => _hatching = true);
    await _shake.forward();
    await _hatch.forward();
    // Prima apariție a lui Cashy, moment epic, nu un tick oarecare.
    Juice.epic();
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (mounted) widget.onHatched();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OnbHalo(
                accent: C.amber,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_shake, _hatch]),
                  builder: (context, _) {
                    final t = _hatch.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (t > 0.1) _ConfettiBurst(progress: (t - 0.1) / 0.9),
                        // Oul: se scutură, apoi se micșorează și dispare.
                        if (t < 0.55)
                          Transform.translate(
                            offset: Offset(
                              math.sin(_shake.value * math.pi * 6) * 9,
                              0,
                            ),
                            child: Transform.rotate(
                              angle:
                                  math.sin(_shake.value * math.pi * 6) * 0.06,
                              child: Opacity(
                                opacity: 1 - (t / 0.55).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 1 - t * 0.5,
                                  child: const _ClayEgg(),
                                ),
                              ),
                            ),
                          ),
                        // Cashy apare.
                        if (t >= 0.4)
                          Transform.scale(
                            scale: Curves.easeOutBack.transform(
                              ((t - 0.4) / 0.6).clamp(0.0, 1.0),
                            ),
                            child: Image.asset(
                              Cashy.cashyDefault,
                              width: 196,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _hatching && _hatch.value > 0.4
                    ? OnbHeader(
                        key: const ValueKey('hatched'),
                        kicker: l10n.onbEggKicker,
                        title: l10n.onbHatchTitle,
                        body: '',
                        accent: C.amber,
                      )
                    : OnbHeader(
                        key: const ValueKey('egg'),
                        kicker: l10n.onbEggKicker,
                        title: l10n.onbEggTitle,
                        body: l10n.onbEggBody,
                        accent: C.amber,
                      ),
              ),
            ],
          ),
        ),
        ClayButton(
          label: l10n.onbEggCta,
          gradient: Grad.amber,
          shadow: Sh.amber,
          height: 60,
          fontSize: 18,
          onTap: _hatching ? null : _crack,
        ),
      ],
    );
  }
}

/// Oul desenat în stil clay (fără asset PNG).
class _ClayEgg extends StatelessWidget {
  const _ClayEgg();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 164,
      child: Stack(
        children: [
          Container(
            width: 132,
            height: 164,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.elliptical(66, 96),
                bottom: Radius.elliptical(66, 76),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF7E8),
                  Color(0xFFF6E3BF),
                  Color(0xFFEED3A4),
                ],
              ),
              boxShadow: Sh.card,
            ),
          ),
          // Reflex de lumină.
          Positioned(
            top: 22,
            left: 26,
            child: Container(
              width: 34,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Explozie radială de confetti (max ~18 particule, culori din paletă).
class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst({required this.progress});

  final double progress;

  static const _colors = [C.blue, C.amber, C.green, C.violet, C.sky, C.danger];

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    return Opacity(
      opacity: (1 - progress).clamp(0.0, 1.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 18; i++)
            Transform.translate(
              offset: Offset(
                math.cos(i * math.pi / 9) * 105 * eased,
                math.sin(i * math.pi / 9) * 105 * eased - 20 * eased,
              ),
              child: Container(
                width: i.isEven ? 9 : 6,
                height: i.isEven ? 9 : 6,
                decoration: BoxDecoration(
                  color: _colors[i % _colors.length],
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ceremonia de nume + culoare.
class CeremonyStep extends StatefulWidget {
  const CeremonyStep({super.key, required this.onDone});

  /// Apelat cu numele validat + cheia culorii.
  final void Function(String name, String color) onDone;

  @override
  State<CeremonyStep> createState() => _CeremonyStepState();
}

class _CeremonyStepState extends State<CeremonyStep>
    with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  String _color = 'sky';
  String? _error;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  static const _swatches = ['sky', 'mint', 'amber', 'violet'];

  @override
  void dispose() {
    _name.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final raw = _name.text.trim();
    final name = raw.isEmpty ? 'Cashy' : raw;
    if (isProfane(name)) {
      setState(() => _error = l10n.onbNameProfane);
      _shake.forward(from: 0);
      return;
    }
    Juice.tick();
    widget.onDone(name, _color);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pal = onbAccentFor(_color);
    final display = _name.text.trim().isEmpty ? 'Cashy' : _name.text.trim();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                OnbHalo(
                  accent: pal.accent,
                  size: 190,
                  child: Image.asset(
                    Cashy.cashyDefault,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                OnbHeader(
                  kicker: l10n.onbCeremonyKicker,
                  title: l10n.onbCeremonyTitle,
                  body: l10n.onbCeremonyBody,
                  accent: pal.accent,
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.onbNameLabel,
                    style: T.display(
                      size: 13,
                      weight: FontWeight.w700,
                      color: C.text2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shake(
                  animation: _shake,
                  child: ClayField(
                    controller: _name,
                    hint: l10n.onbNameHint,
                    maxLength: 12,
                    errorText: _error,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.onbColorLabel,
                    style: T.display(
                      size: 13,
                      weight: FontWeight.w700,
                      color: C.text2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final key in _swatches) ...[
                      GestureDetector(
                        onTap: () {
                          if (_color != key) Juice.tick();
                          setState(() => _color = key);
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: onbAccentFor(key).accent,
                            border: Border.all(
                              color: _color == key ? C.text : Colors.white,
                              width: _color == key ? 3 : 2,
                            ),
                            boxShadow: Sh.raise,
                          ),
                          child: _color == key
                              ? const Center(
                                  child: SvgIcon(
                                    Ic.check,
                                    size: 18,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        ClayButton(
          label: l10n.onbCeremonyCta(display),
          gradient: Grad.blue,
          shadow: Sh.blue,
          height: 60,
          fontSize: 18,
          onTap: _submit,
          trailing: const SvgIcon(
            Ic.arrowRight,
            size: 20,
            color: Colors.white,
            strokeWidth: 2.6,
          ),
        ),
      ],
    );
  }
}
