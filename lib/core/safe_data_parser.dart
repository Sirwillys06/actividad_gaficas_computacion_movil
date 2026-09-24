/// Sanitización de datos crudos de TheSportsDB (numeros como String,
/// nulos, sufijos como "%" o comas de miles).
///
/// Nota: se declara `on Object?` en vez de `on dynamic`. Dart nunca
/// resuelve extensiones sobre un receptor de tipo estático `dynamic`
/// (siempre termina en un `NoSuchMethodError` en tiempo de ejecución);
/// `Object?` es el tipo concreto que sí permite invocarla como
/// `valor.toSafeDouble()` sin perder la posibilidad de recibir
/// cualquier valor (String, num, null, etc.) proveniente del JSON.
extension SafeDataParser on Object? {
  double toSafeDouble({double defaultValue = 0.0}) {
    if (this == null) return defaultValue;
    if (this is double) return this as double;
    if (this is int) return (this as int).toDouble();

    final str = toString().replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(str) ?? defaultValue;
  }

  int toSafeInt({int defaultValue = 0}) {
    if (this == null) return defaultValue;
    if (this is int) return this as int;
    if (this is double) return (this as double).toInt();

    final str = toString().replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(str) ?? defaultValue;
  }

  DateTime toSafeDate() {
    if (this == null) return DateTime.now();
    return DateTime.tryParse(toString()) ?? DateTime.now();
  }

  String toSafeString({String defaultValue = ''}) {
    if (this == null) return defaultValue;
    final str = toString().trim();
    return str.isEmpty ? defaultValue : str;
  }
}
