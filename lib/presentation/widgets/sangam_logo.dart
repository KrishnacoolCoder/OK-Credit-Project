import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// The Sangam brand mark: an app-icon style squircle with a "confluence" symbol —
/// three streams (UPI · Cash · Udhar) merging into one node — finished with a
/// glossy highlight for depth. Set [animated] to gently rotate the streams.
class SangamLogo extends StatelessWidget {
  final double size;
  final bool animated;
  final bool showBackground;

  const SangamLogo({
    super.key,
    this.size = 96,
    this.animated = true,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'sangam_logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          boxShadow: showBackground ? AppShadows.md : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/images/app_logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 48),
        ),
      ),
    );
  }
}
