import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';
import '../items/providers.dart';
import '../items/ui/item_detail_screen.dart';
import '../items/ui/item_photo.dart';
import 'search.dart';

/// "Where is the receipt for the kettle?": the field is focused on
/// arrival, results update with every letter, each row says the status in
/// a sentence. The cabinet is the browsing view; this is the finding view.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.autofocus = true});

  /// Off when a grouped reminder opens the soonest list: the user came to
  /// read it, not to type, and a keyboard would cover it.
  final bool autofocus;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = ref.watch(searchIndexProvider).value ?? const <SearchEntry>[];
    final today = ref.watch(clockProvider)();
    final q = _query.text;
    final hits = searchItems(index, q);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: VSpace.lg),
          child: TextField(
            controller: _query,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            onTapOutside: dismissKeyboard,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l.searchClear,
                      icon: const Icon(Icons.cancel),
                      onPressed: () => setState(_query.clear),
                    ),
            ),
          ),
        ),
      ),
      body: q.trim().isEmpty
          ? _Soonest(views: soonestEnding(index), today: today)
          : hits.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(VSpace.xl),
                  child: Text(l.searchNone(q.trim()), style: context.t.body.copyWith(color: context.c.textSecondary)),
                )
              : ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
                  itemCount: hits.length,
                  itemBuilder: (context, i) => _Hit(view: hits[i], today: today, last: i == hits.length - 1),
                ),
    );
  }
}

/// Before typing: every product, soonest end on top, in the same rows the
/// results use, so the page is useful the moment it opens.
class _Soonest extends StatelessWidget {
  const _Soonest({required this.views, required this.today});
  final List<ItemView> views;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
      itemCount: views.length + 1,
      itemBuilder: (context, i) => i == 0
          ? SectionTitle(l.searchSoonest)
          : _Hit(view: views[i - 1], today: today, last: i == views.length),
    );
  }
}

class _Hit extends StatelessWidget {
  const _Hit({required this.view, required this.today, required this.last});
  final ItemView view;
  final DateTime today;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = view.primary;
    final active = p != null && p.status == ProtectionStatus.active;
    final status = !active
        ? l.protectionEnded
        : l.statusLine(kindLabel(l, p.kind), p.end == null ? l.noFixedEnd : remainingLabel(l, today, p.end!));
    final urgent = view.next != null;
    final hasReceipt = view.item.receipt != null;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: view.item.id))),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: VSpace.sm + 2),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: context.c.divider)),
        ),
        child: Row(children: [
          ItemPhoto(item: view.item),
          const SizedBox(width: VSpace.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(view.item.name, style: context.t.label),
              Text(
                [view.item.store, status].where((s) => s.isNotEmpty).join(' · '),
                style: context.t.small.copyWith(color: urgent ? context.c.deadline : context.c.textSecondary),
              ),
            ]),
          ),
          // The question people search with is often "do I still have the
          // receipt?"; the answer shows without opening the product.
          if (hasReceipt)
            Padding(
              padding: const EdgeInsets.only(left: VSpace.sm),
              child: Icon(Icons.receipt_long_outlined, size: 18, color: context.c.textSecondary, semanticLabel: l.docReceipt),
            ),
          Icon(Icons.chevron_right, color: context.c.muted, size: 20),
        ]),
      ),
    );
  }
}
