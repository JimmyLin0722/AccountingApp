import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/icon_map.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('管理類別'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => _showAddDialog(context, provider),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.categories.length,
        onReorderItem: (oldIndex, newIndex) {
          final cats = List.of(provider.categories);
          final item = cats.removeAt(oldIndex);
          cats.insert(newIndex, item);
          context.read<TransactionProvider>().reorderCategories(cats);
        },
        itemBuilder: (context, i) {
          final cat = provider.categories[i];
          return ListTile(
            key: ValueKey(cat.id),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.expense.withValues(alpha: 0.2)),
              ),
              child: Icon(iconFromName(cat.iconName), color: AppColors.expense, size: 20),
            ),
            title: Text(cat.name, style: const TextStyle(color: AppColors.textPrimary)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.drag_handle, color: AppColors.textGrey),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.expense.withValues(alpha: 0.8), size: 20),
                onPressed: () async {
                  final err = await context.read<TransactionProvider>().deleteCategoryById(cat.id!);
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err)),
                    );
                  }
                },
              ),
            ]),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, TransactionProvider provider) {
    final nameCtrl = TextEditingController();
    String selectedIcon = 'category_outlined';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('新增類別', style: TextStyle(color: AppColors.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: '類別名稱'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('選擇圖示', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: GridView.count(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: kIconMap.entries.map((e) {
                    final isSelected = e.key == selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = e.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.expense.withValues(alpha: 0.18)
                              : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: AppColors.expense, width: 1.5)
                              : Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: Icon(e.value,
                            size: 24,
                            color: isSelected ? AppColors.expense : AppColors.textGrey),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: AppColors.textGrey)),
            ),
            GestureDetector(
              onTap: () async {
                final err = await provider.addCategory(nameCtrl.text, selectedIcon);
                if (err != null && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                } else if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 10)],
                ),
                child: const Text('新增', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
