import 'package:flutter/material.dart';

/// Hoja inferior con buscador para elegir uno o varios elementos de listas
/// largas (cientos de ligas, todos los equipos de una competición…).
class SearchSheet<T> extends StatefulWidget {
  const SearchSheet({
    super.key,
    required this.title,
    required this.items,
    required this.labelOf,
    this.subtitleOf,
    this.leadingOf,
    this.initialSelection = const [],
    this.multiple = false,
    this.maxSelection,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelOf;
  final String? Function(T item)? subtitleOf;
  final Widget Function(T item)? leadingOf;
  final List<T> initialSelection;
  final bool multiple;
  final int? maxSelection;

  /// Abre la hoja y devuelve la selección (null si se cancela).
  static Future<List<T>?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T item) labelOf,
    String? Function(T item)? subtitleOf,
    Widget Function(T item)? leadingOf,
    List<T> initialSelection = const [],
    bool multiple = false,
    int? maxSelection,
  }) => showModalBottomSheet<List<T>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: SearchSheet<T>(
        title: title,
        items: items,
        labelOf: labelOf,
        subtitleOf: subtitleOf,
        leadingOf: leadingOf,
        initialSelection: initialSelection,
        multiple: multiple,
        maxSelection: maxSelection,
      ),
    ),
  );

  @override
  State<SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<SearchSheet<T>> {
  String _query = '';
  late final List<T> _selected = [...widget.initialSelection];

  List<T> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items.where((item) {
      final label = widget.labelOf(item).toLowerCase();
      final subtitle = widget.subtitleOf?.call(item)?.toLowerCase() ?? '';
      return label.contains(query) || subtitle.contains(query);
    }).toList();
  }

  void _toggle(T item) {
    if (!widget.multiple) {
      Navigator.of(context).pop([item]);
      return;
    }
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else if (widget.maxSelection == null || _selected.length < widget.maxSelection!) {
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
              if (widget.multiple)
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text('Aplicar (${_selected.length})'),
                ),
            ],
          ),
          if (widget.multiple && widget.maxSelection != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Máximo ${widget.maxSelection} elementos', style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 12),
          TextField(
            autofocus: false,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar…'),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Sin resultados para la búsqueda.'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = _selected.contains(item);
                      final subtitle = widget.subtitleOf?.call(item);
                      return ListTile(
                        leading: widget.leadingOf?.call(item),
                        title: Text(widget.labelOf(item)),
                        subtitle: subtitle == null ? null : Text(subtitle),
                        selected: selected,
                        trailing: widget.multiple
                            ? Checkbox(value: selected, onChanged: (_) => _toggle(item))
                            : selected
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => _toggle(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
