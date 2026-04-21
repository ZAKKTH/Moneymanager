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
  List<dynamic> categories = [];
  Map<String, int> budget = {};
  String selectedCategory = "未分類";

  DateTime selectedDate = DateTime.now();

  Widget buildSegmentedBar(Map<String, int> categoryTotals) {
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
      const Text("今月の支出内訳",
          style: TextStyle(fontWeight: FontWeight.bold)),

      const SizedBox(height: 8),

      Row(
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

      const SizedBox(height: 8),

      Wrap(
        spacing: 10,
        runSpacing: 5,
        children: visible.map((e) {
          final percent = (e["ratio"] * 100).toStringAsFixed(1);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, color: e["color"]),
              const SizedBox(width: 4),
              Text("${e["name"]} ¥${e["value"]} ($percent%)"),
            ],
          );
        }).toList(),
      ),

      if (hidden.isNotEmpty)
        Text(
          "その他: " + hidden.map((e) => e["name"]).join(", "),
          style: const TextStyle(color: Colors.grey),
        ),
    ],
  );
}
  
  
  Future<void> fetchCategories() async {
  final res = await http.get(
    Uri.parse('http://10.0.2.2:8000/categories'),
  );

  if (res.statusCode == 200) {
  final data = jsonDecode(res.body);

  setState(() {
    categories = data;

    // 🔥 ここ追加
    budget = {
      for (var c in data)
        c["name"]: (c["budget"] ?? 0)
    };
  });
}
}
  String getCurrentMonth() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";

    
  }

  @override
  void initState() {
    super.initState();
    selectedMonth = getCurrentMonth();
    fetchCategories();

    Future.microtask(() async {
      await fetchExpenses();
      await fetchMonthlyTotal(selectedMonth);
    });
  }

  // 🟢 追加
Future<void> addExpense() async {
  final title = titleController.text.trim();
  final amount = int.tryParse(amountController.text);

  // 🔥 Dropdownから取得
  final category = selectedCategory;

  if (title.isEmpty || amount == null) return;

  final response = await http.post(
    Uri.parse('http://10.0.2.2:8000/expense'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "title": title,
      "amount": amount,
      "category": category,
      "date": selectedDate.toIso8601String().split("T")[0],
    }),
  );

  // 🔥 追加後処理（UX重要）
  if (response.statusCode == 200) {
    titleController.clear();
    amountController.clear();

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
  void showCategoryDialog() {
  final nameController = TextEditingController();
  final budgetController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("カテゴリ追加"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "カテゴリ名"),
            ),

            TextField(
              controller: budgetController,
              decoration: const InputDecoration(labelText: "予算"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final budget = int.tryParse(budgetController.text);

              if (name.isEmpty || budget == null) return;

              final res = await http.post(
                Uri.parse('http://10.0.2.2:8000/categories'),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "name": name,
                  "budget": budget,
                }),
              );

              print(res.body);

              Navigator.pop(context);
              await fetchCategories();
            },
            child: const Text("追加"),
          ),
        ],
      );
    },
  );
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

  // 🔥 ① 先にカテゴリ一覧作る
  final allCategories = [
    {"name": "未分類"},
    ...categories
  ];
  // 🔥 ② カテゴリ別合計
  Map<String, int> categoryTotals = {};

  for (var e in expenses) {
    final category = (e["category"] ?? "未分類").toString().trim();
    final amount = (e["amount"] as num).toInt();

    categoryTotals[category] =
        (categoryTotals[category] ?? 0) + amount;
  }
  

  return Scaffold(
      appBar: AppBar(
        title: const Text('家計簿'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              showCategoryDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 上部スクロール
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
                    Row(
                      children: [
                        Text(
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                        ),
                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );

                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text("日付選択"),
                        ),

                        const SizedBox(width: 5),

                        // 🔥 ワンタップ昨日
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedDate =
                                  DateTime.now().subtract(const Duration(days: 1));
                            });
                          },
                          child: const Text("昨日"),
                        ),
                      ],
                    ),
                    categories.isEmpty
                  ? const Text("カテゴリなし")
                  : DropdownButton<String>(
                      value: allCategories.any((c) => c["name"] == selectedCategory)
                            ? selectedCategory
                            : "未分類",
                      isExpanded: true,
                      items: allCategories.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem<String>(
                          value: c["name"],
                          child: Text(c["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
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

                    const Divider(),

                    buildSegmentedBar(categoryTotals), // 🔥ここ追加

                    const Divider(),

                    Text("収入: ¥40000"),
                    Text("固定費: ¥9000"),
                    Text("貯金: ¥3000"),

                    const SizedBox(height: 8),

                    Text(
                      "残り: ¥${40000 - 9000 - 3000 - monthlyTotal}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const Divider(),

                    // 🔥 カテゴリ別表示（完成版）
                    Column(
                      children: [
                        ...categoryTotals.entries.map((entry) {
                          final category = entry.key;
                          final used = entry.value;
                          final limit = budget[category] ?? 0;

                          final remain = limit - used;
                          final percent =
                              limit == 0 ? 0 : (used / limit * 100).toInt();

                          final color = percent >= 100
                              ? Colors.red
                              : percent >= 80
                                  ? Colors.orange
                                  : Colors.green;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text("$used / $limit"),
                                  Text("残り: ¥$remain"),
                                  Text("使用率: $percent%"),

                                  const SizedBox(height: 5),

                                  LinearProgressIndicator(
                                    value: limit == 0 ? 0 : used / limit,
                                    color: color,
                                    backgroundColor: Colors.grey[300],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 下部一覧
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

    subtitle: Builder(
      builder: (_) {
        final category = item["category"] ?? "未分類";

        // 🔥 ここが本質
        final used = categoryTotals[category] ?? 0;

        final limit = budget[category] ?? 0;
        final remain = limit - used;
        final percent = limit == 0 ? 0 : (used / limit * 100).toInt();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${item["date"] ?? ""} / $category"),

            Text("予算: ¥$limit"),

            Text("残り: ¥$remain"),

            Text("使用率: $percent%"),
          ],
        );
      },
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