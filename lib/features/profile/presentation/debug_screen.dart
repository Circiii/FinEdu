import 'package:flutter/material.dart';

import '../../../core/ui/acorn_celebration.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/tokens.dart';

/// Ecran de probă pentru animații. Intrarea spre el apare doar în build-ul de
/// dezvoltare, deci nu ajunge niciodată la utilizatori. Fără design intenționat:
/// e o listă de butoane, nimic mai mult.
class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Ploaia de ghinde'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => AcornCelebration.show(
              context,
              title: 'Unitate cucerită!',
              subtitle:
                  'Ai terminat toate lecțiile. Cardurile intră în '
                  'recapitulare, ca să nu le uiți.',
            ),
            child: const Text('Ploaie: unitate terminată'),
          ),
          ElevatedButton(
            onPressed: () => AcornCelebration.show(
              context,
              title: 'Cufărul e deschis!',
              subtitle:
                  '40 de ghinde îți cad în buzunar. Bifează din nou toate '
                  'misiunile și mâine ai altul.',
            ),
            child: const Text('Ploaie: cufăr'),
          ),
          ElevatedButton(
            onPressed: () => AcornCelebration.show(
              context,
              title: 'Ai dus luna la capăt!',
              subtitle:
                  'Scor 84 din 100. Uită-te pe raport să vezi unde ai '
                  'câștigat și unde te-a costat.',
            ),
            child: const Text('Ploaie: luna de 30 de zile'),
          ),
          ElevatedButton(
            onPressed: () => AcornCelebration.show(
              context,
              title: 'Titlu scurt',
              duration: const Duration(seconds: 20),
            ),
            child: const Text('Ploaie: 20 de secunde, fără subtitlu'),
          ),
          const SizedBox(height: 20),
          const Text('Altele'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ConfettiBurst.show(context),
            child: const Text('Confetti'),
          ),
          ElevatedButton(
            onPressed: Juice.epic,
            child: const Text('Haptic epic'),
          ),
          const SizedBox(height: 20),
          Text(
            'Ecranul ăsta există doar în build-ul de dezvoltare.',
            style: T.body(size: 12, weight: FontWeight.w500, color: C.text3),
          ),
        ],
      ),
    );
  }
}
