import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final txns = provider.transactions;

    if (txns.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('本月尚無記帳紀錄', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: txns.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = txns[i];
        final cat = provider.getCategoryById(t.categoryId);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
            child: Text(cat?.name.substring(0, 1) ?? '?',
                style: const TextStyle(color: Color(0xFF6C63FF))),
          ),
          title: Text(cat?.name ?? '未知類別'),
          subtitle: Text(t.transactionDate),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NT\$ ${NumberFormat('#,###').format(t.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () => context.read<TransactionProvider>().deleteTransaction(t.id!),
              ),
            ],
          ),
        );
      },
    );
  }
}
