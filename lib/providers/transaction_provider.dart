import 'package:flutter/foundation.dart' hide Category;
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/transaction.dart' as model;
import '../models/monthly_budget.dart';

class TransactionProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  List<model.Transaction> _transactions = [];
  List<Category> _categories = [];
  Map<int, int> _monthlySummary = {};
  MonthlySettings? _currentSettings;

  // 輸入狀態
  int? _selectedCategoryId;
  String _amount = '';
  String _note = '';
  String _type = 'expense'; // 'expense' | 'income'
  late DateTime _selectedDate;

  // 選定的檢視月份
  late DateTime _viewMonth;

  List<model.Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  Map<int, int> get monthlySummary => _monthlySummary;
  MonthlySettings? get currentSettings => _currentSettings;

  // Alias for backward compatibility
  MonthlySettings? get currentBudget => _currentSettings;

  int? get selectedCategoryId => _selectedCategoryId;
  String get amount => _amount;
  String get note => _note;
  String get type => _type;
  DateTime get selectedDate => _selectedDate;
  DateTime get viewMonth => _viewMonth;

  int get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);

  int get totalIncome =>
      (_currentSettings?.incomeAmount ?? 0) +
      _transactions.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);

  int get balance => totalIncome - totalExpense;

  // 預算警示：0=無預算, 1=正常, 2=80%警告, 3=超出
  int get budgetStatus {
    final settings = _currentSettings;
    if (settings == null || settings.budgetAmount <= 0) return 0;
    final ratio = totalExpense / settings.budgetAmount;
    if (ratio >= 1.0) return 3;
    if (ratio >= 0.8) return 2;
    return 1;
  }

  TransactionProvider() {
    _selectedDate = DateTime.now();
    _viewMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _load();
  }

  TransactionProvider.test() {
    _selectedDate = DateTime.now();
    _viewMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  Future<void> _load() async {
    _categories = await _db.getCategories();
    await _refreshTransactions();
  }

  Future<void> _refreshTransactions() async {
    final ym = '${_viewMonth.year}-${_viewMonth.month.toString().padLeft(2, '0')}';
    _transactions = await _db.getTransactionsByMonth(_viewMonth.year, _viewMonth.month);
    _monthlySummary = await _db.getMonthlySummary(_viewMonth.year, _viewMonth.month);
    _currentSettings = await _db.getSettings(ym);
    notifyListeners();
  }

  // ── 月份切換 ──────────────────────────────────────────────────
  void goToPreviousMonth() {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    _refreshTransactions();
  }

  void goToNextMonth() {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    _refreshTransactions();
  }

  void setViewMonth(DateTime month) {
    _viewMonth = DateTime(month.year, month.month);
    _refreshTransactions();
  }

  // ── 輸入操作 ──────────────────────────────────────────────────
  void selectCategory(int id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void setType(String t) {
    _type = t;
    notifyListeners();
  }

  void setNote(String n) {
    _note = n;
    notifyListeners();
  }

  void appendDigit(String digit) {
    if (_amount.length >= 7) return;
    if (_amount.isEmpty && digit == '0') return;
    _amount += digit;
    notifyListeners();
  }

  void deleteDigit() {
    if (_amount.isEmpty) return;
    _amount = _amount.substring(0, _amount.length - 1);
    notifyListeners();
  }

  void clearAmount() {
    _amount = '';
    notifyListeners();
  }

  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
  }

  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // ── 儲存 ──────────────────────────────────────────────────────
  Future<String?> saveTransaction({model.Transaction? editing}) async {
    final parsed = int.tryParse(_amount);
    if (parsed == null || parsed <= 0) return '請輸入金額';
    if (_selectedCategoryId == null) return '請選擇消費類別';

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    if (editing != null) {
      final updated = editing.copyWith(
        amount: parsed,
        categoryId: _selectedCategoryId,
        type: _type,
        note: _note.isEmpty ? null : _note,
        transactionDate: dateStr,
      );
      await _db.updateTransaction(updated);
    } else {
      final t = model.Transaction(
        amount: parsed,
        categoryId: _selectedCategoryId!,
        type: _type,
        note: _note.isEmpty ? null : _note,
        transactionDate: dateStr,
      );
      await _db.insertTransaction(t);
    }

    _amount = '';
    _note = '';
    await _refreshTransactions();
    return null;
  }

  void loadForEdit(model.Transaction t) {
    _amount = t.amount.toString();
    _selectedCategoryId = t.categoryId;
    _type = t.type;
    _note = t.note ?? '';
    _selectedDate = DateTime.tryParse(t.transactionDate) ?? DateTime.now();
    notifyListeners();
  }

  void resetInput() {
    _amount = '';
    _note = '';
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await _refreshTransactions();
  }

  // ── 類別管理 ─────────────────────────────────────────────────
  Future<String?> addCategory(String name, String iconName) async {
    if (name.trim().isEmpty) return '請輸入類別名稱';
    final order = _categories.isEmpty ? 0 : _categories.last.displayOrder + 1;
    await _db.insertCategory(Category(name: name.trim(), iconName: iconName, displayOrder: order));
    _categories = await _db.getCategories();
    notifyListeners();
    return null;
  }

  Future<String?> deleteCategoryById(int id) async {
    final canDelete = await _db.canDeleteCategory(id);
    if (!canDelete) return '此類別已有關聯記帳紀錄，無法刪除';
    await _db.deleteCategory(id);
    _categories = await _db.getCategories();
    notifyListeners();
    return null;
  }

  Future<void> reorderCategories(List<Category> newOrder) async {
    await _db.reorderCategories(newOrder);
    _categories = await _db.getCategories();
    notifyListeners();
  }

  // ── 月收入 & 預算 ─────────────────────────────────────────────
  Future<void> saveIncome(int amount) async {
    final ym = '${_viewMonth.year}-${_viewMonth.month.toString().padLeft(2, '0')}';
    final existing = _currentSettings;
    await _db.upsertSettings(MonthlySettings(
      id: existing?.id,
      yearMonth: ym,
      incomeAmount: amount,
      budgetAmount: existing?.budgetAmount ?? 0,
    ));
    await _refreshTransactions();
  }

  Future<void> saveBudget(int amount) async {
    final ym = '${_viewMonth.year}-${_viewMonth.month.toString().padLeft(2, '0')}';
    final existing = _currentSettings;
    await _db.upsertSettings(MonthlySettings(
      id: existing?.id,
      yearMonth: ym,
      incomeAmount: existing?.incomeAmount ?? 0,
      budgetAmount: amount,
    ));
    await _refreshTransactions();
  }

  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id != null && c.id == id);
    } catch (_) {
      return null;
    }
  }

  String get displayAmount => _amount.isEmpty ? '0' : _amount;
}
