import 'package:flutter/material.dart';

import '../../../data/mappers/season_analytics.dart';
import '../../../data/models/ranking_filter.dart';
import '../../../data/models/team_stats.dart';

/// Secciones de análisis de la aplicación.
enum ChartCategory {
  standings('Posiciones', Icons.leaderboard_rounded),
  goals('Goles', Icons.sports_soccer_rounded),
  results('Resultados', Icons.fact_check_rounded),
  performance('Rendimiento', Icons.speed_rounded),
  matches('Partidos', Icons.stadium_rounded),
  homeAway('Local vs visitante', Icons.compare_arrows_rounded),
  evolution('Evolución', Icons.timeline_rounded),
  distribution('Distribución', Icons.bar_chart_rounded),
  comparisons('Comparaciones', Icons.balance_rounded),
  advanced('Análisis avanzado', Icons.insights_rounded);

  const ChartCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Qué selección de la barra de filtros utiliza un gráfico. Se muestra como
/// etiqueta en la tarjeta para que quede claro qué filtro le afecta.
enum ChartScope {
  league('Liga completa', Icons.public_rounded),
  ranking('Filtro de clasificación', Icons.filter_list_rounded),
  team('Equipo seleccionado', Icons.shield_outlined),
  comparison('Equipos comparados', Icons.groups_rounded);

  const ChartScope(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Estado de filtros con el que se construye cada gráfico.
class ChartContext {
  final SeasonAnalytics analytics;
  final RankingFilter filter;
  final TeamStats? team;
  final List<TeamStats> compared;

  const ChartContext({required this.analytics, required this.filter, this.team, this.compared = const []});

  /// Equipos visibles según el filtro global (Todos, Top N, Bottom 5).
  List<TeamStats> get teams => filter.apply(analytics.standings);
}

/// Motivo por el que un gráfico no puede construirse con los datos actuales.
typedef Availability = String? Function(ChartContext context);

/// Definición declarativa de una visualización del catálogo.
class ChartDefinition {
  final String id;
  final ChartCategory category;
  final String title;
  final String description;

  /// Tipo de gráfico Syncfusion utilizado (se muestra como etiqueta).
  final String chartType;
  final ChartScope scope;
  final Availability? availability;
  final double Function(ChartContext context)? height;
  final Widget Function(ChartContext context) builder;

  const ChartDefinition({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.chartType,
    required this.builder,
    this.scope = ChartScope.league,
    this.availability,
    this.height,
  });

  /// Comprueba los requisitos comunes según el alcance y los específicos.
  String? unavailableReason(ChartContext context) {
    if (context.analytics.isEmpty) {
      return 'No hay partidos con marcador para esta liga y temporada.';
    }
    switch (scope) {
      case ChartScope.team:
        if (context.team == null) return 'Selecciona un equipo para ver este análisis.';
        if (context.team!.played == 0) return 'El equipo seleccionado no tiene partidos con marcador.';
      case ChartScope.comparison:
        if (context.compared.length < 2) return 'Selecciona al menos dos equipos para comparar.';
      case ChartScope.ranking:
        if (context.teams.isEmpty) return 'No hay equipos para el filtro seleccionado.';
      case ChartScope.league:
        break;
    }
    return availability?.call(context);
  }

  double resolveHeight(ChartContext context) => height?.call(context) ?? 340;
}

/// Alturas adaptadas al número de categorías para que ningún nombre se oculte.
class ChartSizing {
  static double forRows(int rows, {double perRow = 28, double min = 340}) {
    final value = 90 + rows * perRow;
    return value < min ? min : value;
  }

  static double teamRows(ChartContext context, {double perRow = 28}) => forRows(context.teams.length, perRow: perRow);
}
