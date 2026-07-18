import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/tokens.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
import '../data/lessons_repository.dart';

// ---- Markup inline: **îngroșat** și ==evidențiat== (signaling, Mayer) ----

final _markup = RegExp(r'\*\*(.+?)\*\*|==(.+?)==');

/// Textul de lecție cu markup-ul redat: bold-ul primește greutate și culoare
/// plină, evidențierea primește fundal de marker galben.
class RichLessonText extends StatelessWidget {
  const RichLessonText(this.text,
      {super.key, required this.style, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final m in _markup.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(1),
          style: style.copyWith(fontWeight: FontWeight.w800, color: C.text),
        ));
      } else {
        spans.add(TextSpan(
          text: m.group(2),
          style: style.copyWith(
            fontWeight: FontWeight.w700,
            color: C.text,
            background: Paint()..color = C.amberSoft,
          ),
        ));
      }
      cursor = m.end;
    }
    if (spans.isEmpty) return Text(text, style: style, textAlign: textAlign);
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(TextSpan(style: style, children: spans),
        textAlign: textAlign);
  }
}

// ---- Widgeturi per tip de bloc ----

({Color soft, Color deep}) _tone(String tone) => switch (tone) {
      'amber' => (soft: C.amberSoft, deep: C.amberDeep),
      'green' => (soft: C.greenSoft, deep: C.greenDeep),
      'violet' => (soft: C.violetSoft, deep: C.violetDeep),
      'danger' => (soft: C.dangerSoft, deep: C.dangerDeep),
      _ => (soft: C.blueSoft, deep: C.blueDeep),
    };

class LessonBlockView extends StatelessWidget {
  const LessonBlockView(this.block, {super.key});

  final LessonBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      TextBlock(:final text) => RichLessonText(text,
          style: T.body(
              size: 15.5,
              weight: FontWeight.w400,
              color: C.text2,
              height: 1.55)),
      final CalloutBlock b => _callout(b),
      final StatBlock b => _stat(b),
      final VsBlock b => _vs(b),
      StepsBlock(:final items) => _steps(items),
      QuoteBlock(:final text) => _quote(text),
    };
  }

  Widget _callout(CalloutBlock b) {
    final tone = _tone(b.tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: C.surface, shape: BoxShape.circle, boxShadow: Sh.raise),
            alignment: Alignment.center,
            child: Text(b.icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.title != null) ...[
                  Text(b.title!.toUpperCase(),
                      style: T.display(
                          size: 11,
                          weight: FontWeight.w800,
                          color: tone.deep,
                          letterSpacing: 11 * 0.1)),
                  const SizedBox(height: 4),
                ],
                RichLessonText(b.text,
                    style: T.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: C.text,
                        height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(StatBlock b) {
    return ClayCard(
      radius: R.md,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            AnimatedCount(
              value: b.value,
              suffix: b.suffix,
              duration: Dur.emph,
              style: T.display(
                  size: 34, weight: FontWeight.w800, color: C.blueDeep),
            ),
            const SizedBox(height: 4),
            RichLessonText(b.label,
                textAlign: TextAlign.center,
                style: T.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: C.text2,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _vs(VsBlock b) {
    Widget side(String title, String text, Color soft, Color deep) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(R.sm),
            border: Border.all(color: C.line, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(),
                  style: T.display(
                      size: 11,
                      weight: FontWeight.w800,
                      color: deep,
                      letterSpacing: 11 * 0.08)),
              const SizedBox(height: 5),
              RichLessonText(text,
                  style: T.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: C.text,
                      height: 1.4)),
            ],
          ),
        ),
      );
    }

    // IntrinsicHeight egalizează coloanele când textele diferă ca lungime.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          side(b.leftTitle, b.leftText, C.amberSoft, C.amberDeep),
          const SizedBox(width: 10),
          side(b.rightTitle, b.rightText, C.blueSoft, C.blueDeep),
        ],
      ),
    );
  }

  Widget _steps(List<String> items) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                      gradient: Grad.blue,
                      shape: BoxShape.circle,
                      boxShadow: Sh.blue),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: T.display(
                          size: 13,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: RichLessonText(items[i],
                        style: T.body(
                            size: 14.5,
                            weight: FontWeight.w500,
                            color: C.text,
                            height: 1.4)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _quote(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const CashySprite(asset: Cashy.cashyPoint, width: 52),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(5),
              ),
              border: Border.all(color: C.line, width: 1),
              boxShadow: Sh.raise,
            ),
            child: RichLessonText(text,
                style: T.body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: C.text,
                    height: 1.45)),
          ),
        ),
      ],
    );
  }
}

// ---- Dezvăluire progresivă (segmenting, Mayer): un bloc per tap ----

/// Pagina de concept pe blocuri: primul bloc e vizibil, fiecare tap aduce
/// următorul; [trailing] (micro-check-ul) apare abia după ultimul bloc.
/// [onAllRevealed] anunță player-ul o singură dată.
class LessonBlocksPage extends StatefulWidget {
  const LessonBlocksPage({
    super.key,
    required this.blocks,
    required this.header,
    this.trailing,
    required this.onAllRevealed,
  });

  final List<LessonBlock> blocks;
  final Widget header;
  final Widget? trailing;
  final VoidCallback onAllRevealed;

  @override
  State<LessonBlocksPage> createState() => _LessonBlocksPageState();
}

class _LessonBlocksPageState extends State<LessonBlocksPage> {
  final _scroll = ScrollController();
  int _shown = 1;

  bool get _allShown => _shown >= widget.blocks.length;

  @override
  void initState() {
    super.initState();
    if (_allShown) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onAllRevealed());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _revealNext() {
    if (_allShown) return;
    Juice.tick();
    setState(() => _shown++);
    if (_allShown) widget.onAllRevealed();
    // Blocul nou intră sub fold, îl aducem în ecran după ce s-a așezat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: Dur.base, curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _allShown ? null : _revealNext,
      child: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.header,
            for (var i = 0; i < _shown && i < widget.blocks.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: StaggerIn(
                  // Doar prima construire e „intrare"; tap-urile următoare
                  // animă exclusiv blocul proaspăt dezvăluit.
                  index: 0,
                  child: LessonBlockView(widget.blocks[i]),
                ),
              ),
            if (!_allShown) _tapHint() else if (widget.trailing != null) ...[
              const SizedBox(height: 4),
              StaggerIn(child: widget.trailing!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tapHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: C.surface2,
            borderRadius: BorderRadius.circular(R.pill),
            border: Border.all(color: C.line, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Atinge pentru mai mult',
                  style: T.display(
                      size: 12.5, weight: FontWeight.w700, color: C.text3)),
              const SizedBox(width: 6),
              Text('•' * (widget.blocks.length - _shown),
                  style: T.display(
                      size: 12.5, weight: FontWeight.w800, color: C.blue)),
            ],
          ),
        ),
      ),
    );
  }
}
