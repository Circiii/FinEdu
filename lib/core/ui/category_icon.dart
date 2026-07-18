import 'package:flutter/material.dart';

import 'clay.dart';

/// Iconițele desenate ale categoriilor de cheltuieli (PNG cu fundal
/// transparent, assets/icons/cat_*.png). Cheile fără imagine întorc null,
/// iar situl de afișare cade pe iconița vectorială existentă.
String? categoryIconAsset(String category) => switch (category) {
  'mancare' => 'assets/icons/cat_mancare.png',
  'transport' => 'assets/icons/cat_transport.png',
  'distractie' => 'assets/icons/cat_distractie.png',
  // 'haine' e cheia canonică din baza de date, 'shopping' cheia din grilă.
  'shopping' || 'haine' => 'assets/icons/cat_shopping.png',
  'abonamente' => 'assets/icons/cat_abonamente.png',
  'sanatate' => 'assets/icons/cat_sanatate.png',
  'educatie' => 'assets/icons/cat_educatie.png',
  'altele' => 'assets/icons/cat_altele.png',
  _ => null,
};

/// Pătratul rotunjit al unei categorii: fundal colorat + imaginea desenată.
/// Categoriile fără imagine (economii, chirie) rămân pe [ClayIcon] vectorial.
class CategoryTileIcon extends StatelessWidget {
  const CategoryTileIcon({
    super.key,
    required this.category,
    required this.fallbackPath,
    required this.tint,
    required this.color,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 23,
    this.strokeWidth = 2,
  });

  final String category;
  final String fallbackPath;
  final Color tint;
  final Color color;
  final double size;
  final double radius;
  final double iconSize;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final asset = categoryIconAsset(category);
    if (asset == null) {
      return ClayIcon(
        path: fallbackPath,
        tint: tint,
        color: color,
        size: size,
        radius: radius,
        iconSize: iconSize,
        strokeWidth: strokeWidth,
      );
    }
    // Imaginea e mai bogată decât glyph-ul vectorial, îi dăm mai mult loc
    // în aceeași casetă (fără să atingă marginile).
    final imageSize = (iconSize * 1.45).clamp(0, size - 8).toDouble();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        asset,
        width: imageSize,
        height: imageSize,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
