
# Guía Técnica de Implementación: Módulo `fl_chart`

## 1. Arquitectura de Archivos en `/lib/fl_chart`

Para mantener la mantenibilidad, escalabilidad y aislamiento del código, la carpeta asignada `lib/fl_chart` debe estructurarse estrictamente bajo el siguiente árbol de directorios:

```text
lib/fl_chart/
├── models/
│   └── fl_chart_mapper.dart           # Conversor de ChartDataSet a FlSpot/BarChartGroupData
├── services/
│   └── fl_chart_data_service.dart     # Conexión con SportsApiService/Mock
├── basic/
│   ├── line_charts_basic.dart         # Gráficas 1 a 10 (LineChart)
│   ├── bar_charts_basic.dart          # Gráficas 11 a 25 (BarChart)
│   ├── pie_charts_basic.dart          # Gráficas 26 a 35 (PieChart)
│   └── scatter_radar_basic.dart       # Gráficas 36 a 43 (ScatterChart & RadarChart)
├── advanced/
│   ├── interactive_charts_adv.dart    # Avanzadas 1 a 10 (Touch & Gestures)
│   ├── multi_series_adv.dart          # Avanzadas 11 a 20 (Multi-series & Combinadas)
│   └── dashboard_stream_adv.dart      # Avanzadas 21 a 36 (Streams, Filters & Dynamic State)
├── widgets/
│   ├── chart_card_wrapper.dart        # Contenedor visual uniforme (Card + AspectRatio + Titles)
│   └── custom_tooltip.dart            # Tooltips y TooltipItems personalizados
└── fl_chart_gallery.dart              # Pantalla principal con GridView/ListView selector

```

---

## 2. Correspondencia entre Modelos y `fl_chart`

Cada tipo de gráfico en `fl_chart` requiere una estructura de datos específica. El archivo `models/fl_chart_mapper.dart` debe realizar la conversión desde el modelo abstracto `ChartDataPoint` del módulo general.

| Widget `fl_chart` | Data Model Requerido | Objeto por Punto/Elemento | Mapeo desde `ChartDataPoint` |
| --- | --- | --- | --- |
| `LineChart` | `LineChartData` | `FlSpot(x, y)` | `x`: índice o timestamp.inMilliseconds, `y`: `value` |
| `BarChart` | `BarChartData` | `BarChartGroupData` con `BarChartRodData` | `x`: índice entero, `toY`: `value` |
| `PieChart` | `PieChartData` | `PieChartSectionData` | `value`: `value`, `title`: `label` o porcentaje |
| `ScatterChart` | `ScatterChartData` | `ScatterSpot(x, y)` | `x`: `value`, `y`: `secondaryValue` |
| `RadarChart` | `RadarChartData` | `RadarDataSet` con `RadarEntry(value)` | `value`: `value` mapeado por eje |

---

## 3. Catálogo Técnico de 79 Gráficas

### A. Gráficas Básicas (43 Total)

#### LineChart (Gráficas 1 a 10)

1. **Línea Simple Básica**: Trazado continuo con `isCurved: false`, sin sombras ni gradientes.
2. **Línea Suavizada (Spline)**: Trazado suave con `isCurved: true` y `curveSmoothness: 0.35`.
3. **Línea con Área Sombreada**: Uso de `BelowBarData(show: true)` con color de fondo sólido translúcido.
4. **Línea Discontinua (Dashed Line)**: Trazado con patrón discontinuo usando `dashArray: [5, 5]`.
5. **Doble Línea (Goles Local vs Visitante)**: 2 `LineChartBarData` en una misma lista `lineBarsData`.
6. **Línea con Marcadores Personalizados**: `FlDotData` habilitado mostrando nodos circulares de color personalizado.
7. **Línea Limpia sin Grilla**: Configuración con `FlGridData(show: false)` y `FlBorderData(show: false)`.
8. **Línea con Gradiente Vertical**: Color de línea definido mediante `LinearGradient` de arriba a abajo.
9. **Línea con Rango Y Fijo**: Configuración explícita de `minY: 0` y `maxY: 100` para normalizar escalas.
10. **Línea con Umbral Promedio**: `ExtraLinesData` que dibuja una línea horizontal discontinua roja en el valor medio.

#### BarChart (Gráficas 11 a 25)

11. **Barras Verticales Simples**: Columnas unicolores para puntos por equipo.
12. **Barras con Ancho Variable**: `BarChartRodData` modificando la propiedad `width` según categorías.
13. **Barras Horizontales**: Rotación visual del gráfico mediante intercambio de ejes en títulos y coordenadas.
14. **Barras Agrupadas (3 Series)**: `BarChartGroupData` conteniendo 3 `BarChartRodData` (Victorias, Empates, Derrotas).
15. **Barras Apiladas (Stacked Rods)**: Un solo `BarChartRodData` con múltiples `BarChartRodStackItem`.
16. **Barras con Bordes Redondeados**: Configuración de `borderRadius: BorderRadius.circular(8)` en la parte superior.
17. **Barras con Gradiente Individual**: Cada barra con gradiente vertical asignado en `gradient`.
18. **Barras con Fondo Sombra**: `backDrawRodData` habilitado para mostrar la capacidad máxima teórica detrás.
19. **Barras con Valores Superiores**: Etiquetas de texto colocadas arriba de cada barra mediante `showingTooltipIndicators`.
20. **Barras con Grilla Personalizada**: `FlGridData` con líneas horizontales punteadas y sin líneas verticales.
21. **Barra Métrica Única Destacada**: Muestra una sola barra gigante centrada con indicadores de rango.
22. **Barras Comparativas 1v1**: Dos barras contrapuestas para comparar dos clubes específicos.
23. **Barras Condicionales por Color**: Color dinámico (Verde si `y >= 50`, Rojo si `y < 50`).
24. **Histograma Fino**: Barras muy delgadas (`width: 3`) simulando distribución de frecuencias de goles.
25. **Barras en Bloques Cuadrados**: `borderRadius: BorderRadius.zero` con estética flat/retro.

#### PieChart (Gráficas 26 a 35)

26. **Pastel Estándar**: Tarta completa dividida por resultados de partidos.
27. **Gráfico de Dona**: `PieChartData` con `centerSpaceRadius: 40`.
28. **Dona con Leyenda Central**: Dona con un widget `Text` estático dentro del espacio central.
29. **Sección Seleccionada Desplazada**: Una sección con `radius` incrementado para destacar la categoría dominante.
30. **Pastel con Porcentajes Internos**: Muestra los porcentajes formateados dentro de cada `PieChartSectionData`.
31. **Pastel con Badges/Iconos**: Asignación de widgets pequeños en la propiedad `badgeWidget` de cada sección.
32. **Dona con Bordes de Separación**: `sectionsSpace: 4` con bordes blancos entre secciones.
33. **Pastel Bipartito**: Tarta dividida estrictamente en 2 secciones (Local vs Visitante).
34. **Dona Delgada Estilo Ring**: `centerSpaceRadius: 65` y `radius: 15` para una estética minimalista.
35. **Pastel con Gradientes Radiales**: Secciones coloreadas con gradientes individuales.

#### ScatterChart & RadarChart (Gráficas 36 a 43)

36. **Dispersión Básica**: Relación Año de Fundación vs Capacidad de Estadio.
37. **Dispersión con Nodos de Tamaño Dinámico**: `ScatterSpot` con propiedad `radius` proporcional a puntos.
38. **Dispersión Categorizada por Color**: Puntos agrupados por colores según la liga a la que pertenecen.
39. **Dispersión Minimalista**: Gráfico sin ejes, bordes ni grilla, únicamente la distribución de puntos.
40. **Radar de 3 Ejes (Ataque, Defensa, Posesión)**: `RadarChartData` con 3 títulos perimetrales.
41. **Radar de 5 Ejes (Métricas de Partido)**: Evalúa 5 atributos estadísticos clave.
42. **Radar con Relleno Translúcido**: `RadarDataSet` con `fillColor` usando opacidad al 0.3.
43. **Radar con Vértices Marcados**: Puntos destacados en cada intersección del polígono.

---

### B. Gráficas Avanzadas (36 Total)

#### Interactivas y Táctiles (Gráficas 1 a 10)

1. **LineChart con Tooltip Flotante Personalizado**: `LineTouchData` con `touchTooltipData` renderizando una Card con datos del partido.
2. **BarChart con Selección e Indicador Visual**: Al presionar una barra, esta cambia de color y actualiza un estado local.
3. **PieChart Expansible al Toque**: `PieTouchData` que ajusta dinámicamente el `radius` y `centerSpaceRadius` de la sección tocada.
4. **ScatterChart con Popover Informativo**: Muestra una ventana superpuesta con el nombre del estadio al presionar un punto.
5. **LineChart con Crosshairs (Líneas Guía)**: Dibuja líneas cruzadas vertical/horizontal exactas en la posición del dedo.
6. **BarChart con Filtro Táctil Integrado**: Presionar un segmento de la barra apilada filtra los datos globales del dashboard.
7. **RadarChart con Resaltado de Eje**: Al hacer tap sobre una esquina, resalta el valor numérico de ese vértice.
8. **LineChart con Zoom/Panorámica**: Integración dentro de un `InteractiveViewer` ajustando los límites `minX` y `maxX`.
9. **BarChart con Conmutador de Leyenda**: Tocar la leyenda oculta o muestra series específicas dinámicamente.
10. **PieChart Rotatorio Interactivo**: Cambio dinámico de `startDegreeOffset` mediante gestos horizontales (`OnPanUpdate`).

#### Múltiples Series, Combinadas y Layouts Complejos (Gráficas 11 a 20)

11. **Multi-Línea de Top 5 Equipos**: 5 líneas paralelas representando la lucha por el título durante 38 jornadas.
12. **BarChart Apilado Complejo (5 Niveles)**: Desglose de goles (Jugada, Cabeza, Penalti, Tiro Libre, Autogol).
13. **Radar Comparativo Directo (2 Equipos Superpuestos)**: Dos `RadarDataSet` en el mismo gráfico (ej. Real Madrid vs Barcelona).
14. **LineChart con Banda de Desviación/Incertidumbre**: Dos líneas de límite con área sombreada intermedia representando rangos esperados.
15. **Visualización Combinada Simulada (Barras + Línea)**: `Stack` de un `BarChart` y un `LineChart` transparente sincronizados en coordenadas.
16. **LineChart con Eje Y Doble (Escalas Independientes)**: Simulación visual de 2 ejes Y (Goles a la izquierda, Posesión a la derecha).
17. **BarChart Divergente (Valores Positivos/Negativos)**: Eje central en `Y=0` mostrando diferencia de goles positiva (arriba) o negativa (abajo).
18. **ScatterChart con Línea de Tendencia (Regresión Lineal)**: Puntos de dispersión combinados con un `LineChartBarData` de ajuste.
19. **LineChart con Anotaciones de Eventos**: Íconos colocados en puntos específicos (`FlDotCustomWidget`) indicando goles o tarjetas.
20. **BarChart con Reordenamiento Animado**: Botón que reordena las barras (por Puntos, por Goles, Alfabético) ejecutando animación fluida.

#### Dashboard, Stateful, Dynamic Streams & Real-time Filters (Gráficas 21 a 36)

21. **LineChart Reactivo a Stream (Simulación En Vivo)**: `StreamBuilder` que añade un punto cada 2 segundos simulando tiempo real.
22. **BarChart con Control de Rango de Fechas**: Selector de rango (`DateRangePicker`) que reconstruye el gráfico dinámicamente.
23. **PieChart Reactivo a Dropdown de Liga**: Menú desplegable que cambia el dataset entre Premier League, La Liga y Serie A.
24. **ScatterChart con Slider de Capacidad**: Slider que filtra estadios con capacidad mayor al valor seleccionado.
25. **RadarChart con Switch de Modo (Absoluto vs Porcentaje)**: Toogle que recalculas los datos en base 100%.
26. **LineChart con Acumulado Móvil**: Checkbox para conmutar entre Goles por Jornada vs Goles Acumulados.
27. **BarChart Paginado**: Botones "Siguiente / Anterior" para mostrar 5 equipos a la vez.
28. **PieChart Animado Autopropulsado**: `AnimationController` que hace rotar la dona suavemente cuando no se interactúa.
29. **Dashboard Card: Rendimiento Local vs Visitante**: Componente compacto con mini LineChart + indicadores numéricos.
30. **Dashboard Card: Distribución de Tarjetas**: Mini PieChart con métricas rápidas de disciplina.
31. **LineChart Multi-Filtro (Temporada + Posición)**: Filtro combinado de 2 parámetros mediante `SegmentedButton`.
32. **BarChart con Búsqueda por Texto**: `TextField` que resalta la barra del equipo buscado.
33. **RadarChart con Promedio de Liga Superpuesto**: Muestra el rendimiento del equipo X comparado contra la media de la liga.
34. **LineChart Histórico (Comparativa de 3 Temporadas)**: Misma liga evaluada en 2021, 2022 y 2023.
35. **BarChart Top vs Bottom**: Comparativa split directa entre los primeros 3 y los últimos 3 de la tabla.
36. **Master Chart Dashboard**: Gráfico avanzado interactivo que integra tooltips contextuales, animaciones de entrada, exportación de estado y cambio de temas (Dark/Light mode).

---

## 4. Plantilla de Código Reutilizable (Production-Ready)

### Conversor de Datos: `lib/fl_chart/models/fl_chart_mapper.dart`

```dart
import 'package:fl_chart/fl_chart.dart';
import '../../THE_SPORTS_DB_API.md'; // Referencia a conceptos

class FlChartMapper {
  /// Convierte un ChartDataSet general a una lista de FlSpot para LineChart
  static List<FlSpot> toFlSpots(ChartDataSet dataSet) {
    return dataSet.points.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final point = entry.value;
      return FlSpot(index, point.value);
    }).toList();
  }

  /// Convierte un ChartDataSet a grupos de barras simples
  static List<BarChartGroupData> toBarGroups(ChartDataSet dataSet) {
    return dataSet.points.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: point.value,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }
}

```

### Contenedor Estandarizado: `lib/fl_chart/widgets/chart_card_wrapper.dart`

```dart
import 'package:flutter/material.dart';

class ChartCardWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;
  final double aspectRatio;

  const ChartCardWrapper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chart,
    this.aspectRatio = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: aspectRatio,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}

```

---

## 5. Instrucciones Directas para la Generación con OpenCode

1. **Gestión de Desbordamiento (Overflow)**:
* Todo gráfico DEBE estar envuelto dentro de un `ChartCardWrapper` o un `AspectRatio` explícito.
* Prohibido dejar coordenadas `x` o `y` infinitas o `NaN`. Utilizar siempre las extensiones de sanitización `toSafeDouble()`.


2. **Títulos y Ejes**:
* Para evitar superposición de texto en los ejes X/Y, configurar `reservedSize` adecuadamente en `SideTitles`.
* Utilizar funciones `getTitlesWidget` que validen si el índice está dentro de los límites de la lista (`index >= 0 && index < list.length`).


3. **Optimización de Rendimiento**:
* Usar la propiedad `swapAnimationDuration` para controlar la suavidad de las animaciones al cambiar estados.
* Instanciar configuraciones estáticas de `FlGridData` y `FlBorderData` con constructores `const`.


4. **Modularidad**:
* Cada una de las 79 gráficas debe ser una clase independiente (`StatelessWidget` o `StatefulWidget`) o una función constructora bien documentada en su archivo correspondiente.

