import 'package:flutter/material.dart';

/// Color/ícono ambiental que la galería fija por familia de gráficos.
/// [ChartCardWrapper] lo lee automáticamente si no recibe uno explícito,
/// así los 79 gráficos no necesitan pasar accentColor/icon a mano.
class ChartAccentScope extends InheritedWidget {
  final Color color;
  final IconData icon;

  const ChartAccentScope({
    super.key,
    required this.color,
    required this.icon,
    required super.child,
  });

  static ChartAccentScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChartAccentScope>();

  @override
  bool updateShouldNotify(ChartAccentScope oldWidget) =>
      color != oldWidget.color || icon != oldWidget.icon;
}

/// Tarjeta oscura con brillo de color por familia: encabezado a todo color,
/// ícono en insignia sólida y el gráfico en un panel claro (para que los
/// ejes/etiquetas de `graphic`, pensados para fondo blanco, se vean nítidos).
class ChartCardWrapper extends StatefulWidget {
  final String title;
  final String description;
  final Widget chart;
  final double height;
  final Color? accentColor;
  final IconData? icon;

  const ChartCardWrapper({
    super.key,
    required this.title,
    required this.description,
    required this.chart,
    this.height = 320,
    this.accentColor,
    this.icon,
  });

  @override
  State<ChartCardWrapper> createState() => _ChartCardWrapperState();
}

class _ChartCardWrapperState extends State<ChartCardWrapper> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = ChartAccentScope.maybeOf(context);
    final accent = widget.accentColor ?? scope?.color ?? theme.colorScheme.primary;
    final icon = widget.icon ?? scope?.icon ?? Icons.auto_graph_rounded;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: const Color(0xff141b2e),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withAlpha(_hover ? 160 : 90), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(_hover ? 130 : 70),
              blurRadius: _hover ? 30 : 18,
              spreadRadius: _hover ? 1 : 0,
              offset: const Offset(0, 10),
            ),
            const BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withAlpha(90), accent.withAlpha(18)],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(color: accent.withAlpha(160), blurRadius: 14),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.description,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: const Color(0xffa9b4cc)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Container(
                  height: widget.height,
                  padding: const EdgeInsets.fromLTRB(6, 14, 14, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: widget.chart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
