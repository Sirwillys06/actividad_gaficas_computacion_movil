# Syncfusion Flutter Charts — Sports Analytics

## Arquitectura

La rama separa la aplicación en cuatro capas:

- `core/`: configuración, constantes, tema y utilidades.
- `data/models/`: entidades deportivas.
- `data/services/`: comunicación HTTP con TheSportsDB.
- `data/repositories/`: acceso a datos desacoplado de la UI.
- `data/mappers/`: transformación de datos deportivos a datos de gráficos.
- `presentation/screens/`: pantallas.
- `presentation/widgets/`: componentes reutilizables.
- `presentation/charts/`: widgets exclusivamente responsables de Syncfusion.

Flujo:

`DashboardScreen -> SportsRepository -> SportsApiService -> TheSportsDB`

Los charts reciben listas ya transformadas y no realizan llamadas HTTP.

## TheSportsDB

La implementación usa la API REST v1 gratuita.

Endpoints utilizados:

- `all_leagues.php`
- `search_all_teams.php?l={liga}`
- `eventspastleague.php?id={idLiga}`
- `eventsnextleague.php?id={idLiga}`

La documentación oficial indica que la API v1 gratuita usa una clave pública de desarrollo y que los métodos gratuitos tienen límites de consulta. Por eso el cliente también maneja respuestas vacías, errores HTTP y timeout.

## Gráficos

### Column chart
Compara los goles registrados por equipo en los eventos disponibles.

### Doughnut chart
Distribuye los resultados en:
- victorias locales;
- empates;
- victorias visitantes.

### Line chart
Muestra los goles totales de los partidos recientes.

No se generan estadísticas artificiales. Si la API no entrega marcadores suficientes, la interfaz muestra un estado vacío.

## Interactividad

- Tooltips en los gráficos.
- Selección de puntos en el gráfico de columnas.
- Zoom y pan en la evolución de goles.
- Crosshair en la evolución temporal.
- Leyenda y etiquetas de datos en el doughnut.

## Estados

La aplicación contempla:

- carga inicial;
- carga posterior al cambiar de liga;
- éxito;
- respuesta vacía;
- errores HTTP/API;
- timeout;
- JSON inválido;
- error de conexión.

## Configuración

La API pública de desarrollo se encuentra en:

`lib/syncfusion_flutter_charts/core/config/api_config.dart`

Si se dispone de una clave premium, se puede reemplazar allí sin modificar los servicios ni la UI.

## Verificación local

Desde la raíz del proyecto:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Para revisar específicamente esta rama:

```bash
git checkout syncfusion_flutter_charts
git status
```

Las otras implementaciones de gráficos permanecen en sus propias ramas y no forman parte de los widgets de esta implementación.
