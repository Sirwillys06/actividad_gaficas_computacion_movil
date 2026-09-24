import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'chart_card_wrapper.dart';
import 'chart_entry.dart';

class _FamilyStyle {
  final IconData icon;
  final Color color;
  const _FamilyStyle(this.icon, this.color);
}

const Map<String, _FamilyStyle> _familyStyles = {
  'Barras': _FamilyStyle(Icons.bar_chart_rounded, Color(0xff2d6cdf)),
  'Líneas': _FamilyStyle(Icons.show_chart_rounded, Color(0xff00b8a9)),
  'Circulares': _FamilyStyle(Icons.pie_chart_rounded, Color(0xffa64ac9)),
  'Dispersión / Radar': _FamilyStyle(Icons.scatter_plot_rounded, Color(0xffff7a29)),
  'Dashboard': _FamilyStyle(Icons.dashboard_customize_rounded, Color(0xff7b5cfa)),
  'Interactivos': _FamilyStyle(Icons.touch_app_rounded, Color(0xffff4d8d)),
  'Series Múltiples': _FamilyStyle(Icons.stacked_line_chart_rounded, Color(0xff21c15d)),
};

const _fallbackStyle = _FamilyStyle(Icons.auto_graph_rounded, Color(0xff2d6cdf));

/// Renderiza todas las entradas de una categoría, agrupadas por familia.
///
/// Construye todos los gráficos de una sola vez (nunca perezosamente
/// durante el scroll, para no reconstruir el `Chart` de `graphic` a medio
/// scroll). Además, mientras la lista se está moviendo, cada tarjeta deja
/// de recibir eventos de puntero: `graphic` puede lanzar un error interno
/// ("Null check operator used on a null value") si uno de sus `Chart`
/// recibe un evento de puntero justo durante el scroll — es un bug
/// conocido de la librería (github.com/entronad/graphic/issues/28).
class GraphicGalleryPage extends StatefulWidget {
  final List<ChartEntry> entries;

  const GraphicGalleryPage({super.key, required this.entries});

  @override
  State<GraphicGalleryPage> createState() => _GraphicGalleryPageState();
}

class _GraphicGalleryPageState extends State<GraphicGalleryPage> {
  final ValueNotifier<bool> _scrolling = ValueNotifier(false);
  Timer? _scrollEndTimer;

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _scrolling.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification || notification is ScrollUpdateNotification) {
      _scrollEndTimer?.cancel();
      if (!_scrolling.value) _scrolling.value = true;
    } else if (notification is ScrollEndNotification) {
      _scrollEndTimer?.cancel();
      _scrollEndTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _scrolling.value = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final families = <String, List<ChartEntry>>{};
    for (final entry in widget.entries) {
      families.putIfAbsent(entry.family, () => []).add(entry);
    }

    final children = <Widget>[];
    for (final family in families.keys) {
      final list = families[family]!;
      final style = _familyStyles[family] ?? _fallbackStyle;
      children.add(_FamilyHeader(title: family, count: list.length, style: style));
      for (final entry in list) {
        children.add(
          ChartAccentScope(
            color: style.color,
            icon: style.icon,
            child: RepaintBoundary(
              key: ValueKey(entry.title),
              child: ValueListenableBuilder<bool>(
                valueListenable: _scrolling,
                builder: (context, isScrolling, child) =>
                    IgnorePointer(ignoring: isScrolling, child: child),
                child: entry.builder(context),
              ),
            ),
          ),
        );
      }
    }
    // Elemento final "de sobra": deja que el último gráfico real no sea
    // literalmente el último hijo del ListView.
    children.add(const SizedBox(height: 40));

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24, top: 4),
        // Monta las tarjetas bastante antes de que entren en pantalla (en
        // vez de justo cuando el scroll las alcanza), para que `graphic`
        // tenga tiempo de inicializar cada Chart en un momento estable.
        scrollCacheExtent: ScrollCacheExtent.pixels(6000),
        children: children,
      ),
    );
  }
}

class _FamilyHeader extends StatelessWidget {
  final String title;
  final int count;
  final _FamilyStyle style;

  const _FamilyHeader({required this.title, required this.count, required this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: style.color.withAlpha(150), blurRadius: 16)],
            ),
            child: Icon(style.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: style.color.withAlpha(70),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: style.color.withAlpha(140)),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [style.color.withAlpha(160), style.color.withAlpha(0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
