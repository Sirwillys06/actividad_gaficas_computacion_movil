import 'package:flutter/widgets.dart';

import 'sports_repository.dart';

/// Expone el [SportsRepository] ya cargado a todo el árbol de widgets.
class SportsDataScope extends InheritedWidget {
  final SportsRepository repository;

  const SportsDataScope({
    super.key,
    required this.repository,
    required super.child,
  });

  static SportsRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SportsDataScope>();
    assert(scope != null, 'No SportsDataScope found in context');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(SportsDataScope oldWidget) =>
      repository != oldWidget.repository;
}
