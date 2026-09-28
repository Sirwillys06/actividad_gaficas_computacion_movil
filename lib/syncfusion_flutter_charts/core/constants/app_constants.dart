class AppConstants {
  static const String appName = 'Sports Analytics';
  static const String defaultLeagueId = '4328';
  static const String defaultLeagueName = 'English Premier League';
  static const String analyzedSport = 'Soccer';
  static const Duration requestTimeout = Duration(seconds: 12);
  static const int chartEventLimit = 12;

  /// Puntos por resultado (sistema estándar de fútbol).
  static const int pointsPerWin = 3;
  static const int pointsPerDraw = 1;

  /// El plan gratuito de TheSportsDB permite ~30 peticiones por minuto.
  /// Al completar una temporada jornada a jornada se espera este intervalo
  /// entre llamadas para no superar el límite.
  static const Duration roundRequestInterval = Duration(milliseconds: 2200);

  /// Máximo de jornadas que se intentan descargar al completar una temporada.
  static const int maxRoundsToFetch = 60;

  /// Número de partidos considerados como "forma reciente".
  static const int recentFormMatches = 5;

  /// Umbral clásico de mercado "más/menos de 2.5 goles".
  static const double overUnderLine = 2.5;
}
