import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/segmented_bar.dart';
import '../widgets/category_dialog.dart';



class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
final titleController = TextEditingController();
final amountController = TextEditingController();

Future<void> addExpense() async {
  final title = titleController.text.trim();
  final amount = int.tryParse(amountController.text);

  if (title.isEmpty || amount == null) return;

  await ApiService.addExpense({
    "title": title,
    "amount": amount,
    "category": selectedCategory,
    "date": DateTime.now().toString().split(" ")[0],
  });

  titleController.clear();
  amountController.clear();

  await load();
}
  String selectedCategory = "未分類";
  List expenses = [];
  List categories = [];
  int monthlyTotal = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    expenses = await ApiService.fetchExpenses();
    categories = await ApiService.fetchCategories();
    monthlyTotal = await ApiService.fetchMonthlyTotal("2026-04");

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> categoryTotals = {};

    for (var e in expenses) {
      final category = e["category"] ?? "未分類";
      final amount = e["amount"] as int;

      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("家計簿"),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              showCategoryDialog(context, load);
            },
          )
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "タイトル"),
                ),

                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: "金額"),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: categories.any((c) => c["name"] == selectedCategory)
                      ? selectedCategory
                      : "未分類",
                  items: [
                    const DropdownMenuItem(
                      value: "未分類",
                      child: Text("未分類"),
                    ),
                    ...categories.map<DropdownMenuItem<String>>((c) {
                      return DropdownMenuItem(
                        value: c["name"],
                        child: Text(c["name"]),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  decoration: const InputDecoration(labelText: "カテゴリ"),
                ),

                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: addExpense,
                  child: const Text("追加"),
                ),
              ],
            ),
          ),
          Text("合計: ¥$monthlyTotal"),
          SegmentedBar(categoryTotals: categoryTotals),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (_, i) {
                final item = expenses[i];

                final category = item["category"] ?? "未分類";
                // final amount = item["amount"] as int; #dead code !
                final title = item["title"] ?? "";

                final date = item["date"] ?? "";

                final categoryData = categories.firstWhere(
                  (c) => c["name"] == category,
                  orElse: () => {"budget": 0},
                );

                final budget = categoryData["budget"] ?? 0;

                // カテゴリ合計
                final categorySpent = expenses
                    .where((e) => e["category"] == category)
                    .fold<int>(0, (sum, e) => sum + (e["amount"] as int));

                final remaining = budget - categorySpent;

                final double safeUsage = (budget == 0)
                ? 0.0
                : (categorySpent / budget).clamp(0.0, 1.0).toDouble();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🧠 名前
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // 📅 日時 / カテゴリ
                        Text("$date / $category"),

                        const SizedBox(height: 8),

                        // 💰 予算 & 残高
                        Text("予算: ¥$budget"),
                        Text("残高: ¥$remaining"),

                        const SizedBox(height: 6),

                        // 📊 使用率
                        LinearProgressIndicator(
                          value: safeUsage,
                        ),
                        const SizedBox(height: 4),
                        Text("使用率: ${(safeUsage * 100).toStringAsFixed(1)}%"),

                        const SizedBox(height: 8),

                        // 🗑 削除ボタン
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await ApiService.deleteExpense(item["id"]);
                              await load();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ), 
    );
  }
}