import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The four tabs, in the order the bar shows them.
enum AppTab {
  today('Today', Icons.home_rounded),
  train('Train', Icons.fitness_center_rounded),
  food('Food', Icons.restaurant_rounded),
  progress('Progress', Icons.bar_chart_rounded);

  const AppTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Today, Train, Food and Progress, with the tab bar under them. Each tab
/// keeps its place while another one is open.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AuraTabBar(
        current: AppTab.values[shell.currentIndex],
        // Tapping the open tab again takes it back to its top.
        onSelect: (tab) => shell.goBranch(
          tab.index,
          initialLocation: tab.index == shell.currentIndex,
        ),
      ),
    );
  }
}

/// The bar of tabs: the open one sits on an orange pill.
class AuraTabBar extends StatelessWidget {
  const AuraTabBar({super.key, required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AuraColors.black,
        border: Border(top: BorderSide(color: AuraColors.surfaceStrong)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              for (final tab in AppTab.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _TabButton(
                      tab: tab,
                      selected: tab == current,
                      onTap: () => onSelect(tab),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AuraColors.ink : AuraColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: tab.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AuraColors.accent : Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tab.icon, size: 22, color: fg),
                  const SizedBox(height: 2),
                  Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
