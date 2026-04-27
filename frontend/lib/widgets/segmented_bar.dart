import 'package:flutter/material.dart';
class CategoryDetailPage extends StatelessWidget {
  final String category;

  const CategoryDetailPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: Center(
        child: Text("ここに $category の明細表示"),
      ),
    );
  }
}
class SegmentedBar extends StatelessWidget {
  final Map<String, int> categoryTotals;

  const SegmentedBar({super.key, required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.values.fold(0, (a, b) => a + b);

    if (total == 0) {
      return const Text("データなし");
    }

    const threshold = 0.05;

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> visible = [];
    List<Map<String, dynamic>> hidden = [];

    int i = 0;

    for (var e in entries) {
      final ratio = e.value / total;

      final item = {
        "name": e.key,
        "value": e.value,
        "ratio": ratio,
        "color": colors[i++ % colors.length],
      };

      if (ratio >= threshold) {
        visible.add(item);
      } else {
        hidden.add(item);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "今月の支出内訳",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        // 🔥 メインバー
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: visible.map((e) {
              return Expanded(
                flex: (e["ratio"] * 1000).toInt(),
                child: Container(
                  height: 20,
                  color: e["color"],
                ),
              );
            }).toList(),
          ),
        ),
          const SizedBox(height: 12),

        // 🔥 ここが追加：カテゴリ詳細
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            ...visible.map((e) => _legendItem(e, context)),
            if (hidden.isNotEmpty)
              _legendItem({
                "name": "その他",
                "ratio": hidden.fold<double>(
                    0, (sum, e) => sum + (e["ratio"] as double)),
                "color": Colors.grey,
              }, context),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Map<String, dynamic> e, BuildContext context) {
  final percent = (e["ratio"] * 100).toStringAsFixed(1);

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailPage(
            category: e["name"],
          ),
        ),
      );
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: e["color"],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text("${e["name"]} $percent%"),
      ],
    ),
  );
}
}