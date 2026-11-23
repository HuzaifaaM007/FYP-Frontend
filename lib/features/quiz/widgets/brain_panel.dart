import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/brain.dart';

/// The 5 BRAIN steps for one question, shown as a vertical stepper.
class BrainPanel extends StatelessWidget {
  final BrainWalkthrough w;
  const BrainPanel({super.key, required this.w});

  @override
  Widget build(BuildContext context) {
    final steps = <_Step>[
      _Step('B', 'Breakdown', 'What is really being asked', AppColors.accentPurple, [
        Text(w.breakdown, style: _body()),
        if (w.keywords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: w.keywords
                .map((k) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(k, style: TextStyle(fontSize: 12, color: AppColors.accentPurple, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ]),
      _Step('R', 'Research', 'What you already know', AppColors.accentBlue, [Text(w.research, style: _body())]),
      if (w.assess.isNotEmpty)
        _Step('A', 'Assess', 'Check every option', AppColors.accentOrange, [
          ...w.assess.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(o.eliminate ? Icons.close_rounded : Icons.check_rounded,
                        size: 18, color: o.eliminate ? AppColors.error : AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: o.option,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: o.eliminate ? AppColors.textSecondary : AppColors.textPrimary,
                              decoration: o.eliminate ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          TextSpan(text: '  ${o.reason}', style: TextStyle(color: AppColors.textSecondary)),
                        ]),
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ]),
      _Step('I', 'Identify', 'Rule out what cannot work', AppColors.accentPink, [Text(w.identify, style: _body())]),
      _Step('N', 'Nominate', 'Choose the best answer', AppColors.accentGreen, [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentGreen.withOpacity(0.5)),
          ),
          child: Text(w.nominate, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
        ),
        if (w.why.isNotEmpty) ...[const SizedBox(height: 6), Text(w.why, style: _body())],
      ]),
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) _StepTile(step: steps[i], last: i == steps.length - 1),
      ],
    );
  }

  TextStyle _body() => TextStyle(fontSize: 13, height: 1.45, color: AppColors.textPrimary);
}

class _Step {
  final String letter;
  final String title;
  final String subtitle;
  final Color color;
  final List<Widget> children;
  _Step(this.letter, this.title, this.subtitle, this.color, this.children);
}

class _StepTile extends StatelessWidget {
  final _Step step;
  final bool last;
  const _StepTile({required this.step, required this.last});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: step.color, shape: BoxShape.circle),
                child: Text(step.letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (!last) Expanded(child: Container(width: 2, color: step.color.withOpacity(0.35))),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: step.title, style: TextStyle(fontWeight: FontWeight.bold, color: step.color)),
                    TextSpan(text: '  ${step.subtitle}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ])),
                  const SizedBox(height: 4),
                  ...step.children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "What is BRAIN?" explanation, written in our own words.
Future<void> showBrainIntro(BuildContext context) {
  final rows = [
    ('B', 'Breakdown', 'Read slowly. What is the one thing this question wants? Spot the words that stand out.'),
    ('R', 'Research', 'Connect those words to what you already learned in the lesson.'),
    ('A', 'Assess', 'Look at every option and judge how well it fits the question.'),
    ('I', 'Identify', 'Cross out options that cannot be right. Fewer choices = better odds.'),
    ('N', 'Nominate', 'Pick the best remaining answer, the one that matches the question most closely.'),
  ];
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text('The BRAIN method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Five quick steps for tackling any tough question, even when you are not sure.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Text(r.$1, style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${r.$2}: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        TextSpan(text: r.$3, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
                      ])),
                    ),
                  ]),
                )),
          ],
        ),
      ),
    ),
  );
}
