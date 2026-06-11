import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/transaction.dart' as model;
import '../models/monthly_budget.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'accounting.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        category_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        category_name TEXT    NOT NULL,
        icon_name     TEXT,
        display_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        transaction_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        amount           INTEGER NOT NULL CHECK (amount > 0 AND amount <= 9999999),
        category_id      INTEGER NOT NULL,
        type             TEXT    NOT NULL DEFAULT 'expense',
        note             TEXT,
        transaction_date TEXT    NOT NULL,
        created_at       TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%S', 'now', 'localtime')),
        FOREIGN KEY (category_id) REFERENCES categories (category_id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_settings (
        setting_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        year_month    TEXT    NOT NULL UNIQUE,
        income_amount INTEGER NOT NULL DEFAULT 0,
        budget_amount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    const defaultCategories = [
      {'name': '早餐',  'icon': 'free_breakfast',    'order': 1},
      {'name': '午餐',  'icon': 'lunch_dining',       'order': 2},
      {'name': '晚餐',  'icon': 'dinner_dining',      'order': 3},
      {'name': '交通',  'icon': 'directions_bus',     'order': 4},
      {'name': '娛樂',  'icon': 'sports_esports',     'order': 5},
      {'name': '購物',  'icon': 'shopping_bag',       'order': 6},
      {'name': '薪資',  'icon': 'payments',           'order': 7},
      {'name': '其他',  'icon': 'category_outlined',  'order': 8},
    ];

    for (final c in defaultCategories) {
      await db.insert('categories', {
        'category_name': c['name'],
        'icon_name':     c['icon'],
        'display_order': c['order'],
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE transactions ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'");
      await db.execute('ALTER TABLE transactions ADD COLUMN note TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monthly_budgets (
          budget_id     INTEGER PRIMARY KEY AUTOINCREMENT,
          year_month    TEXT    NOT NULL UNIQUE,
          budget_amount INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // 若 monthly_budgets 存在，遷移資料後刪除
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monthly_settings (
          setting_id    INTEGER PRIMARY KEY AUTOINCREMENT,
          year_month    TEXT    NOT NULL UNIQUE,
          income_amount INTEGER NOT NULL DEFAULT 0,
          budget_amount INTEGER NOT NULL DEFAULT 0
        )
      ''');
      // 把舊表資料搬過來
      await db.execute('''
        INSERT OR IGNORE INTO monthly_settings (year_month, budget_amount)
        SELECT year_month, budget_amount FROM monthly_budgets
      ''');
      // 刪除舊表
      await db.execute('DROP TABLE IF EXISTS monthly_budgets');
    }
  }

  // ── Categories ───────────────────────────────────────────────
  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'display_order ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category c) async {
    final db = await database;
    return db.insert('categories', c.toMap());
  }

  Future<int> updateCategory(Category c) async {
    final db = await database;
    return db.update('categories', c.toMap(),
        where: 'category_id = ?', whereArgs: [c.id]);
  }

  Future<bool> canDeleteCategory(int categoryId) async {
    final db = await database;
    final rows = await db.query('transactions',
        where: 'category_id = ?', whereArgs: [categoryId], limit: 1);
    return rows.isEmpty;
  }

  Future<int> deleteCategory(int categoryId) async {
    final db = await database;
    return db.delete('categories',
        where: 'category_id = ?', whereArgs: [categoryId]);
  }

  Future<void> reorderCategories(List<Category> categories) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < categories.length; i++) {
      batch.update('categories', {'display_order': i},
          where: 'category_id = ?', whereArgs: [categories[i].id]);
    }
    await batch.commit(noResult: true);
  }

  // ── Transactions ─────────────────────────────────────────────
  Future<int> insertTransaction(model.Transaction t) async {
    final db = await database;
    return db.insert('transactions', t.toMap());
  }

  Future<int> updateTransaction(model.Transaction t) async {
    final db = await database;
    return db.update('transactions', t.toMap(),
        where: 'transaction_id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions',
        where: 'transaction_id = ?', whereArgs: [id]);
  }

  Future<List<model.Transaction>> getTransactionsByMonth(
      int year, int month) async {
    final db = await database;
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await db.query(
      'transactions',
      where: 'transaction_date BETWEEN ? AND ?',
      whereArgs: [from, to],
      orderBy: 'transaction_date DESC, transaction_id DESC',
    );
    return rows.map(model.Transaction.fromMap).toList();
  }

  Future<Map<int, int>> getMonthlySummary(int year, int month) async {
    final db = await database;
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await db.rawQuery('''
      SELECT category_id, SUM(amount) AS total
      FROM transactions
      WHERE transaction_date BETWEEN ? AND ?
        AND type = 'expense'
      GROUP BY category_id
    ''', [from, to]);
    return {for (final r in rows) r['category_id'] as int: r['total'] as int};
  }

  // ── Monthly Settings ─────────────────────────────────────────
  Future<MonthlySettings?> getSettings(String yearMonth) async {
    final db = await database;
    final rows = await db.query('monthly_settings',
        where: 'year_month = ?', whereArgs: [yearMonth]);
    if (rows.isEmpty) return null;
    return MonthlySettings.fromMap(rows.first);
  }

  Future<void> upsertSettings(MonthlySettings settings) async {
    final db = await database;
    await db.insert(
      'monthly_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Aliases for backward compatibility
  Future<MonthlySettings?> getBudget(String yearMonth) => getSettings(yearMonth);

  Future<void> upsertBudget(MonthlySettings settings) => upsertSettings(settings);
}
