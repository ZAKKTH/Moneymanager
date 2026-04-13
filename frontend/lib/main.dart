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
<<<<<<< HEAD

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
    fetchExpenses();
    fetchMonthlyTotal(selectedMonth);
  }

  // 🟢 追加
  Future<void> addExpense() async {
    final title = titleController.text;
    final amount = int.tryParse(amountController.text);

    if (title.isEmpty || amount == null) return;

    await http.post(
      Uri.parse('http://10.0.2.2:8000/expense'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title,
        "amount": amount,
      }),
    );

    titleController.clear();
    amountController.clear();

    fetchExpenses();
    fetchMonthlyTotal(selectedMonth);
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
    }
=======

  List<dynamic> expenses = [];

Future<void> addExpense() async {
  final title = titleController.text;
  final amountText = amountController.text;

  // 入力チェック
  if (title.isEmpty || amountText.isEmpty) {
    return;
  }

  final amount = int.tryParse(amountText);
  if (amount == null) {
    return;
  }

  try {
    await http.post(
      Uri.parse('http://10.0.2.2:8000/expense'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title,
        "amount": amount,
      }),
    );

    titleController.clear();
    amountController.clear();

    fetchExpenses(); // 更新
  } catch (e) {
    print("Error: $e");
  }
}

  Future<void> fetchExpenses() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/expenses'),
    );

    setState(() {
      expenses = jsonDecode(response.body);
    });
>>>>>>> 521af660526286380d893c888f6f8e1caaa1298b
  }

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家計簿')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
<<<<<<< HEAD
            // 入力
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
=======
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: '金額'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: addExpense,
              child: const Text('追加'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(expenses[index]["title"]),
                    trailing: Text("¥${expenses[index]["amount"]}"),
                  );
                },
              ),
>>>>>>> 521af660526286380d893c888f6f8e1caaa1298b
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: '金額'),
              keyboardType: TextInputType.number,
            ),

            ElevatedButton(
              onPressed: addExpense,
              child: const Text('追加'),
            ),

            // 月切り替え
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    final parts = selectedMonth.split("-");
                    int y = int.parse(parts[0]);
                    int m = int.parse(parts[1]);

                    m--;
                    if (m == 0) {
                      m = 12;
                      y--;
                    }

                    selectedMonth =
                        "$y-${m.toString().padLeft(2, '0')}";
                    fetchMonthlyTotal(selectedMonth);
                    setState(() {});
                  },
                ),
                Text(selectedMonth),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    final parts = selectedMonth.split("-");
                    int y = int.parse(parts[0]);
                    int m = int.parse(parts[1]);

                    m++;
                    if (m == 13) {
                      m = 1;
                      y++;
                    }

                    selectedMonth =
                        "$y-${m.toString().padLeft(2, '0')}";
                    fetchMonthlyTotal(selectedMonth);
                    setState(() {});
                  },
                ),
              ],
            ),

            Text("今月の合計: ¥$monthlyTotal"),

            // 一覧
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
                subtitle: Text(item["date"] ?? "日付なし"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "¥${item["amount"]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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
                        } else {
                          print("削除失敗: ${response.body}");
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