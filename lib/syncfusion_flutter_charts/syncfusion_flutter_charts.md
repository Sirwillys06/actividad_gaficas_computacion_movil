# Syncfusion Flutter Charts — Sports Analytics

Plataforma de análisis estadístico de fútbol construida con **Flutter**, datos reales de
**TheSportsDB** y **Syncfusion Flutter Charts** como única librería de gráficos. Incluye
**80 visualizaciones** organizadas en 10 secciones, filtros globales y un resumen con tabla.

## Arquitectura

```
lib/syncfusion_flutter_charts/
├── core/
│   ├── config/api_config.dart        # Única fuente de URLs de TheSportsDB
│   ├── constants/app_constants.dart  # Timeout, puntos 3/1/0, límites de peticiones
│   ├── theme/                        # Tema oscuro y paleta semántica de gráficos
│   └── utils/                        # JSON seguro, formateo, estadística
├── data/
│   ├── services/sports_api_service.dart     # HTTP + errores (HTTP, 429, timeout, JSON)
│   ├── repositories/sports_repository.dart  # Cache en memoria + completar por jornadas
│   ├── models/                              # Event, Team, League, TeamStats, métricas…
│   └── mappers/
│       ├── season_analytics.dart    # Clasificación, jornadas e histórico (1 pasada)
│       ├── chart_data_mapper.dart   # Métricas a nivel de partido/liga
│       └── team_series_mapper.dart  # Evolución, perfiles y cara a cara por equipo
└── presentation/
    ├── state/dashboard_controller.dart
    ├── screens/                      # Dashboard + sección Resumen
    ├── widgets/                      # Tarjetas, selectores con búsqueda, tabla, escudos
    └── charts/
        ├── components/               # Gráficos Syncfusion genéricos y reutilizables
        ├── catalog/                  # 80 definiciones declarativas (1 archivo por sección)
        └── *.dart                    # Los 3 gráficos originales (se siguen usando)
```

Flujo: `ApiConfig → SportsApiService → SportsRepository → Models → Mappers → UI`.
Ningún widget construye URLs ni lee JSON.

### Componentes reutilizables

- `CategoryChart<T>`: un único constructor de series cartesianas (Column, Bar, Stacked,
  100 % Stacked, Line, Spline, Area, Spline Area, Step Line, Step Area, Fast Line, Stacked Area)
  con tooltips enriquecidos, selección, zoom/pan, trackball, leyenda y desplazamiento.
- `TeamRankingChart`, `XYChart` (Scatter/Bubble + Trendline), `BreakdownChart`
  (Pie/Doughnut/Radial Bar), `RangeChart` (Range Column/Range Area), `MeanDeviationChart`
  (Hilo + Scatter), `HistogramChart`, `BoxPlotChart`, `WaterfallChart`.
- `ChartDefinition` declara título, descripción, tipo, alcance de filtro, requisitos de datos
  y altura; `ChartDefinitionCard` resuelve estados vacío/insuficiente/error.

## Consumo de TheSportsDB

API v1 gratuita (clave pública en `api_config.dart`). Endpoints:

| Endpoint | Uso |
|---|---|
| `all_leagues.php` | Selector de competición (filtrado a fútbol) |
| `lookupleague.php?id=` | Temporada actual y escudo de la liga |
| `search_all_seasons.php?id=` | Selector de temporada |
| `search_all_teams.php?l=` | Escudos de los equipos |
| `eventsseason.php?id=&s=` | Partidos de la temporada (fuente principal) |
| `eventsround.php?id=&r=&s=` | Completar la temporada jornada a jornada (bajo demanda) |
| `eventspastleague.php?id=` | Respaldo si la temporada no devuelve partidos |

Estrategia de peticiones:

- Al abrir la app: 1 petición de ligas + 2 de la liga (detalle, temporadas) + 2 de la
  temporada (equipos, partidos). **Todo lo demás se calcula localmente.**
- Cambiar de sección, filtro, equipo o comparación **no hace peticiones** (verificado en tests).
- Cache en memoria por URL; las peticiones simultáneas iguales se comparten; los errores no se cachean.
- El plan gratuito puede limitar los partidos que devuelve `eventsseason`. El botón
  *Completar temporada por jornadas* consulta `eventsround` solo para las jornadas incompletas,
  con ~2,2 s entre peticiones para respetar el límite (~30/min), y añade únicamente partidos reales.

## Reglas de datos

- No hay datos simulados en la aplicación: todos los gráficos derivan de los partidos con
  marcador que devuelve TheSportsDB. Los fixtures existen solo en `test/`.
- Partidos sin marcador o aplazados (`strPostponed = yes`) se ignoran en las métricas.
- Equipos identificados por `idHomeTeam`/`idAwayTeam` (con el nombre como respaldo).
- La clasificación se **calcula** (3/1/0; desempate: DG, GF, nombre). Cada liga tiene reglas
  propias; la interfaz lo indica como "clasificación calculada".
- Si la API no informa `intRound`, las jornadas se agrupan por fecha y los ejes lo indican.
- La hora de inicio se muestra en UTC (así la publica la API).

### Limitaciones documentadas y sustituciones

| Solicitado | Situación | Solución |
|---|---|---|
| Radar de rendimiento / radar comparativo | Syncfusion Flutter Charts no incluye series Radar/Polar | Radial Bar (#25) y columnas agrupadas normalizadas 0–100 (#26) |
| Barras de error por equipo | `ErrorBarSeries` solo admite un error global | Hilo + Scatter (media ± desviación típica, #80) |
| Estadísticas de jugadores, posesión, tiros | No forman parte de los endpoints de eventos por temporada que usa la app | Sustituidas por métricas derivables de marcadores (porterías a cero, ambos marcan, forma, localía…) |
| Tabla oficial (`lookuptable.php`) | No se usa: el plan gratuito puede recortarla y no permite reconstruir la evolución por jornada | Tabla calculada con todos los equipos a partir de los partidos |

## Catálogo de las 80 visualizaciones

### Posiciones

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 1 | Puntos por equipo | Bar | Filtro Top/Bottom |
| 2 | Partidos jugados | Column | Filtro Top/Bottom |
| 3 | Puntos por partido | Bar + línea de media | Filtro Top/Bottom |
| 4 | Rendimiento porcentual | Bar | Filtro Top/Bottom |
| 5 | Evolución de la posición | Line (eje Y invertido) | Comparación |
| 6 | Puntos acumulados: equipo vs líder | Step Line | Equipo |
| 7 | Distancia al líder | Column | Filtro Top/Bottom |
| 8 | Horquilla de puntos de la liga | Range Area + Line | Equipo |

### Goles

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 9 | Goles a favor por equipo | Column | Filtro Top/Bottom |
| 10 | Goles en contra por equipo | Bar | Filtro Top/Bottom |
| 11 | Diferencia de goles | Bar divergente | Filtro Top/Bottom |
| 12 | Promedio de goles a favor por partido | Column + línea de media | Filtro Top/Bottom |
| 13 | Goles locales y visitantes por equipo | Stacked Column | Filtro Top/Bottom |
| 14 | Goles totales en los partidos de cada equipo | Stacked Bar | Filtro Top/Bottom |
| 15 | Porterías a cero | Column | Filtro Top/Bottom |
| 16 | Partidos sin marcar | Bar | Filtro Top/Bottom |

### Resultados

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 17 | Victorias, empates y derrotas | Stacked Bar | Filtro Top/Bottom |
| 18 | Porcentaje de victorias, empates y derrotas | 100% Stacked Bar | Filtro Top/Bottom |
| 19 | Porcentaje de victorias | Column | Filtro Top/Bottom |
| 20 | Distribución general de resultados | Doughnut | Liga |
| 21 | Resultados del equipo | Pie | Equipo |
| 22 | Victorias como local y como visitante | Column agrupado | Filtro Top/Bottom |
| 23 | Empates como local y como visitante | Bar agrupado | Filtro Top/Bottom |
| 24 | Derrotas como local y como visitante | Stacked Column | Filtro Top/Bottom |

### Rendimiento

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 25 | Perfil de rendimiento del equipo | Radial Bar | Equipo |
| 26 | Comparativa de perfiles | Column agrupado normalizado | Comparación |
| 27 | Rendimiento como local | Bar | Filtro Top/Bottom |
| 28 | Rendimiento como visitante | Bar | Filtro Top/Bottom |
| 29 | Puntos por partido: local vs visitante | Column agrupado | Filtro Top/Bottom |
| 30 | Forma reciente | Column | Filtro Top/Bottom |
| 31 | Cascada de diferencia de goles | Waterfall | Equipo |
| 32 | Goles a favor y en contra partido a partido | Stacked Column divergente | Equipo |

### Partidos

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 33 | Goles en los partidos más recientes | Line | Liga |
| 34 | Diferencia de goles por partido | Column con desplazamiento | Liga |
| 35 | Partidos con más goles | Bar | Liga |
| 36 | Partidos con menos goles | Bar | Liga |
| 37 | Marcadores más frecuentes | Column | Liga |
| 38 | Victorias por margen de goles | Column | Liga |
| 39 | Intensidad goleadora de la temporada | Fast Line | Liga |
| 40 | Mapa de marcadores | Bubble | Liga |

### Local vs visitante

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 41 | Goles locales y visitantes por jornada | Stacked Area | Liga |
| 42 | Reparto de resultados por jornada | 100% Stacked Column | Liga |
| 43 | Ventaja de localía por equipo | Bar divergente | Filtro Top/Bottom |
| 44 | Goles locales vs goles visitantes | Scatter | Filtro Top/Bottom |
| 45 | Goles encajados en casa y fuera | Bar agrupado | Filtro Top/Bottom |
| 46 | Reparto de goles de la liga | Pie | Liga |
| 47 | Victorias locales vs visitantes acumuladas | Spline | Liga |
| 48 | Rendimiento local vs visitante | Scatter | Filtro Top/Bottom |

### Evolución

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 49 | Goles por jornada | Column | Liga |
| 50 | Promedio de goles por partido en cada jornada | Spline | Liga |
| 51 | Victorias, empates y derrotas por jornada | Line | Liga |
| 52 | Evolución acumulada de goles | Area | Liga |
| 53 | Evolución del rendimiento del equipo | Spline Area | Equipo |
| 54 | Goles acumulados del equipo | Step Area | Equipo |
| 55 | Evolución local y visitante del equipo | Line | Equipo |
| 56 | Rango de goles por jornada | Range Column + Line | Liga |

### Distribución

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 57 | Distribución de goles por jornada | Box and Whisker | Liga |
| 58 | Distribución de goles a favor por equipo | Box and Whisker | Comparación |
| 59 | Partidos por día de la semana | Column | Liga |
| 60 | Goles por partido según el día | Line | Liga |
| 61 | Partidos por hora de inicio (UTC) | Column | Liga |
| 62 | Más / menos de 2.5 goles | Doughnut | Liga |
| 63 | Partidos en los que marcan ambos equipos | Bar | Filtro Top/Bottom |
| 64 | Histograma de goles por partido | Histogram | Liga |

### Comparaciones

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 65 | Indicadores clave de los equipos comparados | Column agrupado | Comparación |
| 66 | Ataque vs defensa por equipo | Bar agrupado | Filtro Top/Bottom |
| 67 | Puntos local y visitante de los equipos comparados | Stacked Bar | Comparación |
| 68 | Evolución de puntos de varios equipos | Line | Comparación |
| 69 | Evolución de la diferencia de goles | Spline | Comparación |
| 70 | Top 5 vs Bottom 5 vs media de la liga | Column agrupado | Liga |
| 71 | Enfrentamientos directos | Doughnut | Comparación |
| 72 | Puntos respecto a la media | Bar divergente | Filtro Top/Bottom |

### Análisis avanzado

| # | Gráfico | Tipo Syncfusion | Filtro |
|---|---|---|---|
| 73 | Ataque vs defensa | Scatter | Filtro Top/Bottom |
| 74 | Goles a favor vs puntos | Scatter + Trendline | Filtro Top/Bottom |
| 75 | Goles en contra vs derrotas | Scatter + Trendline | Filtro Top/Bottom |
| 76 | Diferencia de goles vs puntos | Scatter + Trendline | Filtro Top/Bottom |
| 77 | Comparación global de equipos | Bubble | Filtro Top/Bottom |
| 78 | Promedio de goles vs % de victorias | Scatter + Trendline | Filtro Top/Bottom |
| 79 | Partidos jugados vs puntos | Scatter | Filtro Top/Bottom |
| 80 | Regularidad goleadora | Hilo + Scatter | Filtro Top/Bottom |

## Filtros e interactividad

- Competición (búsqueda entre todas las ligas de fútbol), temporada, equipo analizado
  (búsqueda con escudos) y equipos comparados (hasta 6).
- Filtro global de clasificación: Todos, Top 5, Top 10, Top 15, Bottom 5.
- Tooltips con contexto (partido, posición, valores), selección de puntos, zoom/pan,
  trackball, crosshair, leyendas conmutables, etiquetas de datos, líneas de referencia
  (media, 0, 50 %) y desplazamiento en ejes con muchas categorías.
- Con muchos equipos se usan barras horizontales cuya altura crece con el número de equipos.

## Estados y errores

Carga inicial, carga al cambiar liga/temporada, respuesta vacía (`null` o `"No data"`),
datos insuficientes por gráfico (motivo explícito en la tarjeta), equipo sin partidos,
partidos sin marcador, escudos inexistentes o rotos (iniciales), HTTP de error, límite 429,
timeout y JSON inválido. Un error en un gráfico no rompe el resto del panel.

## Verificación

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Tests (`test/`): cálculos de goles, V/E/D, puntos, DG y promedios; filtros Top/Bottom;
datos vacíos y sin marcador; parsing JSON; cache y completado por jornadas del repositorio;
flujo completo del dashboard con cliente HTTP simulado; y renderizado de los 80 gráficos.
