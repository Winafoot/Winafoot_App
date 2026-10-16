import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wina/config/theme.dart';

/// Indicateur de chargement standard de l'app : un [CircularProgressIndicator]
/// vert centré. [padding] permet d'ajouter une marge (certaines feuilles /
/// cartes l'entourent d'un padding).
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.padding, this.color});

  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Widget child = Center(
      child: CircularProgressIndicator(color: color ?? AppColor.primaryColor),
    );
    return padding == null ? child : Padding(padding: padding!, child: child);
  }
}

/// Enveloppe d'un squelette de chargement : applique l'animation « shimmer »
/// à tout l'arbre passé en [child]. Un seul contrôleur d'animation anime
/// l'ensemble des [SkeletonBox] qu'il contient, quel qu'en soit le nombre.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColor.divider,
      highlightColor: AppColor.surface,
      child: child,
    );
  }
}

/// Bloc plein d'un squelette, aux dimensions du design (échelle appliquée).
/// Une dimension nulle laisse la contrainte du parent décider. À placer sous
/// un [AppSkeleton], qui lui donne son animation.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height, this.width, this.radius = 12});

  final double? height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == null ? null : formatWidth(width!),
      height: height == null ? null : formatHeight(height!),
      decoration: BoxDecoration(
        color: AppColor.divider,
        borderRadius: BorderRadius.circular(r(radius)),
      ),
    );
  }
}
