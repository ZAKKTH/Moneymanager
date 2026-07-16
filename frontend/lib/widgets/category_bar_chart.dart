import 'package:flutter/material.dart';

class CategoryBarChart extends StatelessWidget {
  final Map<String, int> categoryTotals;

  const CategoryBarChart({
    super.key,
    required this.categoryTotals,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const Text("データなし");
    }

    final maxValue =
        categoryTotals.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: categoryTotals.entries.map((e) {
        final ratio = maxValue == 0 ? 0.0 : e.value / maxValue;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏷 カテゴリ名 + 金額
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text("¥${e.value}"),
                ],
              ),

              const SizedBox(height: 4),

              // 📊 バー
              LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}