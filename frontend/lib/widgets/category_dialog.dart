import 'package:flutter/material.dart';
import '../services/api_service.dart';

void showCategoryDialog(BuildContext context, Function refresh) {
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
              decoration: const InputDecoration(
                labelText: "カテゴリ名",
                hintText: "例：食費、交通費 など",
              ),
            ),

            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "予算",
                hintText: "例：5000",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService.addCategory({
                "name": nameController.text,
                "budget": int.parse(budgetController.text),
              });

              Navigator.pop(context);
              refresh();
            },
            child: const Text("追加"),
          ),
        ],
      );
    },
  );
}