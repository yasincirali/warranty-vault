import 'package:flutter/widgets.dart';

/// Knows when a screen that was popped has finished sliding away.
///
/// The cabinet needs this: a new product should fall onto its shelf when
/// the user can see the shelf, not behind the closing add screen. A
/// full-screen dialog does not animate the route below it, so the home
/// route's own secondaryAnimation cannot tell; the navigator can.
class CoverObserver extends NavigatorObserver with ChangeNotifier {
  final _leaving = <Animation<double>>{};

  /// True while a popped screen is still on its way out.
  bool get busy => _leaving.isNotEmpty;

  void _track(Route<dynamic> route) {
    if (route is! TransitionRoute) return;
    final a = route.animation;
    if (a == null || a.isDismissed) {
      notifyListeners();
      return;
    }
    _leaving.add(a);
    void done(AnimationStatus s) {
      if (!s.isDismissed) return;
      a.removeStatusListener(done);
      _leaving.remove(a);
      notifyListeners();
    }

    a.addStatusListener(done);
    notifyListeners();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _track(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _track(route);
}

/// One navigator, one observer.
final coverObserver = CoverObserver();
