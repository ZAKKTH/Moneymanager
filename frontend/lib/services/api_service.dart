import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const baseUrl = 'http://10.0.2.2:8000';

  static Future<List<dynamic>> fetchExpenses() async {
    final res = await http.get(Uri.parse('$baseUrl/expenses'));
    return jsonDecode(res.body);
  }

  static Future<int> fetchMonthlyTotal(String month) async {
    final res = await http.get(Uri.parse('$baseUrl/expenses/month-total/$month'));
    return jsonDecode(res.body)["total"] ?? 0;
  }

  static Future<void> addExpense(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('$baseUrl/expense'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
  }

  static Future<void> deleteExpense(int id) async {
    await http.delete(Uri.parse('$baseUrl/expense/$id'));
  }

  static Future<List<dynamic>> fetchCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories'));
    return jsonDecode(res.body);
  }

  static Future<void> addCategory(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
  }
}