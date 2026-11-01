import 'package:wina/config/phone_scale.dart';
import 'package:flutter/material.dart';
import 'package:wina/models/formation.dart';

/// Terrain vu de dessus, en portrait (but de l'équipe en bas).
const String kPitchPortraitAsset = 'assets/images/pitch_field_portrait.webp';

/// Maillot cyan (titulaire) pour les marqueurs de composition.
const String _kMarkerJersey = 'assets/images/shirt-l-blue.png';

/// Aperçu d'un schéma tactique : terrain portrait + maillots positionnés aux
/// emplacements du [formation]. Utilisé pour les cartes de composition et
/// l'aperçu « Composition choisie ».
class FormationPitch extends StatelessWidget {
  const FormationPitch({
    super.key,
    required this.formation,
    this.markerFraction = 0.16,
    this.borderRadius = 14,
  });

  final Formation? formation;

  /// Largeur d'un maillot, en fraction de la largeur du terrain.
  final double markerFraction;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Formation? f = formation;
    return ClipRRect(
      borderRadius: BorderRadius.circular(cR(borderRadius)),
      child: AspectRatio(
        aspectRatio: 1668 / 2388,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final double m = w * markerFraction;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(kPitchPortraitAsset, fit: BoxFit.cover),
                ),
                if (f != null)
                  for (final FormationSlot slot in f.slots)
                    Positioned(
                      left: slot.x * w - m / 2,
                      top: slot.y * h - m / 2,
                      width: m,
                      height: m,
                      child: Image.asset(_kMarkerJersey, fit: BoxFit.contain),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
