import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';

class VerseImageScreen extends StatefulWidget {
  const VerseImageScreen({
    super.key,
    required this.text,
    required this.reference,
    required this.lang,
  });
  final String text;
  final String reference;
  final String lang;

  @override
  State<VerseImageScreen> createState() => _VerseImageScreenState();
}

const _backgrounds = <List<Color>>[
  [Color(0xFF0E5A47), Color(0xFF0A3D30)],
  [Color(0xFF1E3C72), Color(0xFF2A5298)],
  [Color(0xFFC9962B), Color(0xFF8A5A12)],
  [Color(0xFF6A3093), Color(0xFFA044FF)],
  [Color(0xFFB3261E), Color(0xFF5E0F0B)],
  [Color(0xFF232526), Color(0xFF414345)],
  [Color(0xFFF6EEDC), Color(0xFFE6D3A8)],
  [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
];

class _VerseImageScreenState extends State<VerseImageScreen> {
  final _key = GlobalKey();
  int _bg = 0;
  double _size = 22;
  TextAlign _align = TextAlign.center;
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 3);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              data!.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'verse.png',
            ),
          ],
          text: widget.reference,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final colors = _backgrounds[_bg];
    final light = _bg == 6;
    final fg = light ? Brand.sepiaText : Colors.white;
    return Scaffold(
      appBar: AppBar(title: Text(l('image'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RepaintBoundary(
            key: _key,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: _align == TextAlign.center
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: fg.withValues(alpha: 0.5),
                      size: 36,
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              widget.text,
                              textAlign: _align,
                              style: TextStyle(
                                fontFamily: scriptureFont(widget.lang),
                                fontSize: _size,
                                height: 1.45,
                                color: fg,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.reference,
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l('background'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _backgrounds.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _bg = i),
                child: Container(
                  width: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: _backgrounds[i]),
                    border: Border.all(
                      width: i == _bg ? 3 : 1,
                      color: i == _bg
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.text_fields),
              Expanded(
                child: Slider(
                  value: _size,
                  min: 14,
                  max: 34,
                  onChanged: (v) => setState(() => _size = v),
                ),
              ),
              SegmentedButton<TextAlign>(
                segments: const [
                  ButtonSegment(
                    value: TextAlign.start,
                    icon: Icon(Icons.format_align_left),
                  ),
                  ButtonSegment(
                    value: TextAlign.center,
                    icon: Icon(Icons.format_align_center),
                  ),
                ],
                selected: {_align},
                onSelectionChanged: (s) => setState(() => _align = s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: Text(l('shareImage')),
          ),
        ],
      ),
    );
  }
}
