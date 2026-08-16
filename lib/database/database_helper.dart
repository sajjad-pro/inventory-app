import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inventory_item.dart';

/// طبقة إدارة قاعدة بيانات SQLite المحلية على الجهاز
/// تستخدم نمط Singleton لضمان وجود اتصال واحد فقط بقاعدة البيانات
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            received REAL NOT NULL DEFAULT 0,
            issued REAL NOT NULL DEFAULT 0,
            delivered REAL NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  /// إضافة مادة جديدة، تُرجع المعرف الجديد
  Future<int> insertItem(InventoryItem item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    return await db.insert('items', map);
  }

  /// جلب كل المواد مرتبة حسب تاريخ الإضافة (id)
  Future<List<InventoryItem>> getAllItems() async {
    final db = await database;
    final result = await db.query('items', orderBy: 'id ASC');
    return result.map((row) => InventoryItem.fromMap(row)).toList();
  }

  /// تعديل مادة موجودة
  Future<int> updateItem(InventoryItem item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// حذف مادة عبر معرفها
  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
