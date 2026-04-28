import 'package:flutter/material.dart';
import '../services/api_service.dart';

void showCategoryDialog(BuildContext context, Function refresh) {
  final nameController = TextEditingController();
  final budgetController = TextEditingController();

  List categories = [];

  Future<void> loadCategories(StateSetter setModalState) async {
    categories = await ApiService.fetchCategories();
    setModalState(() {});
  }

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          if (categories.isEmpty) {
            loadCategories(setModalState);
          }

          return AlertDialog(
            title: const Text("カテゴリ管理"),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =========================
                  // 🟢 追加フォーム
                  // =========================
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "カテゴリ名",
                    ),
                  ),

                  TextField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "予算",
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () async {
                      await ApiService.addCategory({
                        "name": nameController.text,
                        "budget": int.tryParse(budgetController.text) ?? 0,
                      });

                      nameController.clear();
                      budgetController.clear();

                      await loadCategories(setModalState);
                      refresh();
                    },
                    child: const Text("追加"),
                  ),

                  const Divider(),

                  // =========================
                  // 🔥 カテゴリ一覧 + 削除
                  // =========================
                  ...categories.map((c) {
                    return ListTile(
                      title: Text(c["name"]),
                      subtitle: Text("予算: ¥${c["budget"] ?? 0}"),

                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDeleteConfirm(
                            context,
                            c["id"],
                            c["name"],
                            () async {
                              await loadCategories(setModalState);
                              refresh();
                            },
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

//
// =========================
// 🔥 二段階削除
// =========================
//

void showDeleteConfirm(
  BuildContext context,
  int id,
  String name,
  Function refresh,
) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("カテゴリ削除"),
        content: Text("「$name」を削除しますか？"),
        actions: [
          TextButton(
            child: const Text("キャンセル"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("削除"),
            onPressed: () {
              Navigator.pop(context);
              showFinalDeleteConfirm(context, id, name, refresh);
            },
          ),
        ],
      );
    },
  );
}

void showFinalDeleteConfirm(
  BuildContext context,
  int id,
  String name,
  Function refresh,
) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("⚠ 最終確認"),
        content: Text("「$name」を完全に削除します。\nこの操作は戻せません。"),
        actions: [
          TextButton(
            child: const Text("やめる"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("完全削除"),
            onPressed: () async {
              await ApiService.deleteCategory(id);

              Navigator.pop(context);
              refresh();
            },
          ),
        ],
      );
    },
  );
}