import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../widgets/app_logo.dart';

class ShellTab {
  const ShellTab({required this.label, required this.icon, required this.screen});

  final String label;
  final IconData icon;
  final Widget screen;
}

/// Shared responsive navigation shell for both the Admin and Staff modules:
/// a [NavigationRail] on wide (web/desktop) layouts, a [BottomNavigationBar]
/// on narrow (mobile) layouts.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.title, required this.tabs});

  final String title;
  final List<ShellTab> tabs;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final content = IndexedStack(
      index: _index,
      children: widget.tabs.map((t) => t.screen).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32, borderRadius: 8),
            const SizedBox(width: 12),
            Text(widget.title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: widget.tabs
                      .map((t) => NavigationRailDestination(
                            icon: _HoverLiftIcon(icon: t.icon),
                            selectedIcon: _HoverLiftIcon(icon: t.icon),
                            label: Text(t.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              items: widget.tabs
                  .map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
                  .toList(),
            ),
    );
  }
}

/// Scales its icon up slightly on mouse hover instead of relying on the
/// default selected-destination indicator pill, which rendered the same
/// color as the icon and made it disappear.
class _HoverLiftIcon extends StatefulWidget {
  const _HoverLiftIcon({required this.icon});

  final IconData icon;

  @override
  State<_HoverLiftIcon> createState() => _HoverLiftIconState();
}

class _HoverLiftIconState extends State<_HoverLiftIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Icon(widget.icon),
      ),
    );
  }
}
