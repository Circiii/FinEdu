import 'package:flutter/material.dart';

/// Ghinda oficială a aplicației (PNG), moneda se vede identic peste tot:
/// balanțe, recompense, prețuri. Înlocuiește emoji-ul 🌰 și iconița vectorială.
class AcornIcon extends StatelessWidget {
  const AcornIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/icons/acorn.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      );
}

/// Text în care fiecare 🌰 devine imaginea ghindei, aliniată pe mijlocul
/// rândului. Stilul, alinierea și overflow-ul se comportă ca la [Text].
class AcornText extends StatelessWidget {
  const AcornText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final size = (style?.fontSize ?? 14) * 1.1;
    final parts = text.split('🌰');
    if (parts.length == 1) {
      return Text(text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow);
    }
    return Text.rich(
      TextSpan(style: style, children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: AcornIcon(size: size),
              ),
            ),
          if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
        ],
      ]),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
