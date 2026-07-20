import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

/// Culorile, razele, umbrele și fonturile aplicației, într-un singur loc.
class C {
  // Fundal și suprafețe
  static const bg = Color(0xFFEAF1FB);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF3F8FF);
  static const inset = Color(0xFFE4EDFA);

  // Linii
  static const line = Color.fromRGBO(28, 66, 132, 0.10);
  static const line2 = Color.fromRGBO(28, 66, 132, 0.17);

  // Text
  static const text = Color(0xFF122340);
  static const text2 = Color(0xFF5C6F8D);
  static const text3 = Color(0xFF9AABC5);

  static const blue = Color(0xFF2B86FF);
  static const blueDeep = Color(0xFF1560D8);
  static const blueInk = Color(0xFFFFFFFF);
  static const blueSoft = Color.fromRGBO(43, 134, 255, 0.12);

  static const amber = Color(0xFFFFB020);
  static const amberDeep = Color(0xFFE08A00);
  static const amberInk = Color(0xFF3A2600);
  static const amberSoft = Color.fromRGBO(255, 176, 32, 0.16);

  static const danger = Color(0xFFFF5D6C);
  static const dangerDeep = Color(0xFFD63450);
  static const dangerInk = Color(0xFFFFFFFF);
  static const dangerSoft = Color.fromRGBO(255, 93, 108, 0.12);

  static const violet = Color(0xFF8B7BFF);
  static const violetDeep = Color(0xFF5D45E0);
  static const violetInk = Color(0xFFFFFFFF);
  static const violetSoft = Color.fromRGBO(139, 123, 255, 0.14);

  static const green = Color(0xFF22C55E);
  static const greenDeep = Color(0xFF12934A);
  static const greenInk = Color(0xFFFFFFFF);
  static const greenSoft = Color.fromRGBO(34, 197, 94, 0.14);

  static const sky = Color(0xFF33B6E6);
  static const skySoft = Color.fromRGBO(51, 182, 230, 0.14);

  // Culoarea categoriei din bara de buget
  static const catFood = Color(0xFFFF7A59);

  // Decupajul de sus al ecranului
  static const notch = Color(0xFF0B1526);
}

/// Razele colțurilor, de la carduri la butoane rotunde.
class R {
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 38.0;
  static const pill = 999.0;
}

/// Durate de animație. Regula: nimic din bucla de lecție peste [base].
/// Feedback-ul rapid ține ritmul; [emph]/[epic] sunt rezervate momentelor rare.
class Dur {
  static const tap = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const emph = Duration(milliseconds: 400);
  static const epic = Duration(milliseconds: 1200);
}

/// Umbrele clay, la fel ca box-shadow din CSS (offset, blur, spread, inset)
class Sh {
  static List<BoxShadow> card = const [
    BoxShadow(
      color: Color.fromRGBO(26, 64, 130, 0.34),
      offset: Offset(0, 22),
      blurRadius: 42,
      spreadRadius: -20,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.95),
      offset: Offset(0, 3),
      blurRadius: 3,
      inset: true,
    ),
    BoxShadow(
      color: Color.fromRGBO(70, 110, 180, 0.13),
      offset: Offset(0, -16),
      blurRadius: 22,
      spreadRadius: -12,
      inset: true,
    ),
  ];

  static List<BoxShadow> raise = const [
    BoxShadow(
      color: Color.fromRGBO(26, 64, 130, 0.26),
      offset: Offset(0, 12),
      blurRadius: 22,
      spreadRadius: -12,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.95),
      offset: Offset(0, 2),
      blurRadius: 2,
      inset: true,
    ),
    BoxShadow(
      color: Color.fromRGBO(70, 110, 180, 0.15),
      offset: Offset(0, -8),
      blurRadius: 12,
      spreadRadius: -8,
      inset: true,
    ),
  ];

  static List<BoxShadow> insetSoft = const [
    BoxShadow(
      color: Color.fromRGBO(50, 90, 160, 0.20),
      offset: Offset(0, 3),
      blurRadius: 7,
      inset: true,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.85),
      offset: Offset(0, -1.5),
      blurRadius: 1,
      inset: true,
    ),
  ];

  static List<BoxShadow> nav = const [
    BoxShadow(
      color: Color.fromRGBO(26, 64, 130, 0.40),
      offset: Offset(0, 20),
      blurRadius: 44,
      spreadRadius: -16,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.95),
      offset: Offset(0, 2),
      blurRadius: 2,
      inset: true,
    ),
  ];

  static List<BoxShadow> blue = const [
    BoxShadow(
      color: Color.fromRGBO(21, 96, 216, 0.50),
      offset: Offset(0, 14),
      blurRadius: 24,
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.55),
      offset: Offset(0, 3),
      blurRadius: 3,
      inset: true,
    ),
    BoxShadow(
      color: Color.fromRGBO(16, 70, 170, 0.50),
      offset: Offset(0, -9),
      blurRadius: 13,
      spreadRadius: -5,
      inset: true,
    ),
  ];

  static List<BoxShadow> amber = const [
    BoxShadow(
      color: Color.fromRGBO(224, 138, 0, 0.45),
      offset: Offset(0, 14),
      blurRadius: 24,
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.62),
      offset: Offset(0, 3),
      blurRadius: 3,
      inset: true,
    ),
    BoxShadow(
      color: Color.fromRGBO(170, 105, 0, 0.42),
      offset: Offset(0, -9),
      blurRadius: 13,
      spreadRadius: -5,
      inset: true,
    ),
  ];

  static List<BoxShadow> danger = const [
    BoxShadow(
      color: Color.fromRGBO(214, 52, 80, 0.40),
      offset: Offset(0, 14),
      blurRadius: 24,
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.50),
      offset: Offset(0, 3),
      blurRadius: 3,
      inset: true,
    ),
    BoxShadow(
      color: Color.fromRGBO(160, 35, 55, 0.40),
      offset: Offset(0, -9),
      blurRadius: 13,
      spreadRadius: -5,
      inset: true,
    ),
  ];

  static List<BoxShadow> violet = const [
    BoxShadow(
      color: Color.fromRGBO(93, 69, 224, 0.40),
      offset: Offset(0, 14),
      blurRadius: 24,
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.50),
      offset: Offset(0, 3),
      blurRadius: 3,
      inset: true,
    ),
    BoxShadow(
      color: Color.fromRGBO(70, 45, 170, 0.42),
      offset: Offset(0, -9),
      blurRadius: 13,
      spreadRadius: -5,
      inset: true,
    ),
  ];

  static List<BoxShadow> green = const [
    BoxShadow(
      color: Color.fromRGBO(18, 147, 74, 0.42),
      offset: Offset(0, 14),
      blurRadius: 24,
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.55),
      offset: Offset(0, 3),
      blurRadius: 3,
      inset: true,
    ),
    BoxShadow(
      color: Color.fromRGBO(10, 110, 55, 0.42),
      offset: Offset(0, -9),
      blurRadius: 13,
      spreadRadius: -5,
      inset: true,
    ),
  ];
}

/// Gradientele butoanelor: deschis sus, culoarea de bază la mijloc, închis jos.
class Grad {
  static LinearGradient blue = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.lerp(C.blue, Colors.white, 0.12)!, C.blue, C.blueDeep],
    stops: const [0.0, 0.52, 1.0],
  );
  static LinearGradient amber = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.lerp(C.amber, Colors.white, 0.12)!, C.amber, C.amberDeep],
    stops: const [0.0, 0.52, 1.0],
  );

  // Butoanele de răspuns din Dojo
  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF8794), C.danger, C.dangerDeep],
    stops: [0.0, 0.55, 1.0],
  );
  static const LinearGradient green = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4BE08A), C.green, C.greenDeep],
    stops: [0.0, 0.55, 1.0],
  );

  // Pastila de scor
  static const LinearGradient scorePill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF63A4FF), C.blue, C.blueDeep],
    stops: [0.0, 0.60, 1.0],
  );

  // Butonul rotund din mijlocul barei de jos
  static const LinearGradient navFab = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7FB4FF), C.blue, C.blueDeep],
    stops: [0.0, 0.55, 1.0],
  );

  // Inelul de progres, pe diagonală
  static const LinearGradient ring = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [C.blue, C.sky],
  );
  // Inelul de scor, aceleași culori inversate
  static const LinearGradient scoreRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [C.sky, C.blue],
  );
}

/// Helperi de tipografie. Display = Baloo 2, body = Plus Jakarta Sans.
/// Fonturile sunt incluse local (vezi pubspec `fonts:`). Numele de familie
/// trebuie să corespundă exact declarațiilor din pubspec.
class T {
  static const displayFamily = 'Baloo 2';
  static const bodyFamily = 'Plus Jakarta Sans';

  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = C.text,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: displayFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = C.text,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// Imaginile lui Cashy, pe stări.
class Cashy {
  static const base = 'assets/mascot/';
  static const cashyDefault = '${base}squirrel_happy.png'; // În formă (acorn)
  static const cashyStudy = '${base}squirrel_learning.png'; // Învață (laptop)
  static const cashyCelebrate =
      '${base}squirrel_celebration.png'; // Bucurie, după o reușită
  static const cashyPoint =
      '${base}squirrel_neutral.png'; // Ghid, arată cu mâna
  static const cashyWorried = '${base}squirrel_warning.png'; // Îngrijorat
}
