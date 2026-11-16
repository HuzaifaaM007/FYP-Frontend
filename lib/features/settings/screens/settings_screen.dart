import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_controller.dart';

/// Appearance settings: pick one of the built-in themes. The choice is saved on the device.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final current = ThemeController.instance.palette;
        return Scaffold(
          appBar: AppBar(title: const Text('Appearance')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Pick the look you like. It applies to the whole app and is remembered on this phone.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              ...AppPalettes.all.map((p) => _ThemeTile(palette: p, selected: p.id == current.id)),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  const _ThemeTile({required this.palette, required this.selected});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ThemeController.instance.select(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Mini preview of the theme: background, a card and the accent dots.
              Container(
                width: 92,
                height: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: 60,
                      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(5), border: Border.all(color: p.border)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Container(height: 5, width: 30, decoration: BoxDecoration(color: p.textSecondary, borderRadius: BorderRadius.circular(3))),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        for (final c in p.accentPalette)
                          Container(
                            width: 11,
                            height: 11,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                          child: Text(p.isDark ? 'Dark' : 'Light', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(p.description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? AppColors.primary : AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
