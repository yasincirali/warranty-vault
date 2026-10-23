import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../items/domain/vault.dart';
import '../settings/settings.dart';

/// The moment we ask for a rating (Rafım Ar-Ge 23 Oct, yasin "yap"):
/// right after the user's own third product has landed on its shelf. By
/// then the cabinet has shown what it is for; asking earlier (first run,
/// sample cabinet) asks someone who has not used it yet, and asking inside
/// "Something's wrong" or at the counter asks someone who is upset or busy.
/// Once per install: Apple caps the system sheet at three a year anyway,
/// and a second ask after a "not now" is the one people resent.
const reviewAfterOwnItems = 3;

/// Products the user added themselves, kept or thrown out (samples never
/// count: they are ours, not theirs).
int ownItemCount(Vault v) => v.items.where((i) => !i.sample).length;

/// Pure decision, so the rule is tested without a phone: exactly one own
/// product has just been added and the count is at the threshold or past
/// it. So a tester who already has ten products is asked after their next
/// one, not the moment the update opens, and restoring a backup (ten at
/// once) is not "just added a product".
bool shouldAskForReview({required Vault? before, required Vault after, required bool asked}) {
  if (asked || before == null) return false;
  final was = ownItemCount(before), now = ownItemCount(after);
  return now == was + 1 && now >= reviewAfterOwnItems;
}

/// The platform's own rating sheet (SKStoreReviewController / Play
/// in-app review); no screen of our own. Tests swap in a recorder.
abstract interface class ReviewRequester {
  Future<void> request();
}

class StoreReviewRequester implements ReviewRequester {
  @override
  Future<void> request() async {
    final r = InAppReview.instance;
    if (await r.isAvailable()) await r.requestReview();
  }
}

class NoReviewRequester implements ReviewRequester {
  @override
  Future<void> request() async {}
}

/// main() overrides this on iOS/Android.
final reviewRequesterProvider = Provider<ReviewRequester>((_) => NoReviewRequester());

class ReviewPrompt {
  ReviewPrompt({required this.store, required this.requester, required this.atHome});
  final SettingsStore Function() store;
  final ReviewRequester Function() requester;

  /// True while the cabinet is the visible screen: the sheet never opens
  /// over the problem flow, the counter screen or a product page.
  final bool Function() atHome;

  /// The fall onto the shelf and its haptic finish inside this; the sheet
  /// comes after the product is seen standing there.
  static const settle = Duration(seconds: 2);
  static const askedKey = 'review_asked';

  Timer? _timer;

  void onVault(Vault? before, Vault after) {
    if (!shouldAskForReview(before: before, after: after, asked: store().read(askedKey) != null)) return;
    _timer?.cancel();
    _timer = Timer(settle, _ask);
  }

  Future<void> _ask() async {
    // Not at home now (opened the new product, started a problem): skip
    // this one; the next own product tries again.
    if (!atHome()) return;
    try {
      await store().write(askedKey, '1');
      await requester().request();
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'review'));
    }
  }

  void dispose() => _timer?.cancel();
}
