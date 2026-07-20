import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/tokens.dart';
import '../../home/data/home_providers.dart';
import '../data/wardrobe_repository.dart';

/// Look-ul echipat al lui Cashy: culorile fundalului + emoji-ul accesoriului.
/// Itemele apar doar dacă sunt și deținute (un item dispărut din catalog e ignorat).
final equippedLookProvider = Provider<({List<Color>? bg, String? accessory})>((
  ref,
) {
  final profile = ref.watch(localProfileStreamProvider).valueOrNull;
  final catalog = ref.watch(wardrobeCatalogProvider('ro')).valueOrNull;
  final owned = ref.watch(ownedItemsProvider).valueOrNull ?? const <String>{};
  if (profile == null || catalog == null) {
    return (bg: null, accessory: null);
  }
  CosmeticItem? find(String? id) {
    if (id == null || !owned.contains(id)) return null;
    for (final i in catalog) {
      if (i.id == id) return i;
    }
    return null;
  }

  final bg = find(profile.equippedBackground);
  final acc = find(profile.equippedAccessory);
  return (
    bg: bg == null ? null : [for (final c in bg.colors) Color(c)],
    accessory: acc?.emoji,
  );
});

/// Mascota compusă: sprite-ul de stare + fundalul echipat + accesoriul,
/// punctul unic prin care Cashy apare „îmbrăcat" peste tot în aplicație.
class CashyAvatar extends ConsumerWidget {
  const CashyAvatar({
    super.key,
    required this.asset,
    required this.size,
    this.radius,
    this.fallback,
  });

  /// Sprite-ul de stare (mood-ul rămâne al contextului, garderoba doar
  /// îmbracă, nu schimbă emoția).
  final String asset;
  final double size;
  final double? radius;

  /// Gradientul afișat când niciun fundal nu e echipat (ex. culoarea lui
  /// Cashy aleasă la onboarding).
  final List<Color>? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(equippedLookProvider);
    final colors =
        look.bg ?? fallback ?? const [Color(0xFFDCE9F8), Color(0xFFC3D8F0)];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(radius ?? size * 0.26),
              boxShadow: Sh.raise,
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
          ),
          if (look.accessory != null)
            Positioned(
              top: -size * 0.10,
              right: -size * 0.06,
              child: Text(
                look.accessory!,
                style: TextStyle(fontSize: size * 0.34),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sprite-ul „îmbrăcat" fără fundal, pentru locurile unde Cashy stă liber în layout.
/// Ocupă exact lățimea cerută; accesoriul iese puțin în afară fără să mute vecinii.
class CashySprite extends ConsumerWidget {
  const CashySprite({super.key, required this.asset, required this.width});

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessory = ref.watch(
      equippedLookProvider.select((l) => l.accessory),
    );
    final image = Image.asset(asset, width: width);
    if (accessory == null) return image;
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          image,
          Positioned(
            top: -width * 0.14,
            right: -width * 0.05,
            child: Text(accessory, style: TextStyle(fontSize: width * 0.30)),
          ),
        ],
      ),
    );
  }
}
