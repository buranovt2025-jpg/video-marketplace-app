import 'package:flutter/material.dart';

class AppBrandTitle extends StatelessWidget {
  final double height;
  final bool showText;

  const AppBrandTitle({
    super.key,
    this.height = 28,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final isDarkBg = (bg.computeLuminance() < 0.5);

    // On dark background we use orange mark over black.
    // On light background we use orange mark over white.
    final markAsset = isDarkBg ? 'assets/images/logo_dark.png' : 'assets/images/logo_white.png';

    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ) ??
        const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          markAsset,
          height: height,
          filterQuality: FilterQuality.high,
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Container(
            width: 2,
            height: height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Text('GoGoMarket', style: textStyle),
        ],
      ],
    );
  }
}

