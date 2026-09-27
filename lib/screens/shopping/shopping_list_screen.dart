import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/shopping_item.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final item = ShoppingItem(id: _uuid.v4(), name: name, quantity: _qtyCtrl.text.trim().isEmpty ? null : _qtyCtrl.text.trim(), createdAt: DateTime.now());
    await HiveService.shopping.put(item.id, item);
    _nameCtrl.clear();
    _qtyCtrl.clear();
  }

  Future<void> _clearChecked() async {
    final checked = HiveService.shopping.values.where((i) => i.checked).toList();
    for (final i in checked) {
      await i.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(tr(context, 'শপিং তালিকা', 'Shopping List')),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [scheme.surfaceContainerLow, scheme.surface])),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(scheme: scheme),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: HiveService.shopping.listenable(),
                  builder: (context, Box<ShoppingItem> box, _) {
                    final items = box.values.toList()
                      ..sort((a, b) {
                        if (a.checked != b.checked) return a.checked ? 1 : -1;
                        return b.createdAt.compareTo(a.createdAt);
                      });
                    if (items.isEmpty) {
                      return EmptyState(icon: Icons.shopping_cart_outlined, title: tr(context, 'তালিকা খালি', 'List is empty'), message: tr(context, 'নিচে লিখে তালিকায় যোগ করুন।', 'Type below to add items to your list.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return StaggeredFadeIn(
                          index: i,
                          child: Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.md)),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            onDismissed: (_) => item.delete(),
                            child: PressableCard(
                              color: scheme.surface,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: CheckboxListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide.none),
                                value: item.checked,
                                activeColor: AppColors.shopping,
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: (v) {
                                  item.checked = v ?? false;
                                  item.save();
                                },
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    decoration: item.checked ? TextDecoration.lineThrough : null,
                                    color: item.checked ? scheme.onSurfaceVariant : scheme.onSurface,
                                  ),
                                ),
                                subtitle: item.quantity != null ? Text(item.quantity!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)) : null,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required ColorScheme scheme}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(context, 'যা কিনতে হবে তা ট্র্যাক করুন।', 'Track what you need to buy.'),
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                ),
              ),
              AnimatedBuilder(
                animation: HiveService.shopping.listenable(),
                builder: (context, _) {
                  final all = HiveService.shopping.values;
                  final checked = all.where((i) => i.checked).length;
                  return IconButton(
                    icon: Icon(Icons.cleaning_services_outlined, color: scheme.onSurfaceVariant),
                    tooltip: tr(context, 'চেক করা মুছুন', 'Clear checked'),
                    onPressed: checked == 0 ? null : _clearChecked,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: tr(context, 'যেমন: চাল', 'e.g. Rice'),
                      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _add(),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                Container(width: 1, height: 28, color: scheme.outlineVariant),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyCtrl,
                    style: TextStyle(color: scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: tr(context, 'পরিমাণ', 'Qty'),
                      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: AppColors.shopping, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
