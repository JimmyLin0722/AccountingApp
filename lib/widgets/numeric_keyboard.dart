import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class NumericKeyboard extends StatelessWidget {
  const NumericKeyboard({super.key});

  static const _keys = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    ['DEL', '0', 'OK'],
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final row = index ~/ 3;
        final col = index % 3;
        final key = _keys[row][col];
        return _KeyButton(label: key);
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  const _KeyButton({required this.label});

  @override
  Widget build(BuildContext context) {
    final isOk = label == 'OK';
    final isDel = label == 'DEL';

    return Material(
      color: isOk
          ? const Color(0xFF6C63FF)
          : isDel
              ? Colors.grey.shade200
              : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final provider = context.read<TransactionProvider>();
          if (isOk) {
            final error = await provider.saveTransaction();
            if (error != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
              );
            }
          } else if (isDel) {
            provider.deleteDigit();
          } else {
            provider.appendDigit(label);
          }
        },
        child: Center(
          child: isDel
              ? const Icon(Icons.backspace_outlined, size: 20)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isOk ? Colors.white : Colors.black87,
                  ),
                ),
        ),
      ),
    );
  }
}
