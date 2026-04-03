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
            ),
          ],
        ),
      ),
    );
  }
}