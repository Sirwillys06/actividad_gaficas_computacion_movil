import 'package:flutter/material.dart';

import '../charts/catalog/chart_catalog.dart';
import '../charts/catalog/chart_definition.dart';
import 'chart_card.dart';
import 'status_view.dart';

/// Tarjeta de un gráfico del catálogo: resuelve disponibilidad, altura y
/// errores de transformación sin romper el resto del panel.
class ChartDefinitionCard extends StatelessWidget {
  const ChartDefinitionCard({super.key, required this.definition, required this.context});

  final ChartDefinition definition;
  final ChartContext context;

  @override
  Widget build(BuildContext buildContext) {
    final reason = definition.unavailableReason(context);
    Widget body;
    var height = 160.0;
    if (reason != null) {
      body = EmptyView(message: reason);
    } else {
      height = definition.resolveHeight(context);
      try {
        body = definition.builder(context);
      } catch (error) {
        height = 160;
        body = ErrorView(message: 'No se pudo construir este gráfico: $error');
      }
    }
    return ChartCard(
      number: ChartCatalog.numberOf(definition),
      title: definition.title,
      description: definition.description,
      height: height,
      tags: [
        ChartTag(label: definition.chartType, icon: Icons.stacked_bar_chart_rounded),
        ChartTag(label: definition.scope.label, icon: definition.scope.icon),
      ],
      child: body,
    );
  }
}
