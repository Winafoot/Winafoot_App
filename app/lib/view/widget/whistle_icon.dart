import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icône sifflet — SVG exporté du design Figma
/// (« whistle-game-referee-svgrepo-com », pas d'équivalent Iconsax).
class WhistleIcon extends StatelessWidget {
  const WhistleIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/whistle.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
