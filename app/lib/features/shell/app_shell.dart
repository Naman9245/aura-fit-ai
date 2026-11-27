import 'dart:math' as math;

import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        onSelect: (tab) {
          if (tab.index != shell.currentIndex) {
            // A haptic is a nicety: a phone without one just stays still.
            HapticFeedback.selectionClick().ignore();
          }
          // Tapping the open tab again takes it back to its top.
          shell.goBranch(
            tab.index,
            initialLocation: tab.index == shell.currentIndex,
          );
        },
      ),
    );
  }
}

/// The tabs' screens, one on show at a time. Each keeps its state, and the
/// one that opens fades and rises in.
class TabsContainer extends StatefulWidget {
  const TabsContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<TabsContainer> createState() => _TabsContainerState();
}

class _TabsContainerState extends State<TabsContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _rise = Tween(
    begin: const Offset(0, 0.02),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void didUpdateWidget(TabsContainer old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex && !motionOff(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentIndex,
      children: [
        for (final (index, child) in widget.children.indexed)
          Offstage(
            offstage: index != widget.currentIndex,
            child: TickerMode(
              enabled: index == widget.currentIndex,
              // The same widgets for every tab, so none loses its state.
              child: FadeTransition(
                opacity: index == widget.currentIndex
                    ? _fade
                    : kAlwaysCompleteAnimation,
                child: SlideTransition(
                  position: index == widget.currentIndex
                      ? _rise
                      : const AlwaysStoppedAnimation(Offset.zero),
                  child: child,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The bar of tabs: an orange pill slides to the open one.
class AuraTabBar extends StatelessWidget {
  const AuraTabBar({super.key, required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final still = motionOff(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AuraColors.black,
        border: Border(top: BorderSide(color: AuraColors.surfaceStrong)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / AppTab.values.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: still
                        ? Duration.zero
                        : const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    left: current.index * width + 3,
                    width: width - 6,
                    top: 0,
                    bottom: 0,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AuraColors.accent,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                  Row(
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
                ],
              );
            },
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
    final label = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: tab.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
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
              // 0 to 1 as the tab opens: the colour turns to ink and the
              // icon gives a little hop.
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: selected ? 1 : 0),
                duration: motionOff(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                builder: (context, t, _) {
                  final fg = Color.lerp(AuraColors.muted, AuraColors.ink, t)!;
                  final hop = selected ? math.sin(t * math.pi) : 0.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -4 * hop),
                        child: Transform.scale(
                          scale: 1 + 0.15 * hop,
                          child: Icon(tab.icon, size: 22, color: fg),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: label?.copyWith(
                          color: fg,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
