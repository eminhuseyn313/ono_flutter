import 'package:quick_actions/quick_actions.dart';

/// Long-press the ONO icon: straight into the four things done most often.
class AppShortcut {
  final String type;
  final String title;
  final String route;
  const AppShortcut(this.type, this.title, this.route);
}

const appShortcutList = [
  AppShortcut('checkin', 'Morning check-in', '/checkin'),
  AppShortcut('protein', 'Log protein', '/log?add=protein'),
  AppShortcut('gym', 'Start gym session', '/gym'),
  AppShortcut('review', 'Review cards', '/review'),
];

String? routeForShortcut(String type) {
  for (final s in appShortcutList) {
    if (s.type == type) return s.route;
  }
  return null;
}

abstract class AppShortcuts {
  /// Registers the shortcuts; [onOpen] gets the route of the one tapped,
  /// including the one that launched the app.
  Future<void> init({required void Function(String route) onOpen});
}

/// Web and tests.
class NoopAppShortcuts implements AppShortcuts {
  const NoopAppShortcuts();
  @override
  Future<void> init({required void Function(String route) onOpen}) async {}
}

/// iOS Home Screen quick actions (`quick_actions`). No entitlement needed.
class QuickActionShortcuts implements AppShortcuts {
  final _actions = const QuickActions();

  @override
  Future<void> init({required void Function(String route) onOpen}) async {
    try {
      await _actions.initialize((type) {
        final route = routeForShortcut(type);
        if (route != null) onOpen(route);
      });
      await _actions.setShortcutItems([
        for (final s in appShortcutList)
          ShortcutItem(type: s.type, localizedTitle: s.title),
      ]);
    } catch (_) {
      // Platform without quick actions: nothing to add.
    }
  }
}
