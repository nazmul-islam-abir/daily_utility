import 'package:flutter/material.dart';

import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Unit Converter — design #10. Four tabs (Length / Weight / Temp / Volume),
/// "From" value + unit dropdown, animated swap button, "To" result + unit dropdown.
class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> with SingleTickerProviderStateMixin {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            title: Text(tr(context, 'একক রূপান্তর', 'Unit Converter'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          body: Column(
            children: [
              _TabBar(
                index: _tab,
                onSelect: (i) => setState(() => _tab = i),
                tabs: const [
                  _TabDef('দৈর্ঘ্য', 'Length', Icons.straighten),
                  _TabDef('ওজন', 'Weight', Icons.fitness_center),
                  _TabDef('তাপমাত্রা', 'Temp', Icons.thermostat),
                  _TabDef('আয়তন', 'Volume', Icons.local_drink_outlined),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppAnimations.medium,
                  switchInCurve: AppAnimations.curve,
                  child: _buildTab(_tab),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return const KeyedSubtree(key: ValueKey('length'), child: _ConverterPanel(category: _Category.length));
      case 1:
        return const KeyedSubtree(key: ValueKey('weight'), child: _ConverterPanel(category: _Category.weight));
      case 2:
        return const KeyedSubtree(key: ValueKey('temp'), child: _ConverterPanel(category: _Category.temp));
      default:
        return const KeyedSubtree(key: ValueKey('volume'), child: _ConverterPanel(category: _Category.volume));
    }
  }
}

class _TabDef {
  final String bn;
  final String en;
  final IconData icon;
  const _TabDef(this.bn, this.en, this.icon);
}

class _TabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final List<_TabDef> tabs;
  const _TabBar({required this.index, required this.onSelect, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = i == index;
          final t = tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                curve: AppAnimations.curve,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: sel ? AppColors.surface : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: sel ? AppShadows.soft(AppColors.converter) : []),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 18, color: sel ? AppColors.converter : AppColors.textMuted),
                    const SizedBox(height: 4),
                    Text(tr(context, t.bn, t.en), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: sel ? AppColors.text : AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum _Category { length, weight, temp, volume }

class _Unit {
  final String bn;
  final String en;
  final String symbol;
  const _Unit(this.bn, this.en, this.symbol);
}

class _ConverterPanel extends StatefulWidget {
  final _Category category;
  const _ConverterPanel({required this.category});

  @override
  State<_ConverterPanel> createState() => _ConverterPanelState();
}

class _ConverterPanelState extends State<_ConverterPanel> {
  late final TextEditingController _value;
  late int _from;
  late int _to;
  double _swapRotation = 0;

  static const _length = [_Unit('মিটার', 'Meter', 'm'), _Unit('কিলোমিটার', 'Kilometer', 'km'), _Unit('সেন্টিমিটার', 'Centimeter', 'cm'), _Unit('মিলিমিটার', 'Millimeter', 'mm'), _Unit('ইঞ্চি', 'Inch', 'in'), _Unit('ফুট', 'Foot', 'ft'), _Unit('গজ', 'Yard', 'yd'), _Unit('মাইল', 'Mile', 'mi')];
  static const _weight = [_Unit('কিলোগ্রাম', 'Kilogram', 'kg'), _Unit('গ্রাম', 'Gram', 'g'), _Unit('মিলিগ্রাম', 'Milligram', 'mg'), _Unit('পাউন্ড', 'Pound', 'lb'), _Unit('আউন্স', 'Ounce', 'oz'), _Unit('টন', 'Ton', 't')];
  static const _temp = [_Unit('সেলসিয়াস', 'Celsius', '°C'), _Unit('ফারেনহাইট', 'Fahrenheit', '°F'), _Unit('কেলভিন', 'Kelvin', 'K')];
  static const _volume = [_Unit('লিটার', 'Liter', 'L'), _Unit('মিলিলিটার', 'Milliliter', 'mL'), _Unit('গ্যালন (US)', 'Gallon (US)', 'gal'), _Unit('কোয়ার্ট', 'Quart', 'qt'), _Unit('পাইন্ট', 'Pint', 'pt'), _Unit('কাপ', 'Cup', 'cup')];

  List<_Unit> get _units {
    switch (widget.category) {
      case _Category.length: return _length;
      case _Category.weight: return _weight;
      case _Category.temp: return _temp;
      case _Category.volume: return _volume;
    }
  }

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(text: '1');
    _from = 0;
    _to = widget.category == _Category.temp ? 1 : (_units.length > 1 ? 1 : 0);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
      _swapRotation += 1;
    });
  }

  double _convert(double v) {
    switch (widget.category) {
      case _Category.length:
        return _convertLength(v, _from, _to);
      case _Category.weight:
        return _convertWeight(v, _from, _to);
      case _Category.temp:
        return _convertTemp(v, _from, _to);
      case _Category.volume:
        return _convertVolume(v, _from, _to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = double.tryParse(_value.text) ?? 0;
    final result = _convert(v);
    final units = _units;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _ValueCard(
          title: tr(context, 'থেকে', 'FROM'),
          units: units,
          selectedIndex: _from,
          controller: _value,
          onUnitChange: (i) => setState(() => _from = i),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _swap,
            child: AnimatedRotation(
              duration: AppAnimations.medium,
              curve: AppAnimations.curve,
              turns: _swapRotation,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.converter.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: const Icon(Icons.swap_vert, color: AppColors.converter),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ValueCard(
          title: tr(context, 'এ রূপান্তর', 'TO'),
          units: units,
          selectedIndex: _to,
          displayValue: _formatResult(result),
          onUnitChange: (i) => setState(() => _to = i),
          readOnly: true,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(tr(context, 'ফলাফল স্বয়ংক্রিয়ভাবে হিসাব হয়।', 'Result updates instantly as you type.'), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
          ]),
        ),
      ],
    );
  }

  String _formatResult(double v) {
    if (v == 0) return '0';
    if (v.abs() < 0.0001 || v.abs() >= 1e6) return v.toStringAsExponential(4);
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}

class _ValueCard extends StatelessWidget {
  final String title;
  final List<_Unit> units;
  final int selectedIndex;
  final TextEditingController? controller;
  final String? displayValue;
  final ValueChanged<int> onUnitChange;
  final bool readOnly;
  const _ValueCard({required this.title, required this.units, required this.selectedIndex, required this.onUnitChange, this.controller, this.displayValue, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final unit = units[selectedIndex];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.cardGradient(AppColors.converter)), borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiniSectionLabel(title),
          const SizedBox(height: 12),
          if (readOnly)
            Text(displayValue ?? '0', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.text))
          else
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.text),
              decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero, isDense: true),
            ),
          const SizedBox(height: 8),
          _UnitDropdown(units: units, selectedIndex: selectedIndex, onSelect: onUnitChange),
          const SizedBox(height: 8),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.converter.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppRadius.sm)), child: Text(unit.symbol, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.converter))),
          ]),
        ],
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  final List<_Unit> units;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _UnitDropdown({required this.units, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onSelect,
      itemBuilder: (ctx) => [
        for (int i = 0; i < units.length; i++)
          PopupMenuItem(
            value: i,
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: i == selectedIndex ? AppColors.converter : AppColors.line, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(tr(context, units[i].bn, units[i].en), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('(${units[i].symbol})', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ),
      ],
      child: Row(children: [
        Expanded(child: Text(tr(context, units[selectedIndex].bn, units[selectedIndex].en), style: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w700))),
        const Icon(Icons.expand_more, color: AppColors.textMuted),
      ]),
    );
  }
}

double _convertLength(double v, int from, int to) {
  const toMeter = [1.0, 1000.0, 0.01, 0.001, 0.0254, 0.3048, 0.9144, 1609.344];
  final m = v * toMeter[from];
  return m / toMeter[to];
}

double _convertWeight(double v, int from, int to) {
  const toKg = [1.0, 0.001, 0.000001, 0.45359237, 0.0283495231, 1000.0];
  final kg = v * toKg[from];
  return kg / toKg[to];
}

double _convertTemp(double v, int from, int to) {
  double c;
  switch (from) {
    case 0: c = v; break;
    case 1: c = (v - 32) * 5 / 9; break;
    case 2: c = v - 273.15; break;
    default: c = v;
  }
  switch (to) {
    case 0: return c;
    case 1: return c * 9 / 5 + 32;
    case 2: return c + 273.15;
    default: return c;
  }
}

double _convertVolume(double v, int from, int to) {
  const toLiter = [1.0, 0.001, 3.785411784, 0.946352946, 0.473176473, 0.2365882365];
  final l = v * toLiter[from];
  return l / toLiter[to];
}
