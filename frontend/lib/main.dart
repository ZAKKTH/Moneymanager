import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '家計簿アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ExpensePage(),
    );
  }
}

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final categoryController = TextEditingController();
  

  List<dynamic> expenses = [];
  int monthlyTotal = 0;
  String selectedMonth = "";

  String getCurrentMonth() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    selectedMonth = getCurrentMonth();

    Future.microtask(() async {
      await fetchExpenses();
      await fetchMonthlyTotal(selectedMonth);
    });
  }

  // 🟢 追加
Future<void> addExpense() async {
  final title = titleController.text.trim();
  final amount = int.tryParse(amountController.text);
  final category = categoryController.text.trim();

  if (title.isEmpty || amount == null) return;

  final response = await http.post(
    Uri.parse('http://10.0.2.2:8000/expense'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "title": title,
      "amount": amount,
      "category": category.isEmpty ? "未分類" : category,
    }),
  );

  if (response.statusCode == 200) {
    titleController.clear();
    amountController.clear();
    categoryController.clear();

    await fetchExpenses();
    await fetchMonthlyTotal(selectedMonth);
  } else {
    debugPrint("追加失敗: ${response.body}");
  }
}

  // 🟢 一覧取得
  Future<void> fetchExpenses() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/expenses'),
    );

    if (response.statusCode == 200) {
      setState(() {
        expenses = jsonDecode(response.body);
      });
    } else {
      debugPrint("取得失敗: ${response.body}");
    }
  }

  // 🟢 月合計
  Future<void> fetchMonthlyTotal(String month) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/expenses/month-total/$month'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        monthlyTotal = data["total"] ?? 0;
      });
    } else {
      debugPrint("合計取得失敗: ${response.body}");
    }
  }
  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家計簿')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'タイトル'),
                    ),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: '金額'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'カテゴリ（自由入力）'),
                    ),
                    ElevatedButton(
                      onPressed: addExpense,
                      child: const Text('追加'),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ← 月ボタンそのまま
                      ],
                    ),

                    Text("今月の合計: ¥$monthlyTotal"),
                  ],
                ),
              ),
            ),

            // 👇 一覧は別で固定
            Expanded(
              child: expenses.isEmpty
                  ? const Center(child: Text("データなし"))
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final item = expenses[index];

                        return Card(
                          child: ListTile(
                            title: Text(item["title"] ?? "タイトルなし"),
                            subtitle: Text(
                              "${item["date"] ?? ""} / ${item["category"] ?? "未分類"}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "¥${item["amount"]}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final response = await http.delete(
                                      Uri.parse(
                                        'http://10.0.2.2:8000/expense/${item["id"]}',
                                      ),
                                    );

                                    if (response.statusCode == 200) {
                                      await fetchExpenses();
                                      await fetchMonthlyTotal(selectedMonth);
                                    }
                                  },
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
      ),
    );
  }
}