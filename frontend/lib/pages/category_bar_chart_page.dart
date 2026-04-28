import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/category_bar_chart.dart';

class CategoryBarChartPage extends StatefulWidget {
  const CategoryBarChartPage({super.key});

  @override
  State<CategoryBarChartPage> createState() =>
      _CategoryBarChartPageState();
}

class _CategoryBarChartPageState
    extends State<CategoryBarChartPage> {
  List expenses = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    expenses = await ApiService.fetchExpenses();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> categoryTotals = {};

    for (var e in expenses) {
      final category = e["category"] ?? "未分類";
      final amount = (e["amount"] as num).toInt();

      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("カテゴリ分析"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: expenses.isEmpty
            ? const Center(child: Text("データなし"))
            : CategoryBarChart(categoryTotals: categoryTotals),
      ),
    );
  }
}