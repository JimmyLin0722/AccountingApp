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
    Color(0xFFF4A438), Color(0xFF5BC8C0), Color(0xFFF06060),
    Color(0xFF4A90D9), Color(0xFFA29BFE), Color(0xFF55EFC4),
    Color(0xFFFFD93D), Color(0xFFFF6B6B),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: AppColors.textDark),
        title: GestureDetector(
          onTap: () => _showMonthPicker(context, provider, viewMonth),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('全部',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(monthLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: '本月設定',
            onPressed: () => _showMonthlySettingsDialog(context, provider),
          ),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
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
                  color: const Color(0xFFFFF3CD),
                  textColor: const Color(0xFF856404),
                ),
              if (provider.budgetStatus == 3)
                _BudgetBanner(
                  message: '🚨 本月支出已超出預算！',
                  color: const Color(0xFFFDE2E2),
                  textColor: const Color(0xFFB00020),
                ),
              // 統計橫幅
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: provider.monthlySummary.isEmpty
                    ? const SizedBox(height: 200,
                        child: Center(child: Text('本月尚無支出', style: TextStyle(color: AppColors.textGrey))))
                    : _DonutChart(
                        summary: provider.monthlySummary,
                        balance: provider.balance,
                        colors: _chartColors,
                        provider: provider,
                      ),
              ),
              const SizedBox(height: 8),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.okButton,
        foregroundColor: Colors.white,
        onPressed: () {
          context.read<TransactionProvider>().resetInput();
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
        },
        child: const Icon(Icons.add, size: 28),
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
      builder: (ctx) => AlertDialog(
        title: const Text('本月設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: incomeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '本月固定收入（NT\$）',
                prefixIcon: Icon(Icons.trending_up),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '本月支出預算（NT\$）',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final income = int.tryParse(incomeCtrl.text);
              final budget = int.tryParse(budgetCtrl.text);
              if (income != null && income >= 0) {
                await provider.saveIncome(income);
              }
              if (budget != null && budget >= 0) {
                await provider.saveBudget(budget);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('儲存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              if (_month == 1) { _year--; _month = 12; } else { _month--; }
            }),
          ),
          Text('$_year 年', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              if (_month == 12) { _year++; _month = 1; } else { _month++; }
            }),
          ),
        ]),
        const SizedBox(height: 8),
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
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$m月',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
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
  final Color color;
  final Color textColor;
  const _BudgetBanner({required this.message, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(message, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
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
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (!alignRight) ...[
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const Icon(Icons.arrow_right, size: 16, color: AppColors.textGrey),
          ] else ...[
            const Icon(Icons.arrow_right, size: 16, color: AppColors.textGrey),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ],
        ]),
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: 2))),
          child: Text('\$${fmt.format(amount)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ),
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
    final sections = summary.entries.toList().asMap().entries.map((e) {
      return PieChartSectionData(
        value: e.value.value.toDouble(),
        color: colors[e.key % colors.length],
        title: '',
        radius: 52,
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(sections: sections, centerSpaceRadius: 72, sectionsSpace: 2)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.textGrey),
          const SizedBox(height: 2),
          const Text('總結餘', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          Text(
            '${isNeg ? '-' : ''}\$${fmt.format(balance.abs())}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isNeg ? AppColors.okButton : const Color(0xFF2E7D32),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$displayDate $weekday',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('\$-${fmt.format(dayExpense)}',
                style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
        const Divider(height: 1),
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
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: (isIncome ? AppColors.income : AppColors.primary).withValues(alpha: 0.15),
        child: Icon(
          iconFromName(cat?.iconName),
          size: 18,
          color: isIncome ? AppColors.income : AppColors.primary,
        ),
      ),
      title: Text(cat?.name ?? '未知類別',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: t.note != null && t.note!.isNotEmpty
          ? Text(t.note!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey))
          : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(amountText,
            style: TextStyle(fontSize: 15, color: amountColor, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textGrey),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('編輯')),
            const PopupMenuItem(value: 'delete', child: Text('刪除', style: TextStyle(color: Colors.red))),
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
