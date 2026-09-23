


# Especificación General de Datos: TheSportsDB API (v1 - Key 3)

## 1. Contexto y Arquitectura General
Este documento define la especificación técnica de integración con la API pública de **TheSportsDB** (v1). Servirá como fuente de verdad única para transformar datos deportivos de red a estructuras de datos desacopladas, consumibles por **cualquiera de las 4 librerías de gráficos** implementadas en el proyecto:
- `fl_chart`
- `syncfusion_flutter_charts`
- `charts_flutter`
- `graphic`

---

## 2. Configuración de Servicio
- **URL Base**: `https://www.thesportsdb.com/api/v1/json/3/`
- **Método HTTP**: `GET`
- **Autenticación**: Clave pública `3` (o `123`) inyectada en la ruta URL.
- **Formato**: JSON.
- **Headers HTTP recomendados**:
  - `Accept: application/json`

---

## 3. Estrategia de Parsing y Sanitización de Datos

La API de TheSportsDB devuelve valores numéricos representados como cadenas de texto (`String`), campos nulos opcionales y formatos irregulares (ej. `"75%"`, `"1,200"`, `null`, `""`). 

### Extensiones de Sanitización en Dart
Todo adaptador de datos debe utilizar estrictamente las siguientes extensiones antes de instanciar un objeto para las gráficas:

```dart
extension SafeDataParser on dynamic {
  /// Convierte cualquier entrada (String, int, double, null) a double seguro.
  double toSafeDouble({double defaultValue = 0.0}) {
    if (this == null) return defaultValue;
    if (this is double) return this as double;
    if (this is int) return (this as int).toDouble();
    
    final str = this.toString().replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(str) ?? defaultValue;
  }

  /// Convierte cualquier entrada a entero seguro.
  int toSafeInt({int defaultValue = 0}) {
    if (this == null) return defaultValue;
    if (this is int) return this as int;
    if (this is double) return (this as double).toInt();
    
    final str = this.toString().replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(str) ?? defaultValue;
  }

  /// Parser seguro para fechas en formato YYYY-MM-DD.
  DateTime toSafeDate() {
    if (this == null) return DateTime.now();
    return DateTime.tryParse(this.toString()) ?? DateTime.now();
  }
}

```

---

## 4. Endpoints Oficiales, Modelos JSON y Mapeo Métrico

### 4.1. Tabla de Clasificación de Liga (*Standings*)

Muestra el rendimiento acumulado de los equipos en una temporada.

* **Endpoint**: `lookuptable.php`
* **Parámetros**: `l` (ID de liga), `s` (Temporada)
* **URL Ejemplo**: `https://www.thesportsdb.com/api/v1/json/3/lookuptable.php?l=4328&s=2023-2024`

#### Estructura del Payload JSON:

```json
{
  "table": [
    {
      "idStanding": "12345",
      "intRank": "1",
      "idTeam": "133604",
      "strTeam": "Arsenal",
      "intPlayed": "38",
      "intWin": "28",
      "intLoss": "5",
      "intDraw": "5",
      "intGoalsFor": "91",
      "intGoalsAgainst": "29",
      "intGoalDifference": "62",
      "intPoints": "89"
    }
  ]
}

```

#### Métricas Mapeables a Gráficos:

* **Barras / Columnas**: `intPoints`, `intGoalsFor`, `intGoalsAgainst` por `strTeam`.
* **Sectores / Pastel**: Distribución de `intWin`, `intLoss`, `intDraw` de un equipo.
* **Dispersión / Burbujas**: `intGoalsFor` (Eje X) vs `intGoalsAgainst` (Eje Y) vs `intPoints` (Tamaño).

---

### 4.2. Calendario y Resultados de Temporada (*Events Season*)

Registra el historial de partidos jugados y programados.

* **Endpoint**: `eventsseason.php`
* **Parámetros**: `id` (ID de liga), `s` (Temporada)
* **URL Ejemplo**: `https://www.thesportsdb.com/api/v1/json/3/eventsseason.php?id=4328&s=2023-2024`

#### Estructura del Payload JSON:

```json
{
  "events": [
    {
      "idEvent": "1032718",
      "strEvent": "Arsenal vs Chelsea",
      "intRound": "1",
      "dateEvent": "2023-08-12",
      "strTimestamp": "2023-08-12T11:30:00+00:00",
      "intHomeScore": "2",
      "intAwayScore": "1",
      "intSpectators": "60250",
      "strStatus": "Match Finished"
    }
  ]
}

```

#### Métricas Mapeables a Gráficos:

* **Líneas / Áreas (Series Temporales)**: Evolución de `intHomeScore` + `intAwayScore` por `dateEvent` o `intRound`.
* **Histogramas**: Asistencia de espectadores (`intSpectators`) en el tiempo.
* **Gráficos Combinados**: Promedio de goles por jornada vs Asistencia total.

---

### 4.3. Estadísticas Detalladas de un Partido (*Event Stats*)

Métricas métricamente balanceadas entre dos equipos en un partido específico.

* **Endpoint**: `lookupeventstats.php`
* **Parámetros**: `id` (ID de partido/evento)
* **URL Ejemplo**: `https://www.thesportsdb.com/api/v1/json/3/lookupeventstats.php?id=1032718`

#### Estructura del Payload JSON:

```json
{
  "eventstats": [
    {
      "idStatistic": "991",
      "strStat": "Shots on Goal",
      "intHome": "8",
      "intAway": "3"
    },
    {
      "idStatistic": "992",
      "strStat": "Possession",
      "intHome": "65%",
      "intAway": "35%"
    }
  ]
}

```

#### Métricas Mapeables a Gráficos:

* **Radar / Araña**: Comparativa multidimensional entre `intHome` e `intAway` para múltiples métricas (`strStat`).
* **Barras Agrupadas / Horizontales**: Comparación directa atributo por atributo.
* **Dona / Medidor (Gauge)**: Posesión local vs visitante.

---

### 4.4. Información Técnica de Equipos (*Search All Teams*)

Datos de infraestructura y demografía de los clubes de una liga.

* **Endpoint**: `search_all_teams.php`
* **Parámetros**: `l` (Nombre completo de la liga)
* **URL Ejemplo**: `https://www.thesportsdb.com/api/v1/json/3/search_all_teams.php?l=English%20Premier%20League`

#### Estructura del Payload JSON:

```json
{
  "teams": [
    {
      "idTeam": "133604",
      "strTeam": "Arsenal",
      "intFormedYear": "1886",
      "intCapacity": "60704",
      "strStadium": "Emirates Stadium",
      "strCountry": "England"
    }
  ]
}

```

#### Métricas Mapeables a Gráficos:

* **Dispersión (Scatter)**: `intFormedYear` vs `intCapacity`.
* **Barras Ordenadas**: Ranking de estadios por capacidad (`intCapacity`).

---

## 5. Modelo Unificado de Datos (Agnóstico a Librerías)

Para que las 4 librerías consuman exactamente la misma estructura sin reescribir la lógica de conexión HTTP, la capa de servicio debe mapear todas las respuestas a esta estructura canónica abstracta:

```dart
/// Punto de datos genérico para alimentar cualquier librería gráfica.
class ChartDataPoint {
  final String label;          // Categoría o etiqueta en eje X / Leyenda
  final double value;          // Valor numérico principal (Eje Y)
  final double? secondaryValue;// Valor secundario opcional (Eje Y2, radios, etc)
  final String? group;         // Nombre de la serie/grupo (ej. "Local", "Visitante")
  final DateTime? timestamp;   // Para series temporales
  final Map<String, dynamic>? extraMetaData; // Información para Tooltips personalizados

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.group,
    this.timestamp,
    this.extraMetaData,
  });
}

/// Contenedor de series de datos.
class ChartDataSet {
  final String title;
  final String xLabel;
  final String yLabel;
  final List<ChartDataPoint> points;

  const ChartDataSet({
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.points,
  });
}

```

---

## 6. Proveedor de Datos Sintéticos (Fallback & Offline Mode)

Debido al estrangulamiento de peticiones de la clave pública `3` o fallos de red durante desarrollo local, el cliente HTTP de la aplicación debe redirigir a un generador estático cuando detecte un error 429, timeout o respuesta vacía.

```dart
class SportsApiMock {
  static ChartDataSet getMockStandings() {
    return const ChartDataSet(
      title: "Posiciones Temporada (Mock)",
      xLabel: "Equipos",
      yLabel: "Puntos",
      points: [
        ChartDataPoint(label: "ARS", value: 89, secondaryValue: 91, group: "Top"),
        ChartDataPoint(label: "MCI", value: 91, secondaryValue: 96, group: "Top"),
        ChartDataPoint(label: "LIV", value: 82, secondaryValue: 86, group: "Top"),
        ChartDataPoint(label: "AVL", value: 68, secondaryValue: 76, group: "Mid"),
        ChartDataPoint(label: "TOT", value: 66, secondaryValue: 74, group: "Mid"),
        ChartDataPoint(label: "CHE", value: 63, secondaryValue: 77, group: "Mid"),
        ChartDataPoint(label: "NEW", value: 60, secondaryValue: 85, group: "Mid"),
        ChartDataPoint(label: "MUN", value: 60, secondaryValue: 57, group: "Low"),
      ],
    );
  }

  static ChartDataSet getMockMatchStats() {
    return const ChartDataSet(
      title: "Estadísticas de Partido (Mock)",
      xLabel: "Métrica",
      yLabel: "Cantidad",
      points: [
        ChartDataPoint(label: "Tiros a Puerta", value: 8, secondaryValue: 3, group: "Match"),
        ChartDataPoint(label: "Posesión %", value: 62, secondaryValue: 38, group: "Match"),
        ChartDataPoint(label: "Faltas", value: 11, secondaryValue: 14, group: "Match"),
        ChartDataPoint(label: "Córners", value: 7, secondaryValue: 2, group: "Match"),
        ChartDataPoint(label: "Tarjetas Amarillas", value: 1, secondaryValue: 4, group: "Match"),
      ],
    );
  }
}

```

---

## 7. IDs de Referencia Frecuentes (Cheat Sheet para Pruebas)

| Entidad | Nombre / Descripción | ID / Key |
| --- | --- | --- |
| **Liga** | English Premier League | `4328` |
| **Liga** | La Liga Española | `4335` |
| **Liga** | UEFA Champions League | `4480` |
| **Equipo** | Arsenal | `133604` |
| **Equipo** | Real Madrid | `133738` |
| **Temporada** | Temporada Reciente | `2023-2024` |
