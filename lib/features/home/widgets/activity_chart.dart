import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/activity.dart';

/// "Your activity" card: grouped daily bars (lessons read vs videos watched) with period totals.
class ActivityChartCard extends StatefulWidget {
  final StudentActivity activity;
  const ActivityChartCard({super.key, required this.activity});

  @override
  State<ActivityChartCard> createState() => _ActivityChartCardState();
}

class _ActivityChartCardState extends State<ActivityChartCard> {
  int? _selected;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String _label(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final empty = a.lessonsRead == 0 && a.videosWatched == 0;
    final selected = _selected != null && _selected! < a.series.length ? a.series[_selected!] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Your activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Text('Last ${a.days} days', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Total(value: a.lessonsRead, label: 'Lessons finished', color: AppColors.accentBlue),
              const SizedBox(width: 12),
              _Total(value: a.videosWatched, label: 'Videos finished', color: AppColors.accentOrange),
              const SizedBox(width: 12),
              _Total(value: a.activeDays, label: 'Active days', color: AppColors.accentGreen),
            ],
          ),
          const SizedBox(height: 16),
          if (empty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Finish a lesson or watch a video to the end and your activity will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 140,
              child: LayoutBuilder(
                builder: (context, c) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) {
                    final slot = (c.maxWidth - 24) / a.series.length;
                    final i = ((d.localPosition.dx - 24) / slot).floor();
                    setState(() => _selected = (i < 0 || i >= a.series.length || i == _selected) ? null : i);
                  },
                  child: CustomPaint(
                    size: Size(c.maxWidth, 140),
                    painter: _BarsPainter(a.series, _selected, _label),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Legend(color: AppColors.accentBlue, text: 'Lessons'),
                const SizedBox(width: 14),
                _Legend(color: AppColors.accentOrange, text: 'Videos'),
                const Spacer(),
                if (selected != null)
                  Text(
                    '${_label(selected.date)}: ${selected.lessons} lessons, ${selected.videos} videos',
                    style: const TextStyle(fontSize: 12),
                  )
                else
                  Text('Tap a day for details', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Total({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      );
}

class _BarsPainter extends CustomPainter {
  final List<ActivityDay> series;
  final int? selected;
  final String Function(DateTime) label;
  _BarsPainter(this.series, this.selected, this.label);

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    const left = 24.0, bottom = 20.0, top = 6.0;
    final plotH = size.height - bottom - top;
    final maxV = math.max(3, series.fold<int>(0, (m, d) => math.max(m, math.max(d.lessons, d.videos))));
    final slot = (size.width - left) / series.length;
    final barW = math.max(2.0, math.min(10.0, slot * 0.36));

    final grid = Paint()..color = AppColors.border..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    void text(String s, Offset o, {TextAlign align = TextAlign.left}) {
      tp.text = TextSpan(text: s, style: TextStyle(color: AppColors.textSecondary, fontSize: 10));
      tp.layout();
      final dx = align == TextAlign.right ? o.dx - tp.width : align == TextAlign.center ? o.dx - tp.width / 2 : o.dx;
      tp.paint(canvas, Offset(dx, o.dy));
    }

    for (final f in [0.0, 0.5, 1.0]) {
      final y = top + plotH * (1 - f);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      text('${(maxV * f).round()}', Offset(left - 4, y - 6), align: TextAlign.right);
    }

    final step = math.max(1, (series.length / 5).ceil());
    for (var i = 0; i < series.length; i++) {
      final cx = left + slot * i + slot / 2;
      if (selected == i) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx - slot / 2, top, slot, plotH), const Radius.circular(4)),
          Paint()..color = AppColors.surfaceElevated,
        );
      }
      void bar(int v, double dx, Color c) {
        if (v <= 0) return;
        final h = plotH * v / maxV;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx + dx, top + plotH - h, barW, h),
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          Paint()..color = c,
        );
      }

      bar(series[i].lessons, -barW - 1, AppColors.accentBlue);
      bar(series[i].videos, 1, AppColors.accentOrange);
      if (i % step == 0 || i == series.length - 1) {
        text(label(series[i].date), Offset(cx, size.height - 14), align: TextAlign.center);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => old.series != series || old.selected != selected;
}
