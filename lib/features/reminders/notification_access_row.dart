import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'reminders.dart';

/// Says out loud that reminders will not arrive, and offers the one way
/// to fix it. Before this, a "Don't allow" left the Settings switch on and
/// the app silent about it (Rafım Ar-Ge 24 Oct). The state is in words and
/// an icon, never colour alone.
class NotificationAccessRow extends ConsumerWidget {
  const NotificationAccessRow({super.key, this.onItem = false});

  /// On a product page: only a real "off" is worth a line there; "not
  /// asked yet" is the after-save question's job.
  final bool onItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(notificationAccessProvider).value;
    if (access == null || access == NotificationAccess.granted) return const SizedBox.shrink();
    if (onItem && access == NotificationAccess.notAsked) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final denied = access == NotificationAccess.denied;
    final container = ProviderScope.containerOf(context, listen: false);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(child: Icon(Icons.notifications_off_outlined, size: 20, color: context.c.textSecondary)),
            const SizedBox(width: VSpace.md),
            Expanded(
              child: Text(
                onItem ? l.notifyOffItem : (denied ? l.notifyOff : l.notifyNotAsked),
                style: context.t.small.copyWith(color: context.c.textSecondary),
              ),
            ),
            const SizedBox(width: VSpace.sm),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(VSize.minTap, VSize.minTap),
                foregroundColor: context.c.text,
              ),
              onPressed: () =>
                  denied ? ref.read(reminderSchedulerProvider).openSettings() : askNotificationPermission(container),
              child: Text(denied ? l.notifyOpenSettings : l.notifyAllow),
            ),
          ],
        ),
      ),
    );
  }
}
