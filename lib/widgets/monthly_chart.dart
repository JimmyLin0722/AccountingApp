import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';

class MonthlyChart extends StatelessWidget {
  const MonthlyChart({super.key});

  static const _colors = [
    Color(0xFF6C63FF), Color(0xFFFF6584), Color(0xFF43C6AC),
    Color(0xFFFFBE76), Color(0xFFA29BFE), Color(0xFFFF7675),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final summary = provider.monthlySummary;

    if (summary.isEmpty) return const SizedBox.shrink();

    final total = summary.values.fold(0, (a, b) => a + b);
    final sections = summary.entries.toList().asMap().entries.map((e) {
      final idx = e.key;
      final amount = e.value.value;
      final percent = amount / total * 100;
      return PieChartSectionData(
        value: amount.toDouble(),
        color: _colors[idx % _colors.length],
        title: '${percent.toStringAsFixed(0)}%',
        radius: 55,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: percent >= 8 ? null : const SizedBox.shrink(),
      );
    }).toList();

    final legends = summary.entries.toList().asMap().entries.map((e) {
      final idx = e.key;
      final cat = provider.getCategoryById(e.value.key);
      return _LegendItem(color: _colors[idx % _colors.length], label: cat?.name ?? '?');
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 36)),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 4, children: legends),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}
