import 'dart:async';

import 'package:aurafit/core/format.dart';
import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/core/theme/aura_type.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Icon matched to an Indian household or metric portion unit.
IconData iconForPortionUnit(String unit) {
  final u = unit.toLowerCase();
  if (u == 'g' || u == 'grams' || u == 'ml') return Icons.scale_outlined;
  if (u.contains('egg') || u.contains('white') || u.contains('yolk')) {
    return Icons.egg_outlined;
  }
  if (u.contains('+ gravy')) return Icons.ramen_dining_outlined;
  if (u.contains('roll') || u.contains('burger') || u.contains('momo')) {
    return Icons.lunch_dining_outlined;
  }
  if (u.contains('katori')) return Icons.soup_kitchen_outlined;
  if (u.contains('bowl')) return Icons.rice_bowl_outlined;
  if (u.contains('plate')) return Icons.dinner_dining_outlined;
  if (u.contains('glass') ||
      u.contains('bottle') ||
      u.contains('shaker') ||
      u.contains('tetrapak') ||
      u.contains('coconut')) {
    return Icons.local_drink_outlined;
  }
  if (u.contains('cup') || u.contains('mug') || u.contains('tumbler')) {
    return Icons.local_cafe_outlined;
  }
  if (u.contains('scoop')) return Icons.fitness_center_outlined;
  if (u.contains('tbsp') || u.contains('tsp') || u.contains('sachet')) {
    return Icons.restaurant_outlined;
  }
  if (u.contains('slice') ||
      u.contains('pav') ||
      u.contains('sandwich') ||
      u.contains('roti') ||
      u.contains('phulka') ||
      u.contains('dosa') ||
      u.contains('idli') ||
      u.contains('chilla') ||
      u.contains('vada')) {
    return Icons.bakery_dining_outlined;
  }
  if (u.contains('breast') ||
      u.contains('fillet') ||
      u.contains('quarter') ||
      u.contains('bird') ||
      u.contains('steak')) {
    return Icons.set_meal_outlined;
  }
  if (u.contains('pack') || u.contains('bar') || u.contains('tub')) {
    return Icons.inventory_2_outlined;
  }
  return Icons.pie_chart_outline;
}

/// Natural scrollable tick values for a portion [unit].
///
/// * Grams (`g`): 5 g / 10 g / 25 g steps from 5 g to 1,000 g.
/// * Bowls / katoris / glasses / plates: quarter & half steps (`0.25 .. 10`).
/// * Countable items (`egg`, `piece`, `idli`, `slice`, `biscuit`, `scoop`):
///   half steps up to 5, then whole numbers up to 25 (plus 30).
List<double> wheelStepsForUnit(String unit) {
  final u = unit.toLowerCase();
  if (u == 'g' || u == 'grams' || u == 'ml') {
    return const <double>[
      5,
      10,
      15,
      20,
      25,
      30,
      35,
      40,
      45,
      50,
      60,
      70,
      75,
      80,
      90,
      100,
      110,
      120,
      125,
      130,
      140,
      150,
      160,
      175,
      180,
      200,
      225,
      250,
      275,
      300,
      350,
      400,
      450,
      500,
      600,
      700,
      800,
      900,
      1000,
    ];
  }
  if (u.contains('katori') ||
      u.contains('bowl') ||
      u.contains('cup') ||
      u.contains('glass') ||
      u.contains('mug') ||
      u.contains('plate')) {
    return const <double>[
      0.25,
      0.5,
      0.75,
      1,
      1.25,
      1.5,
      1.75,
      2,
      2.5,
      3,
      3.5,
      4,
      4.5,
      5,
      6,
      7,
      8,
      10,
    ];
  }
  return const <double>[
    0.5,
    1,
    1.5,
    2,
    2.5,
    3,
    3.5,
    4,
    4.5,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    14,
    15,
    16,
    18,
    20,
    25,
    30,
  ];
}

/// Horizontal scrollable portion-unit cards with visual icons + a tactile
/// swipe-to-spin number wheel (with `-` / `+` buttons and an optional exact-
/// number dialog so the keyboard never covers the screen uninvited).
class PortionWheelPicker extends StatefulWidget {
  const PortionWheelPicker({
    super.key,
    required this.portions,
    required this.selectedUnit,
    required this.count,
    required this.onUnitChanged,
    required this.onCountChanged,
    this.customSteps,
    this.showGramsSubtitle = true,
    this.maxExactValue = 5000,
  });

  final List<FoodPortion> portions;
  final String selectedUnit;
  final double count;
  final ValueChanged<FoodPortion> onUnitChanged;
  final ValueChanged<double> onCountChanged;
  final List<double>? customSteps;
  final bool showGramsSubtitle;
  final double maxExactValue;

  @override
  State<PortionWheelPicker> createState() => _PortionWheelPickerState();
}

class _PortionWheelPickerState extends State<PortionWheelPicker> {
  late FixedExtentScrollController _wheelCtrl;
  late List<double> _steps;
  bool _programmaticJump = false;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps(widget.selectedUnit, widget.count);
    _wheelCtrl = FixedExtentScrollController(
      initialItem: _indexOf(widget.count),
    );
  }

  @override
  void didUpdateWidget(PortionWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUnit != widget.selectedUnit ||
        oldWidget.count != widget.count) {
      _steps = _buildSteps(widget.selectedUnit, widget.count);
      final targetIdx = _indexOf(widget.count);
      if (_wheelCtrl.hasClients && _wheelCtrl.selectedItem != targetIdx) {
        _programmaticJump = true;
        _wheelCtrl.jumpToItem(targetIdx);
        _programmaticJump = false;
      }
    }
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    super.dispose();
  }

  List<double> _buildSteps(String unit, double current) {
    final base = [...(widget.customSteps ?? wheelStepsForUnit(unit))];
    if (!base.any((v) => (v - current).abs() < 0.001)) {
      base
        ..add(current)
        ..sort();
    }
    return base;
  }

  int _indexOf(double value) {
    var bestIdx = 0;
    var bestDiff = double.infinity;
    for (var i = 0; i < _steps.length; i++) {
      final diff = (_steps[i] - value).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  void _animateToIndex(int index) {
    if (index < 0 || index >= _steps.length) return;
    if (_wheelCtrl.hasClients) {
      unawaited(
        _wheelCtrl.animateToItem(
          index,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      widget.onCountChanged(_steps[index]);
    }
  }

  Future<void> _typeExactDialog() async {
    final ctrl = TextEditingController(text: formatDecimal(widget.count));
    final entered = await showDialog<double>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text('Exact ${widget.selectedUnit}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Amount',
            suffixText: widget.selectedUnit,
          ),
          onSubmitted: (v) {
            final parsed = double.tryParse(v.trim());
            if (parsed != null &&
                parsed > 0 &&
                parsed <= widget.maxExactValue) {
              Navigator.of(dlgCtx).pop(parsed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(ctrl.text.trim());
              if (parsed != null &&
                  parsed > 0 &&
                  parsed <= widget.maxExactValue) {
                Navigator.of(dlgCtx).pop(parsed);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (entered != null && mounted) {
      widget.onCountChanged(entered);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final currentPortion = widget.portions.firstWhere(
      (p) => p.unit == widget.selectedUnit,
      orElse: () => const FoodPortion(unit: 'g', grams: 1),
    );
    final totalGrams = currentPortion.grams * widget.count;
    final currentIdx = _indexOf(widget.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.portions.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in widget.portions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _UnitIconCard(
                      portion: p,
                      selected: p.unit == widget.selectedUnit,
                      onTap: () => widget.onUnitChanged(p),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: portionLabel(widget.count, widget.selectedUnit),
                      style: AuraType.display(26, color: AuraColors.accent),
                    ),
                    if (widget.showGramsSubtitle && widget.selectedUnit != 'g')
                      TextSpan(
                        text: '  (${formatDecimal(totalGrams, places: 0)} g)',
                        style: text.bodyMedium?.copyWith(
                          color: AuraColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _typeExactDialog,
              icon: const Icon(Icons.dialpad, size: 16),
              label: const Text('Exact'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 76,
          decoration: const BoxDecoration(
            color: AuraColors.surfaceStrong,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Decrease amount',
                onPressed: currentIdx > 0
                    ? () => _animateToIndex(currentIdx - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: Container(
                        width: 68,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: AuraColors.accent,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                    Semantics(
                      label:
                          'Swipe left or right to choose ${widget.selectedUnit} amount',
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: ListWheelScrollView.useDelegate(
                          controller: _wheelCtrl,
                          itemExtent: 68,
                          diameterRatio: 2.6,
                          perspective: 0.002,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (idx) {
                            if (_programmaticJump) return;
                            unawaited(HapticFeedback.selectionClick());
                            widget.onCountChanged(_steps[idx]);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _steps.length,
                            builder: (context, index) {
                              if (index < 0 || index >= _steps.length) {
                                return null;
                              }
                              final val = _steps[index];
                              final isSelected = index == currentIdx;
                              return RotatedBox(
                                quarterTurns: 1,
                                child: InkWell(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  onTap: () => _animateToIndex(index),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          _formatWheelNumber(val),
                                          style: isSelected
                                              ? AuraType.display(
                                                  28,
                                                  color: AuraColors.ink,
                                                )
                                              : text.titleMedium?.copyWith(
                                                  color: AuraColors.muted,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Increase amount',
                onPressed: currentIdx < _steps.length - 1
                    ? () => _animateToIndex(currentIdx + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatWheelNumber(double val) {
    if (val >= 1000 && val == val.roundToDouble()) {
      return formatWhole(val.round());
    }
    return formatDecimal(val);
  }
}

/// An amount and its unit, read naturally: "1 katori", "2 pieces",
/// "2 eggs + gravy", "2 omelettes (2 eggs)", "150 g".
String portionLabel(double count, String unit) {
  final number = count >= 1000 && count == count.roundToDouble()
      ? formatWhole(count.round())
      : formatDecimal(count);
  return '$number ${pluralUnit(unit, count)}';
}

/// [unit] for [count] of it. Only the first word changes, so "egg + gravy"
/// becomes "eggs + gravy".
String pluralUnit(String unit, double count) {
  if (count == 1 || unit == 'g' || unit == 'ml') return unit;
  final split = RegExp(r'^(.*?)(\s*[(+].*)?$').firstMatch(unit)!;
  final head = split[1]!;
  final tail = split[2] ?? '';
  return '${_plural(head)}$tail';
}

String _plural(String unit) {
  if (unit.endsWith('glass')) return '${unit}es';
  if (unit.endsWith('sandwich')) return '${unit}es';
  if (unit.endsWith('potato')) return '${unit}es';
  const same = ['medium', 'small', 'large', 'handful'];
  if (unit.endsWith('s') ||
      same.any(unit.startsWith) ||
      unit.contains('katori') ||
      unit.contains('roti') ||
      unit.contains('pav') ||
      unit.contains('dosa') ||
      unit.contains('tbsp') ||
      unit.contains('tsp') ||
      unit.contains('cubes') ||
      unit.contains('chopped')) {
    return unit;
  }
  if (unit == 'half bird') return 'half birds';
  return '${unit}s';
}

class _UnitIconCard extends StatelessWidget {
  const _UnitIconCard({
    required this.portion,
    required this.selected,
    required this.onTap,
  });

  final FoodPortion portion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = portion.unit == 'g' ? 'grams' : portion.unit;
    final sub = portion.unit == 'g'
        ? 'by weight'
        : '${formatDecimal(portion.grams, places: 0)} g';

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AuraColors.paper : AuraColors.surfaceStrong,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconForPortionUnit(portion.unit),
                size: 20,
                color: selected ? AuraColors.ink : AuraColors.muted,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: text.labelLarge?.copyWith(
                      color: selected ? AuraColors.ink : AuraColors.foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    sub,
                    style: text.bodySmall?.copyWith(
                      color: selected ? AuraColors.ink : AuraColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact single-row 3-way Oil & Ghee selector (PRD N9) so all 3 levels fit
/// cleanly side-by-side without wrapping onto two tall rows.
class OilSelectorBar extends StatelessWidget {
  const OilSelectorBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final OilLevel selected;
  final ValueChanged<OilLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const items = <(OilLevel, String, String, IconData)>[
      (
        OilLevel.low,
        'No ghee / low oil',
        'Low / none',
        Icons.water_drop_outlined,
      ),
      (OilLevel.home, 'Home style', 'Home style', Icons.home_outlined),
      (
        OilLevel.extra,
        'Extra ghee / restaurant',
        'Extra ghee',
        Icons.local_fire_department_outlined,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              selected: selected == items[i].$1,
              label: items[i].$2,
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  onChanged(items[i].$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected == items[i].$1
                        ? AuraColors.paper
                        : AuraColors.surfaceStrong,
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].$4,
                        size: 18,
                        color: selected == items[i].$1
                            ? AuraColors.ink
                            : AuraColors.muted,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          items[i].$3,
                          style: text.labelMedium?.copyWith(
                            color: selected == items[i].$1
                                ? AuraColors.ink
                                : AuraColors.foreground,
                            fontWeight: selected == items[i].$1
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
