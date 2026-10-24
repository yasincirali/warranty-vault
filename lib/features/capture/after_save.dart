import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../items/domain/item.dart';
import '../items/providers.dart';
import '../items/ui/documents.dart';
import '../reminders/reminder_plan.dart';
import '../reminders/reminders.dart';
import '../settings/settings.dart';

/// The two questions that follow a saved product (Rafım Ar-Ge 24 Oct,
/// yasin "yap"), asked while the paper is still in the shopping bag:
///
/// 1. Its receipt. The product photo comes first (the cabinet), but the
///    receipt is what a seller asks for, and thermal paper fades within
///    months; until now it could only be added from the product page.
/// 2. Notifications, the first time a product has a reminder ahead. Our
///    own one-line question goes before the system prompt, which iOS shows
///    once: a reflex "Don't allow" there used to leave the Settings switch
///    on and every reminder silently missing.
///
/// True while these run; the rating ask waits for them (see ReviewPrompt).
final afterSaveBusy = ValueNotifier<bool>(false);

/// The product falls onto its shelf first; the question comes once it is
/// seen standing there.
const afterSaveSettle = Duration(milliseconds: 900);

/// "Later" this many times and the receipt is not asked after a save any
/// more: this user keeps receipts elsewhere. The product page still offers it.
const receiptAskLimit = 3;

/// "Not now" this many times and our question stops; Settings keeps the
/// way back.
const notifyAskLimit = 2;

const receiptLaterKey = 'receipt_ask_later', notifyNotNowKey = 'notify_ask_not_now';

/// Pure: whether to ask for the receipt of a just-saved product.
bool shouldAskReceipt({required Item item, required int laters}) =>
    !item.sample && item.receipt == null && laters < receiptAskLimit;

/// Pure: whether to ask about notifications after this save.
bool shouldAskNotify({
  required bool remindersOn,
  required bool askedBefore,
  required int notNows,
  required bool hasReminder,
}) => remindersOn && !askedBefore && notNows < notifyAskLimit && hasReminder;

/// Runs after the add screen has closed with [itemId]. Takes the navigator
/// and the container, not a widget: the screen that opened the add screen
/// (the empty cabinet) is gone once its first product lands.
Future<void> afterSave(NavigatorState nav, ProviderContainer c, String itemId) async {
  afterSaveBusy.value = true;
  try {
    await Future<void>.delayed(afterSaveSettle);
    final store = c.read(settingsStoreProvider);
    int count(String key) => int.tryParse(store.read(key) ?? '') ?? 0;

    var item = c.read(vaultProvider).value?.items.where((i) => i.id == itemId).firstOrNull;
    // Something else opened meanwhile (a reminder tap): not over it.
    if (item == null || !nav.mounted || nav.canPop()) return;

    if (shouldAskReceipt(item: item, laters: count(receiptLaterKey))) {
      final source = await _receiptSheet(nav);
      if (source == null) {
        await store.write(receiptLaterKey, '${count(receiptLaterKey) + 1}');
      } else if (nav.mounted) {
        final l = AppLocalizations.of(nav.context);
        await saveDoc(c, ScaffoldMessenger.of(nav.context), l, itemId, DocKind.receipt, source);
      }
    }

    final views = await c.read(itemViewsProvider.future);
    final now = c.read(clockProvider)();
    final mine = planReminders(views.where((v) => v.item.id == itemId), now);
    final ask = shouldAskNotify(
      remindersOn: c.read(settingsProvider).reminders,
      askedBefore: store.read(remindersAskedKey) != null,
      notNows: count(notifyNotNowKey),
      hasReminder: mine.isNotEmpty,
    );
    if (!ask || !nav.mounted || nav.canPop()) return;
    final yes = await _notifySheet(nav, mine.first.fireAt);
    if (yes == true) {
      await askNotificationPermission(c);
    } else {
      await store.write(notifyNotNowKey, '${count(notifyNotNowKey) + 1}');
    }
  } catch (e, s) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'after save'));
  } finally {
    afterSaveBusy.value = false;
  }
}

Future<DocSource?> _receiptSheet(NavigatorState nav) => showModalBottomSheet<DocSource>(
  context: nav.context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheet) {
    final l = AppLocalizations.of(sheet);
    return _Sheet(
      title: l.receiptAskTitle,
      body: l.receiptAskBody,
      actions: [
        ...docSourceButtons(sheet, l),
        _Later(label: l.later, onTap: () => Navigator.of(sheet).pop()),
      ],
    );
  },
);

Future<bool?> _notifySheet(NavigatorState nav, DateTime first) => showModalBottomSheet<bool>(
  context: nav.context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheet) {
    final l = AppLocalizations.of(sheet);
    return _Sheet(
      title: l.notifyAskTitle,
      body: '${l.notifyAskBody}\n${l.notifyAskFirst(fmtDate(sheet, first))}',
      actions: [
        FilledButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(sheet).pop(true);
          },
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(VSize.button)),
          child: Text(l.notifyAskYes),
        ),
        const SizedBox(height: VSpace.sm),
        _Later(label: l.notNow, onTap: () => Navigator.of(sheet).pop(false)),
      ],
    );
  },
);

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.body, required this.actions});
  final String title, body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(VSpace.xl, 0, VSpace.xl, VSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: context.t.title)),
          const SizedBox(height: VSpace.sm),
          Text(body, style: context.t.body.copyWith(color: context.c.textSecondary)),
          const SizedBox(height: VSpace.lg),
          ...actions,
        ],
      ),
    ),
  );
}

class _Later extends StatelessWidget {
  const _Later({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size.fromHeight(VSize.button),
      foregroundColor: context.c.textSecondary,
    ),
    child: Text(label),
  );
}
