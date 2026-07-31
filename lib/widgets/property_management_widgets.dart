import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_state_widgets.dart';

class HierarchyCrumb {
  final String label;
  final VoidCallback? onTap;

  const HierarchyCrumb(this.label, {this.onTap});
}

class HierarchyBreadcrumbs extends StatelessWidget {
  final List<HierarchyCrumb> items;

  const HierarchyBreadcrumbs({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            TextButton(
              onPressed: items[index].onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                foregroundColor: items[index].onTap == null
                    ? AppColors.textPrimary
                    : AppColors.primary,
              ),
              child: Text(items[index].label),
            ),
          ],
        ],
      ),
    );
  }
}

class SearchableManagementList<T> extends StatefulWidget {
  final List<T> items;
  final bool Function(T item, String query) matches;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final List<Widget> header;
  final String searchHint;
  final String emptyMessage;
  final String noResultsMessage;

  const SearchableManagementList({
    super.key,
    required this.items,
    required this.matches,
    required this.itemBuilder,
    required this.searchHint,
    required this.emptyMessage,
    required this.noResultsMessage,
    this.header = const [],
  });

  @override
  State<SearchableManagementList<T>> createState() =>
      _SearchableManagementListState<T>();
}

class _SearchableManagementListState<T>
    extends State<SearchableManagementList<T>> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) => widget.matches(item, _query))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        ...widget.header,
        TextField(
          controller: _controller,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            hintText: widget.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        if (widget.items.isEmpty)
          AppStateCard.empty(
            title: 'Nothing here yet',
            message: widget.emptyMessage,
          )
        else if (filtered.isEmpty)
          AppStateCard(
            icon: Icons.search_off_rounded,
            title: 'No matches found',
            message: widget.noResultsMessage,
            color: AppColors.warning,
          )
        else
          ...filtered.map((item) => widget.itemBuilder(context, item)),
      ],
    );
  }
}
