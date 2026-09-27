import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

/// Escudo de un equipo resuelto por idTeam.
///
/// En Flutter Web los escudos de TheSportsDB pueden fallar por CORS al
/// decodificarse en el canvas; [WebHtmlElementStrategy.fallback] recurre a un
/// elemento <img> cuando eso ocurre. Si la imagen no carga, se muestran las
/// iniciales del equipo.
class TeamBadge extends StatelessWidget {
  final String? badgeUrl;
  final String name;
  final double size;

  const TeamBadge({
    super.key,
    required this.badgeUrl,
    required this.name,
    this.size = 20,
  });

  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length.clamp(0, 2)).toUpperCase();
    }
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            initials(name),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: DashboardColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = badgeUrl;
    if (url == null || url.isEmpty) return _fallback();

    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }
}

/// [escudo] Nombre del equipo, en una sola línea.
class TeamLabel extends StatelessWidget {
  final String name;
  final String? badgeUrl;
  final bool showBadge;
  final bool highlighted;
  final double fontSize;
  final double badgeSize;

  const TeamLabel({
    super.key,
    required this.name,
    required this.badgeUrl,
    this.showBadge = true,
    this.highlighted = false,
    this.fontSize = 10,
    this.badgeSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBadge) ...[
          TeamBadge(badgeUrl: badgeUrl, name: name, size: badgeSize),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.1,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              color: highlighted ? DashboardColors.ink : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
