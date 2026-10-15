import 'dart:io';

import 'package:flutter/material.dart';

/// Renders exercise media, transparently choosing between a bundled asset
/// (dataset exercises) and a file in the app documents directory (custom
/// exercises).
///
/// Poster images are static (jpg/png) while the instruction animation is a
/// gif, so [animate] selects the gif when one is available.
class ExerciseImage extends StatelessWidget {
  const ExerciseImage({
    super.key,
    required this.posterPath,
    this.gifPath,
    this.animate = false,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
  });

  final String? posterPath;
  final String? gifPath;
  final bool animate;
  final BoxFit fit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final path = animate && _hasText(gifPath) ? gifPath! : posterPath;

    if (!_hasText(path)) {
      return _Placeholder(icon: icon);
    }

    if (path!.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _Placeholder(icon: icon),
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _Placeholder(icon: icon),
    );
  }

  static bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(child: Icon(icon, color: scheme.onSurfaceVariant, size: 28)),
    );
  }
}
