import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_tooltip.dart';

/// Capa de interacción sobre un gráfico de charts_flutter.
///
/// charts_flutter_updated 0.16 declara SelectionTrigger.hover, pero su
/// ChartGestureDetector solo conecta tap y drag: el hover nunca llega al
/// gráfico. Como el área de dibujo coincide con el widget (márgenes 0 y
/// viewport fijo), cada vista traduce la posición del puntero al dato
/// correspondiente y esta capa entrega esa posición en hover (ratón), en tap
/// y al arrastrar (táctil).
class PlotPointerRegion extends StatelessWidget {
  final Widget child;
  final ValueChanged<Offset> onPoint;
  final VoidCallback onExit;

  const PlotPointerRegion({
    super.key,
    required this.child,
    required this.onPoint,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      onHover: (event) => onPoint(event.localPosition),
      onExit: (_) => onExit(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => onPoint(event.localPosition),
        onPointerMove: (event) {
          if (event.kind != PointerDeviceKind.mouse) {
            onPoint(event.localPosition);
          }
        },
        child: child,
      ),
    );
  }
}

/// Coloca el tooltip junto a [anchor] sin salirse del área del gráfico.
class TooltipOverlay extends StatelessWidget {
  final Offset anchor;
  final TooltipContent content;

  const TooltipOverlay({
    super.key,
    required this.anchor,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _TooltipLayoutDelegate(anchor),
          child: ChartTooltip(content: content),
        ),
      ),
    );
  }
}

class _TooltipLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset anchor;

  const _TooltipLayoutDelegate(this.anchor);

  static const double _gap = 14;

  // El tooltip conserva su tamaño natural aunque el área del gráfico sea
  // pequeña (p. ej. un donut en móvil); puede sobresalir del lienzo.
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints(maxWidth: 240, maxHeight: 320);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.dx + _gap;
    if (x + childSize.width > size.width) {
      x = anchor.dx - _gap - childSize.width;
    }
    if (x < 0) x = (size.width - childSize.width) / 2;

    var y = anchor.dy - childSize.height / 2;
    final maxY = size.height - childSize.height;
    y = maxY < 0 ? maxY / 2 : y.clamp(0, maxY).toDouble();
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _TooltipLayoutDelegate old) =>
      old.anchor != anchor;
}

/// Banda translúcida que resalta la categoría activa.
class BandHighlight extends StatelessWidget {
  final int index;
  final int count;
  final Axis direction;

  const BandHighlight({
    super.key,
    required this.index,
    required this.count,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, c) {
            final horizontal = direction == Axis.horizontal;
            final step = (horizontal ? c.maxWidth : c.maxHeight) / count;
            return Stack(
              children: [
                Positioned(
                  left: horizontal ? step * index : 0,
                  top: horizontal ? 0 : step * index,
                  width: horizontal ? step : c.maxWidth,
                  height: horizontal ? c.maxHeight : step,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x140B3D2E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
