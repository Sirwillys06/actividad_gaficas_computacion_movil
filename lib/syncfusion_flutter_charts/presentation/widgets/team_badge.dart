import 'package:flutter/material.dart';

/// Escudo de TheSportsDB. Si la URL no existe o falla la descarga se muestran
/// las iniciales del equipo (nunca una imagen inventada).
class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.name, this.url, this.size = 28});

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: name, size: size);
    final source = url;
    if (source == null || source.isEmpty) return fallback;
    return SizedBox.square(
      dimension: size,
      child: Image.network(
        source,
        cacheWidth: (size * 3).round(),
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'Escudo de $name',
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isEmpty
        ? '?'
        : words.length == 1
        ? words.first.substring(0, words.first.length.clamp(1, 2))
        : '${words[0][0]}${words[1][0]}';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.bold),
      ),
    );
  }
}
