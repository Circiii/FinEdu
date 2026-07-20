import 'package:flutter/material.dart';

/// Flacăra oficială a streak-ului (PNG), aceeași imagine peste tot unde apare
/// focul: chip-ul de pe Acasă, Arcade, Profil, Dojo și ecranul de streak.
class FlameIcon extends StatelessWidget {
  const FlameIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icons/flame.png',
    width: size,
    height: size,
    // Desenul e mai înalt decât lat: îl încadrăm fără să-l turtim, iar
    // cutia rămâne pătrată, ca să nu se miște nimic în jurul lui.
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
  );
}
