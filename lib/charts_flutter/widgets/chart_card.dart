import 'package:flutter/material.dart';

import '../charts/chart_body.dart';
import '../charts/chart_models.dart';
import '../models/multi_league_dashboard_models.dart';
import '../services/multi_league_api_service.dart';
import '../theme/dashboard_theme.dart';
import 'team_badge.dart';

/// Tarjeta de un gráfico que solicita sus datos al hacerse visible.
///
/// El SliverGrid solo construye las tarjetas visibles; cada una pide al
/// servicio únicamente el bloque que necesita (tabla y/o eventos). El
/// servicio reutiliza caché y peticiones en curso, por lo que 16 tarjetas de
/// una liga generan como máximo 2 peticiones HTTP.
class LazyChartCard extends StatefulWidget {
  final MultiLeagueApiService apiService;
  final LeagueConfig league;
  final ChartDefinition definition;
  final int number;

  const LazyChartCard({
    super.key,
    required this.apiService,
    required this.league,
    required this.definition,
    required this.number,
  });

  @override
  State<LazyChartCard> createState() => _LazyChartCardState();
}

class _LazyChartCardState extends State<LazyChartCard> {
  late Future<LeagueDashboardData> _future;

  // Datos del gráfico construidos una sola vez por respuesta.
  LeagueDashboardData? _builtFrom;
  ChartData? _chartData;
  Object? _buildError;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<LeagueDashboardData> _load() {
    final source = widget.definition.source;
    return widget.apiService.getLeagueData(
      widget.league,
      includeStandings: source.needsStandings,
      includeEvents: source.needsEvents,
    );
  }

  void _retry() => setState(() {
        _builtFrom = null;
        _future = _load();
      });

  void _ensureBuilt(LeagueDashboardData data) {
    if (identical(_builtFrom, data)) return;
    _builtFrom = data;
    try {
      _chartData = widget.definition.build(data);
      _buildError = null;
    } catch (error) {
      // Un gráfico con datos inesperados no rompe el resto de la liga.
      _chartData = null;
      _buildError = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ChartCard(
        definition: widget.definition,
        number: widget.number,
        body: FutureBuilder<LeagueDashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ChartStateMessage.error(
                detail: snapshot.error.toString(),
                onRetry: _retry,
              );
            }
            if (!snapshot.hasData) return const ChartStateMessage.loading();

            _ensureBuilt(snapshot.data!);
            if (_buildError != null) {
              return ChartStateMessage.error(detail: _buildError.toString());
            }
            final chartData = _chartData!;
            if (chartData.isEmpty) {
              return ChartStateMessage.empty(widget.definition.emptyMessage);
            }
            final chartContext = ChartContext(
              data: snapshot.data!,
              season: MultiLeagueApiService.season,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChartLegend(data: chartData, kind: widget.definition.kind, context: chartContext),
                Expanded(
                  child: ChartBody(
                    kind: widget.definition.kind,
                    data: chartData,
                    context: chartContext,
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

/// Marco visual común de los gráficos.
class ChartCard extends StatelessWidget {
  final ChartDefinition definition;
  final int number;
  final Widget body;

  const ChartCard({
    super.key,
    required this.definition,
    required this.number,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final kind = definition.kind;
    final endpoint = switch (definition.source) {
      ChartDataSource.standings => 'tabla de clasificación',
      ChartDataSource.events => 'partidos de la temporada',
      ChartDataSource.both => 'tabla + partidos',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: DashboardColors.pitch.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(kind.icon, size: 19, color: DashboardColors.pitch),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#$number · ${definition.advanced ? 'Avanzado' : 'Básico'}'
                        ' · Temporada ${MultiLeagueApiService.season}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: DashboardColors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _KindChip(kind: kind),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              definition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: DashboardColors.inkMuted,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.straighten_rounded, size: 13, color: DashboardColors.inkFaint),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    definition.axisHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: body),
            const Divider(height: 14, color: DashboardColors.border),
            Row(
              children: [
                const Icon(Icons.dataset_outlined, size: 12, color: DashboardColors.inkFaint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Fuente: TheSportsDB · $endpoint',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: DashboardColors.inkFaint),
                  ),
                ),
                const Icon(Icons.touch_app_outlined, size: 12, color: DashboardColors.inkFaint),
                const SizedBox(width: 3),
                const Text(
                  'Cursor o toque: detalle',
                  style: TextStyle(fontSize: 10, color: DashboardColors.inkFaint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final ChartKind kind;

  const _KindChip({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tipo de gráfico: ${kind.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DashboardColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DashboardColors.border),
        ),
        child: Text(
          kind.label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: DashboardColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Leyenda de series. Solo aparece cuando hay más de una serie o cuando el
/// color tiene un significado propio (barras divergentes).
class ChartLegend extends StatelessWidget {
  final ChartData data;
  final ChartKind kind;
  final ChartContext context;

  const ChartLegend({
    super.key,
    required this.data,
    required this.kind,
    required this.context,
  });

  @override
  Widget build(BuildContext buildContext) {
    final entries = <Widget>[];
    final data = this.data;

    if (kind == ChartKind.divergingBar) {
      entries
        ..add(const _LegendEntry(label: 'Positiva', color: DashboardColors.win))
        ..add(const _LegendEntry(label: 'Negativa', color: DashboardColors.loss));
    } else if (data is CategoryChartData && data.series.length > 1) {
      for (final s in data.series) {
        entries.add(_LegendEntry(label: s.name, color: s.color, line: s.asLine || kind == ChartKind.line));
      }
    } else if (data is TimeChartData && data.series.length > 1) {
      for (final s in data.series) {
        entries.add(
          _LegendEntry(
            label: s.name,
            color: s.color,
            line: true,
            leading: s.teamId == null
                ? null
                : TeamBadge(badgeUrl: context.badge(s.teamId), name: s.name, size: 14),
          ),
        );
      }
    }

    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(spacing: 12, runSpacing: 4, children: entries),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  final String label;
  final Color color;
  final bool line;
  final Widget? leading;

  const _LegendEntry({
    required this.label,
    required this.color,
    this.line = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: line ? 14 : 10,
          height: line ? 3 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(line ? 2 : 3),
          ),
        ),
        const SizedBox(width: 5),
        if (leading != null) ...[leading!, const SizedBox(width: 4)],
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

/// Estados de carga, vacío y error dentro de una tarjeta.
class ChartStateMessage extends StatelessWidget {
  final IconData? icon;
  final String message;
  final String? detail;
  final bool loading;
  final VoidCallback? onRetry;

  const ChartStateMessage.loading({super.key})
      : icon = null,
        message = 'Cargando estadísticas…',
        detail = null,
        loading = true,
        onRetry = null;

  const ChartStateMessage.empty(this.message, {super.key})
      : icon = Icons.hourglass_empty_rounded,
        detail = null,
        loading = false,
        onRetry = null;

  const ChartStateMessage.error({super.key, this.detail, this.onRetry})
      : icon = Icons.cloud_off_rounded,
        message = 'No se pudieron cargar las estadísticas.',
        loading = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Icon(icon, size: 28, color: DashboardColors.inkFaint),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: DashboardColors.inkMuted,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: DashboardColors.inkFaint),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
