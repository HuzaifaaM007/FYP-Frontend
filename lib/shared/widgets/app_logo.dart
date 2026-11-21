import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// The Study Sensei logo, painted in the current theme's main colour
/// (white on Midnight, cyan on Ocean, gold on Emerald, ...).
/// The image is pure white, and `color` + `BlendMode.srcIn` repaints every white pixel.
class AppLogo extends StatelessWidget {
  final double size;
  final Color? color; // override the theme colour if needed
  const AppLogo({super.key, this.size = 96, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/logo_white.png',
      width: size,
      height: size,
      color: color ?? AppColors.primary,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Study Sensei logo',
    );
  }
}
