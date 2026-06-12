import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../theme/app_theme.dart';
import '../utils/icon_map.dart';
import 'category_management_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final model.Transaction? editing;
  const AddTransactionScreen({super.key, this.editing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _noteCtrl = TextEditingController();

  static const _weekdays = ['', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _noteCtrl.text = widget.editing!.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isEditing = widget.editing != null;
    final now = provider.selectedDate;
    final weekday = _weekdays[now.weekday];
    final today = DateTime.now();
    final isToday = now.year == today.year && now.month == today.month && now.day == today.day;
    final dateLabel = '${isToday ? '今日 ' : ''}${DateFormat('yyyy/MM/dd').format(now)} $weekday';
    final selectedCat = provider.selectedCategoryId != null
        ? provider.getCategoryById(provider.selectedCategoryId!)
        : null;
    final fmt = NumberFormat('#,###');
    final isIncome = provider.type == 'income';
    final activeColor = isIncome ? AppColors.income : AppColors.expense;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          _TypeTab(
            label: '支出',
            isSelected: !isIncome,
            color: AppColors.expense,
            onTap: () => context.read<TransactionProvider>().setType('expense'),
          ),
          const SizedBox(width: 8),
          _TypeTab(
            label: '收入',
            isSelected: isIncome,
            color: AppColors.income,
            onTap: () => context.read<TransactionProvider>().setType('income'),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textGrey),
            tooltip: '管理類別',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.9,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: provider.categories.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _CategoryCell(
                    icon: Icons.add,
                    label: '新增分類',
                    isAdd: true,
                    isSelected: false,
                    activeColor: activeColor,
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
                    },
                  );
                }
                final cat = provider.categories[i - 1];
                return _CategoryCell(
                  icon: iconFromName(cat.iconName),
                  label: cat.name,
                  isSelected: cat.id == provider.selectedCategoryId,
                  activeColor: activeColor,
                  onTap: () => context.read<TransactionProvider>().selectCategory(cat.id!),
                );
              },
            ),
          ),
          // 底部輸入面板
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceHigh.withValues(alpha: 0.8))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 金額顯示
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TWD',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 11, letterSpacing: 2)),
                      const SizedBox(height: 2),
                      Text(
                        '\$${fmt.format(int.tryParse(provider.displayAmount) ?? 0)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                          shadows: [Shadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 16)],
                        ),
                      ),
                    ],
                  ),
                ),
                // 備註欄位
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _noteCtrl,
                    onChanged: (v) => context.read<TransactionProvider>().setNote(v),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '輸入備註（選填）',
                      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      enabledBorder: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: activeColor.withValues(alpha: 0.6), width: 1),
                      ),
                    ),
                    maxLines: 1,
                  ),
                ),
                // 快捷 Chip（顯示已選類別）
                if (selectedCat != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(selectedCat.name,
                          style: TextStyle(color: activeColor, fontSize: 12)),
                    ),
                  ),
                // 日期列
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.surfaceHigh),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left, size: 24, color: AppColors.textGrey),
                        onPressed: () => context.read<TransactionProvider>().previousDay(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            locale: const Locale('zh', 'TW'),
                          );
                          if (picked != null && context.mounted) {
                            context.read<TransactionProvider>().setDate(picked);
                          }
                        },
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppColors.textGrey),
                          const SizedBox(width: 6),
                          Text(dateLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              )),
                        ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right, size: 24, color: AppColors.textGrey),
                        onPressed: () => context.read<TransactionProvider>().nextDay(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
                // 鍵盤
                _NumericKeyboard(isEditing: isEditing, editing: widget.editing),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 支出/收入切換 Tab ─────────────────────────────────────────
class _TypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _TypeTab({
    required this.label, required this.isSelected,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
            shadows: isSelected
                ? [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                : null,
          ),
        ),
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isAdd;
  final Color activeColor;
  final VoidCallback onTap;
  const _CategoryCell({
    required this.icon, required this.label, required this.isSelected,
    required this.activeColor, required this.onTap, this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.18)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: activeColor, width: 1.5)
                : isAdd
                    ? Border.all(color: AppColors.accent.withValues(alpha: 0.5))
                    : Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Icon(
            icon,
            color: isSelected ? activeColor : (isAdd ? AppColors.accent : AppColors.textGrey),
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? activeColor : AppColors.textGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _NumericKeyboard extends StatelessWidget {
  final bool isEditing;
  final model.Transaction? editing;
  const _NumericKeyboard({this.isEditing = false, this.editing});

  static const double _keyH = 52.0;
  static const double _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(children: [
            _numRow(context, ['7', '8', '9', 'AC']),
            const SizedBox(height: _gap),
            _numRow(context, ['4', '5', '6', '←']),
            const SizedBox(height: _gap),
            _numRow(context, ['1', '2', '3', '']),
            const SizedBox(height: _gap),
            _numRow(context, ['00', '0', '.', '']),
          ]),
        ),
        const SizedBox(width: _gap),
        SizedBox(
          width: 64,
          child: _OkButton(height: _keyH * 2 + _gap, isEditing: isEditing, editing: editing),
        ),
      ]),
    );
  }

  Widget _numRow(BuildContext context, List<String> keys) {
    return Row(children: [
      ...keys.take(3).map((k) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _KeyBtn(label: k),
            ),
          )),
      const SizedBox(width: 4),
      SizedBox(
        width: 52,
        child: keys[3].isEmpty ? const SizedBox(height: _keyH) : _KeyBtn(label: keys[3], isSpecial: true),
      ),
    ]);
  }
}

class _OkButton extends StatelessWidget {
  final double height;
  final bool isEditing;
  final model.Transaction? editing;
  const _OkButton({required this.height, this.isEditing = false, this.editing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final provider = context.read<TransactionProvider>();
        final err = await provider.saveTransaction(editing: editing);
        if (err != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        } else if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(isEditing ? '更新' : 'OK',
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: Colors.white, letterSpacing: 1.5,
            )),
      ),
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String label;
  final bool isSpecial;
  const _KeyBtn({required this.label, this.isSpecial = false});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox(height: 52);
    final isAc = label == 'AC';
    final isBack = label == '←';
    final isSpecialKey = isAc || isBack;

    return GestureDetector(
      onTap: () {
        final p = context.read<TransactionProvider>();
        if (isBack) {
          p.deleteDigit();
        } else if (isAc) {
          p.clearAmount();
        } else if (label == '.') {
          // MVP 不支援小數，忽略
        } else {
          p.appendDigit(label);
        }
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: isBack
            ? const Icon(Icons.backspace_outlined, color: AppColors.income, size: 20)
            : Text(
                label,
                style: TextStyle(
                  fontSize: isAc ? 15 : 18,
                  fontWeight: FontWeight.w600,
                  color: isSpecialKey ? AppColors.income : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}
