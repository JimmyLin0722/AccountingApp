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
        title: const Text('管理類別'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Icon(iconFromName(cat.iconName), color: AppColors.primary, size: 20),
            ),
            title: Text(cat.name),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.drag_handle, color: AppColors.textGrey),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () async {
                  final err = await context.read<TransactionProvider>().deleteCategoryById(cat.id!);
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
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
          title: const Text('新增類別'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
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
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                        ),
                        child: Icon(e.value,
                            size: 24,
                            color: isSelected ? AppColors.primary : AppColors.textDark),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final err = await provider.addCategory(nameCtrl.text, selectedIcon);
                if (err != null && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
                  );
                } else if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('新增', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
