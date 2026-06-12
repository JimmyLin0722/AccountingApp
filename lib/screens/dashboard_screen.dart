import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../theme/app_theme.dart';
import '../utils/icon_map.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _chartColors = [
    Color(0xFFFF4772), Color(0xFF00F5D4), Color(0xFF7000FF),
    Color(0xFF00C4FF), Color(0xFFFFD700), Color(0xFFFF6B6B),
    Color(0xFF4DFFB4), Color(0xFFFF9F43),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final viewMonth = provider.viewMonth;
    final monthLabel = DateFormat('yyyy年M月').format(viewMonth);
    final grouped = _groupByDate(provider.transactions);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const Icon(Icons.menu, color: AppColors.textGrey),
        title: GestureDetector(
          onTap: () => _showMonthPicker(context, provider, viewMonth),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('全部',
                  style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(monthLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textGrey),
          ]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textGrey),
            tooltip: '本月設定',
            onPressed: () => _showMonthlySettingsDialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textGrey),
            onPressed: () {},
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) {
            context.read<TransactionProvider>().goToNextMonth();
          } else if (details.primaryVelocity! > 300) {
            context.read<TransactionProvider>().goToPreviousMonth();
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 預算警示 Banner
              if (provider.budgetStatus == 2)
                _BudgetBanner(
                  message: '⚠️ 本月支出已達預算 80%，請注意消費',
                  bgColor: const Color(0xFF2A1F00),
                  textColor: const Color(0xFFFFB800),
                  accentColor: const Color(0xFFFFB800),
                ),
              if (provider.budgetStatus == 3)
                _BudgetBanner(
                  message: '🚨 本月支出已超出預算！',
                  bgColor: const Color(0xFF2A0011),
                  textColor: AppColors.expense,
                  accentColor: AppColors.expense,
                ),
              // 統計橫幅
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SummaryTile(label: '總支出', amount: provider.totalExpense, color: AppColors.expense),
                    GestureDetector(
                      onTap: () => _showMonthlySettingsDialog(context, provider),
                      child: _SummaryTile(label: '總收入', amount: provider.totalIncome, color: AppColors.income, alignRight: true),
                    ),
                  ],
                ),
              ),
              // 甜甜圈圖
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: provider.monthlySummary.isEmpty
                    ? const SizedBox(
                        height: 200,
                        child: Center(child: Text('本月尚無支出', style: TextStyle(color: AppColors.textGrey))))
                    : _DonutChart(
                        summary: provider.monthlySummary,
                        balance: provider.balance,
                        colors: _chartColors,
                        provider: provider,
                      ),
              ),
              const SizedBox(height: 4),
              // 交易清單
              if (grouped.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('本月尚無記帳紀錄', style: TextStyle(color: AppColors.textGrey)),
                )
              else
                ...grouped.entries.map((e) =>
                    _DateGroup(date: e.key, txns: e.value, provider: provider)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          onPressed: () {
            context.read<TransactionProvider>().resetInput();
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          },
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Map<String, List<model.Transaction>> _groupByDate(List<model.Transaction> txns) {
    final map = <String, List<model.Transaction>>{};
    for (final t in txns) {
      map.putIfAbsent(t.transactionDate, () => []).add(t);
    }
    return map;
  }

  void _showMonthPicker(BuildContext context, TransactionProvider provider, DateTime current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MonthPickerSheet(current: current, provider: provider),
    );
  }

  void _showMonthlySettingsDialog(BuildContext context, TransactionProvider provider) {
    final incomeCtrl = TextEditingController(
      text: provider.currentSettings?.incomeAmount != null && provider.currentSettings!.incomeAmount > 0
          ? provider.currentSettings!.incomeAmount.toString()
          : '',
    );
    final budgetCtrl = TextEditingController(
      text: provider.currentSettings?.budgetAmount != null && provider.currentSettings!.budgetAmount > 0
          ? provider.currentSettings!.budgetAmount.toString()
          : '',
    );
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('本月設定',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 24),
                  _GlassTextField(
                    controller: incomeCtrl,
                    label: '本月固定收入（NT\$）',
                    icon: Icons.trending_up,
                    accentColor: AppColors.income,
                  ),
                  const SizedBox(height: 20),
                  _GlassTextField(
                    controller: budgetCtrl,
                    label: '本月支出預算（NT\$）',
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: AppColors.expense,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消', style: TextStyle(color: AppColors.textGrey)),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                          final income = int.tryParse(incomeCtrl.text);
                          final budget = int.tryParse(budgetCtrl.text);
                          if (income != null && income >= 0) await provider.saveIncome(income);
                          if (budget != null && budget >= 0) await provider.saveBudget(budget);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 12),
                            ],
                          ),
                          child: const Text('儲存',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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

// ── 玻璃擬態輸入欄位 ──────────────────────────────────────────
class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  const _GlassTextField({
    required this.controller, required this.label,
    required this.icon, required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            hintText: '0',
            hintStyle: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold,
              color: AppColors.textGrey.withValues(alpha: 0.4),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 月份選擇器 ────────────────────────────────────────────────
class _MonthPickerSheet extends StatefulWidget {
  final DateTime current;
  final TransactionProvider provider;
  const _MonthPickerSheet({required this.current, required this.provider});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
    _month = widget.current.month;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textGrey),
            onPressed: () => setState(() {
              if (_month == 1) { _year--; _month = 12; } else { _month--; }
            }),
          ),
          Text('$_year 年',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textGrey),
            onPressed: () => setState(() {
              if (_month == 12) { _year++; _month = 1; } else { _month++; }
            }),
          ),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          childAspectRatio: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(12, (i) {
            final m = i + 1;
            final isSelected = m == _month;
            return GestureDetector(
              onTap: () {
                widget.provider.setViewMonth(DateTime(_year, m));
                Navigator.pop(context);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 8)]
                      : null,
                ),
                child: Text('$m月',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textGrey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ── 預算警示 Banner ───────────────────────────────────────────
class _BudgetBanner extends StatelessWidget {
  final String message;
  final Color bgColor;
  final Color textColor;
  final Color accentColor;
  const _BudgetBanner({
    required this.message, required this.bgColor,
    required this.textColor, required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(width: 3, height: 16, color: accentColor, margin: const EdgeInsets.only(right: 10)),
        Text(message, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── 統計磚 ────────────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final bool alignRight;
  const _SummaryTile({required this.label, required this.amount, required this.color, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 4),
        Text('\$${fmt.format(amount)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
            )),
      ],
    );
  }
}

// ── 甜甜圈圖 ──────────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final Map<int, int> summary;
  final int balance;
  final List<Color> colors;
  final TransactionProvider provider;
  const _DonutChart({required this.summary, required this.balance, required this.colors, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final isNeg = balance < 0;
    final balanceColor = isNeg ? AppColors.expense : AppColors.income;
    final sections = summary.entries.toList().asMap().entries.map((e) {
      return PieChartSectionData(
        value: e.value.value.toDouble(),
        color: colors[e.key % colors.length],
        title: '',
        radius: 20,
      );
    }).toList();

    return SizedBox(
      height: 240,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                balanceColor.withValues(alpha: 0.07),
                Colors.transparent,
              ],
              radius: 0.7,
            ),
          ),
        ),
        PieChart(PieChartData(
          sections: sections,
          centerSpaceRadius: 84,
          sectionsSpace: 3,
          startDegreeOffset: -90,
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('總結餘', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 2),
          Text(
            '${isNeg ? '-' : ''}\$${fmt.format(balance.abs())}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: balanceColor,
              shadows: [Shadow(color: balanceColor.withValues(alpha: 0.6), blurRadius: 16)],
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── 日期群組 ──────────────────────────────────────────────────
class _DateGroup extends StatelessWidget {
  final String date;
  final List<model.Transaction> txns;
  final TransactionProvider provider;
  const _DateGroup({required this.date, required this.txns, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final dayExpense = txns.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);
    final dt = DateTime.tryParse(date);
    const weekdays = ['', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final weekday = dt != null ? weekdays[dt.weekday] : '';
    final displayDate = dt != null ? DateFormat('yyyy/MM/dd').format(dt) : date;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$displayDate $weekday',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textGrey)),
            Text('\$-${fmt.format(dayExpense)}',
                style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
        ...txns.map((t) => _TxnTile(t: t, provider: provider)),
      ]),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final model.Transaction t;
  final TransactionProvider provider;
  const _TxnTile({required this.t, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final cat = provider.getCategoryById(t.categoryId);
    final isIncome = t.type == 'income';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final amountText = isIncome ? '+\$${fmt.format(t.amount)}' : '-\$${fmt.format(t.amount)}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: amountColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: amountColor.withValues(alpha: 0.2)),
        ),
        child: Icon(iconFromName(cat?.iconName), size: 18, color: amountColor),
      ),
      title: Text(cat?.name ?? '未知類別',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      subtitle: t.note != null && t.note!.isNotEmpty
          ? Text(t.note!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey))
          : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(amountText,
            style: TextStyle(
              fontSize: 15,
              color: amountColor,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: amountColor.withValues(alpha: 0.4), blurRadius: 8)],
            )),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textGrey),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('編輯')),
            PopupMenuItem(value: 'delete',
                child: Text('刪除', style: TextStyle(color: AppColors.expense))),
          ],
          onSelected: (action) async {
            if (action == 'delete') {
              await context.read<TransactionProvider>().deleteTransaction(t.id!);
            } else if (action == 'edit') {
              context.read<TransactionProvider>().loadForEdit(t);
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(editing: t),
                ));
              }
            }
          },
        ),
      ]),
    );
  }
}
