import 'dart:math' as math;
import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/fmt.dart';

class _ChatMsg {
  final bool user;
  final String? text;
  final String? card; // 'chart' | 'donut' | 'sim'
  final List<String>? chips;
  const _ChatMsg({this.user = false, this.text, this.card, this.chips});
}

const _bars = [
  ('Mâncare', 38, Color(0xFFFF7A59)),
  ('Distracție', 20, Color(0xFF8B7BFF)),
  ('Transport', 16, Color(0xFF2B86FF)),
  ('Abonamente', 12, Color(0xFF22C55E)),
  ('Altele', 14, Color(0xFF8AA0BF)),
];

final Map<String, List<_ChatMsg>> _replies = {
  'Da, arată-mi': [
    const _ChatMsg(text: 'Perfect! Regula 50/30/20 pentru banii tăi:'),
    const _ChatMsg(card: 'donut'),
    const _ChatMsg(
      text: 'Adică ~120 lei/lună la economii. Vrei să vezi cât se strânge?',
      chips: ['Cât aș strânge?', 'Mulțumesc!'],
    ),
  ],
  'Cât aș strânge?': [
    const _ChatMsg(text: 'Hai să simulăm! Trage de cât pui deoparte lunar:'),
    const _ChatMsg(card: 'sim'),
    const _ChatMsg(
      text: 'Obiceiurile mici fac diferența mare. Începem?',
      chips: ['Sună bine!', 'Nu acum'],
    ),
  ],
  'Nu acum': [
    const _ChatMsg(
      text: 'E ok! Sunt aici oricând ai o întrebare despre bani.',
      chips: ['Arată cheltuielile'],
    ),
  ],
  'Mulțumesc!': [
    const _ChatMsg(
      text: 'Cu plăcere! Ține-o tot așa și scorul tău crește.',
      chips: ['Arată cheltuielile'],
    ),
  ],
  'Sună bine!': [
    const _ChatMsg(
      text: 'Super! Provocare setată: pune 10 lei/zi deoparte. Mult succes!',
      chips: ['Mulțumesc!'],
    ),
  ],
  'Arată cheltuielile': [
    const _ChatMsg(text: 'Sigur! Uite distribuția lunii tale:'),
    const _ChatMsg(card: 'chart'),
    const _ChatMsg(text: 'Vrei un plan?', chips: ['Da, arată-mi', 'Nu acum']),
  ],
};

class FinbotScreen extends StatefulWidget {
  const FinbotScreen({super.key});
  @override
  State<FinbotScreen> createState() => _FinbotScreenState();
}

class _FinbotScreenState extends State<FinbotScreen> {
  final _scroll = ScrollController();
  double simAmount = 150;
  final List<_ChatMsg> chat = [
    const _ChatMsg(
      text:
          'Salut! Sunt FinBot. Ți-am analizat luna, vrei să vezi unde se duc banii?',
    ),
    const _ChatMsg(card: 'chart'),
    const _ChatMsg(
      text: 'Mâncarea e 38% din buget, cam mult. Vrei un plan de economisire?',
      chips: ['Da, arată-mi', 'Cât aș strânge?', 'Nu acum'],
    ),
  ];

  void _send(String text) {
    setState(() {
      chat.add(_ChatMsg(user: true, text: text));
      chat.addAll(
        _replies[text] ??
            [
              const _ChatMsg(
                text:
                    'Bună întrebare! Momentan pot să-ți arăt cheltuielile și un plan de economisire.',
                chips: ['Arată cheltuielile'],
              ),
            ],
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          _header(),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              children: [for (final m in chat) _bubble(m)],
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: C.line, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: _iconBtn(Ic.chevronLeft, 17, 2.4),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFB3A7FF), C.violet, C.violetDeep],
                      stops: [0, 0.55, 1],
                    ),
                    borderRadius: BorderRadius.circular(R.sm),
                    boxShadow: Sh.violet,
                  ),
                  alignment: Alignment.center,
                  child: const SvgIcon(
                    Ic.star,
                    size: 26,
                    color: Colors.white,
                    fill: true,
                  ),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: C.green,
                      border: Border.all(color: C.bg, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FinBot',
                  style: T.display(
                    size: 18,
                    weight: FontWeight.w800,
                    color: C.text,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'activ acum',
                  style: T.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: C.green,
                  ),
                ),
              ],
            ),
          ),
          _iconBtn(Ic.more, 18, 2),
        ],
      ),
    );
  }

  Widget _iconBtn(String path, double size, double sw) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: C.surface,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: C.line, width: 1),
      boxShadow: Sh.raise,
    ),
    alignment: Alignment.center,
    child: SvgIcon(path, size: size, color: C.text2, strokeWidth: sw),
  );

  Widget _bubble(_ChatMsg m) {
    if (m.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 11),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            gradient: Grad.scorePill,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(6),
              bottomLeft: Radius.circular(18),
            ),
            boxShadow: Sh.blue,
          ),
          child: Text(
            m.text!,
            style: T.body(
              size: 14.5,
              weight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.text != null)
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.84,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(6),
                    ),
                    border: Border.all(color: C.line, width: 1),
                    boxShadow: Sh.raise,
                  ),
                  child: Text(
                    m.text!,
                    style: T.body(
                      size: 14.5,
                      weight: FontWeight.w400,
                      color: C.text,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          if (m.card == 'chart')
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _chartCard(),
            ),
          if (m.card == 'donut')
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _donutCard(),
            ),
          if (m.card == 'sim')
            Padding(padding: const EdgeInsets.only(top: 2), child: _simCard()),
          if (m.chips != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final c in m.chips!) _chip(c)],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        _send(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: C.violetSoft,
          borderRadius: BorderRadius.circular(R.pill),
          border: Border.all(color: C.line, width: 1),
          boxShadow: Sh.raise,
        ),
        child: Text(
          label,
          style: T.display(
            size: 13,
            weight: FontWeight.w700,
            color: C.violetDeep,
          ),
        ),
      ),
    );
  }

  Widget _chartCard() {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cheltuieli · Iulie',
            style: T.display(size: 13, weight: FontWeight.w800, color: C.text),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _bars.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == _bars.length - 1 ? 0 : 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _bars[i].$1,
                          maxLines: 1,
                          style: T.body(
                            size: 12,
                            weight: FontWeight.w600,
                            color: C.text2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        height: 10,
                        color: C.inset,
                        child: FractionallySizedBox(
                          widthFactor: _bars[i].$2 / 100,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _bars[i].$3,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${_bars[i].$2}%',
                      textAlign: TextAlign.right,
                      style: T.display(
                        size: 12,
                        weight: FontWeight.w800,
                        color: C.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _donutCard() {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 98,
            height: 98,
            child: CustomPaint(painter: _DonutPainter()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _donutLegend(C.blue, 'Nevoi', '50%'),
                const SizedBox(height: 9),
                _donutLegend(C.violet, 'Dorințe', '30%'),
                const SizedBox(height: 9),
                _donutLegend(C.green, 'Economii', '20%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _donutLegend(Color color, String label, String pct) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: T.body(size: 13, weight: FontWeight.w600, color: C.text2),
          ),
        ),
        Text(
          pct,
          style: T.display(size: 14, weight: FontWeight.w800, color: C.text),
        ),
      ],
    );
  }

  Widget _simCard() {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pui deoparte',
                style: T.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: C.text2,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${simAmount.round()}',
                    style: T.display(
                      size: 20,
                      weight: FontWeight.w800,
                      color: C.blue,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'lei/lună',
                    style: T.display(
                      size: 12,
                      weight: FontWeight.w800,
                      color: C.text3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 14,
              activeTrackColor: C.inset,
              inactiveTrackColor: C.inset,
              trackShape: const RoundedRectSliderTrackShape(),
              thumbShape: ClaySliderThumb(),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: 10,
              max: 500,
              value: simAmount,
              onChanged: (v) =>
                  setState(() => simAmount = (v / 10).round() * 10),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: C.greenSoft,
              borderRadius: BorderRadius.circular(R.sm),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: C.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const AcornIcon(size: 24),
                ),
                const SizedBox(width: 11),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'În 12 luni strângi',
                      style: T.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: C.text2,
                      ),
                    ),
                    Text(
                      '${fmtThousands(simAmount.round() * 12)} lei',
                      style: T.display(
                        size: 22,
                        weight: FontWeight.w800,
                        color: C.greenDeep,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: C.inset,
                borderRadius: BorderRadius.circular(R.pill),
                boxShadow: Sh.insetSoft,
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'Scrie un mesaj…',
                style: T.body(
                  size: 14,
                  weight: FontWeight.w400,
                  color: C.text3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB3A7FF), C.violet, C.violetDeep],
                stops: [0, 0.55, 1],
              ),
              boxShadow: Sh.violet,
            ),
            alignment: Alignment.center,
            child: const SvgIcon(
              Ic.send,
              size: 22,
              color: Colors.white,
              strokeWidth: 2.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = 15.9 / 42 * size.width;
    final sw = 7 / 42 * size.width;
    void seg(double startPct, double lenPct, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2 + 2 * math.pi * startPct,
        2 * math.pi * lenPct,
        false,
        paint,
      );
    }

    seg(0.0, 0.50, C.blue);
    seg(0.50, 0.30, C.violet);
    seg(0.80, 0.20, C.green);
  }

  @override
  bool shouldRepaint(_DonutPainter o) => false;
}
