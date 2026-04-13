import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer_model.dart';
import '../models/labour_model.dart';
import '../models/farm_data_model.dart';
import '../models/dead_chicks_model.dart';
import '../models/medicine_model.dart';
import '../models/feed_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('poultry_farm.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 5, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE farm_data ADD COLUMN breed TEXT DEFAULT ""');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE customers ADD COLUMN numberOfChicks INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE dead_chicks (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          count INTEGER,
          notes TEXT,
          createdAt TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE medicines (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          name TEXT,
          cost REAL,
          notes TEXT,
          createdAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE feeds (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          type TEXT,
          quantity REAL,
          cost REAL,
          notes TEXT,
          createdAt TEXT
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        symbolNumber TEXT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        imagePath TEXT,
        address TEXT,
        mobileNo TEXT,
        numberOfChicks INTEGER,
        chickenWeight REAL,
        chickenRate REAL,
        average REAL,
        depositAmount REAL,
        remainingAmount REAL,
        paymentMode TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE labours (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mobileNo TEXT,
        address TEXT,
        joiningDate TEXT,
        dailyWage REAL,
        totalDaysWorked INTEGER,
        totalPaid REAL,
        remainingPayment REAL,
        role TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE farm_data (
        id TEXT PRIMARY KEY,
        breed TEXT,
        date TEXT NOT NULL,
        numberOfChicks INTEGER,
        chicksAmount REAL,
        medicineAmount REAL,
        grainsAmount REAL,
        otherExpenses REAL,
        notes TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE dead_chicks (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        count INTEGER,
        notes TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        name TEXT,
        cost REAL,
        notes TEXT,
        createdAt TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE feeds (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        type TEXT,
        quantity REAL,
        cost REAL,
        notes TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        referenceId TEXT,
        createdAt TEXT
      )
    ''');
  }

  // ─── CUSTOMER CRUD ───────────────────────────────────────────────────────────

  Future<String> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap());
    // Record income
    await insertExpense({
      'id': customer.id + '_income',
      'category': 'income',
      'amount': customer.totalAmount,
      'description': 'Sales to ${customer.name}',
      'date': customer.date,
      'referenceId': customer.id,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return customer.id;
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'createdAt DESC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
    await db.delete('expenses', where: 'referenceId = ?', whereArgs: [customer.id]);
    if (customer.totalAmount > 0) {
      await insertExpense({
        'id': customer.id + '_income',
        'category': 'income',
        'amount': customer.totalAmount,
        'description': 'Sales to ${customer.name}',
        'date': customer.date,
        'referenceId': customer.id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await db.delete('expenses', where: 'referenceId = ?', whereArgs: [id]);
  }

  // ─── LABOUR CRUD ─────────────────────────────────────────────────────────────

  Future<String> insertLabour(Labour labour) async {
    final db = await database;
    await db.insert('labours', labour.toMap());
    return labour.id;
  }

  Future<List<Labour>> getLabours() async {
    final db = await database;
    final maps = await db.query('labours', orderBy: 'createdAt DESC');
    return maps.map((m) => Labour.fromMap(m)).toList();
  }

  Future<void> updateLabour(Labour labour) async {
    final db = await database;
    await db.update('labours', labour.toMap(), where: 'id = ?', whereArgs: [labour.id]);
  }

  Future<void> deleteLabour(String id) async {
    final db = await database;
    await db.delete('labours', where: 'id = ?', whereArgs: [id]);
  }

  // ─── FARM DATA CRUD ──────────────────────────────────────────────────────────

  Future<String> insertFarmData(FarmData data) async {
    final db = await database;
    await db.insert('farm_data', data.toMap());
    double totalExpense = data.chicksAmount +
        data.medicineAmount +
        data.grainsAmount +
        data.otherExpenses;
    if (totalExpense > 0) {
      await insertExpense({
        'id': data.id + '_expense',
        'category': 'expense',
        'amount': totalExpense,
        'description': 'Farm expenses - Chicks/Medicine/Grains',
        'date': data.date,
        'referenceId': data.id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    return data.id;
  }

  Future<List<FarmData>> getFarmData() async {
    final db = await database;
    final maps = await db.query('farm_data', orderBy: 'date DESC');
    return maps.map((m) => FarmData.fromMap(m)).toList();
  }

  Future<void> updateFarmData(FarmData data) async {
    final db = await database;
    await db.update('farm_data', data.toMap(), where: 'id = ?', whereArgs: [data.id]);
    
    double totalExpense = data.chicksAmount +
        data.medicineAmount +
        data.grainsAmount +
        data.otherExpenses;
        
    if (totalExpense > 0) {
      await insertExpense({
        'id': data.id + '_expense',
        'category': 'expense',
        'amount': totalExpense,
        'description': 'Farm expenses - Chicks/Medicine/Grains',
        'date': data.date,
        'referenceId': data.id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } else {
      await db.delete('expenses', where: 'id = ?', whereArgs: [data.id + '_expense']);
    }
  }

  Future<void> deleteFarmData(String id) async {
    final db = await database;
    await db.delete('farm_data', where: 'id = ?', whereArgs: [id]);
    await db.delete('expenses', where: 'referenceId = ?', whereArgs: [id]);
  }

  // ─── DEAD CHICKS CRUD ────────────────────────────────────────────────────────

  Future<String> insertDeadChicks(DeadChicks data) async {
    final db = await database;
    await db.insert('dead_chicks', data.toMap());
    return data.id;
  }

  Future<List<DeadChicks>> getDeadChicks() async {
    final db = await database;
    final maps = await db.query('dead_chicks', orderBy: 'date DESC');
    return maps.map((m) => DeadChicks.fromMap(m)).toList();
  }

  Future<void> updateDeadChicks(DeadChicks data) async {
    final db = await database;
    await db.update('dead_chicks', data.toMap(), where: 'id = ?', whereArgs: [data.id]);
  }

  Future<void> deleteDeadChicks(String id) async {
    final db = await database;
    await db.delete('dead_chicks', where: 'id = ?', whereArgs: [id]);
  }

  // ─── MEDICINE CRUD ───────────────────────────────────────────────────────────

  Future<String> insertMedicine(Medicine data) async {
    final db = await database;
    await db.insert('medicines', data.toMap());
    if (data.cost > 0) {
      await insertExpense({
        'id': data.id + '_expense',
        'category': 'expense',
        'amount': data.cost,
        'description': 'Medicine: ${data.name}',
        'date': data.date,
        'referenceId': data.id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    return data.id;
  }

  Future<List<Medicine>> getMedicines() async {
    final db = await database;
    final maps = await db.query('medicines', orderBy: 'date DESC');
    return maps.map((m) => Medicine.fromMap(m)).toList();
  }

  Future<void> updateMedicine(Medicine data) async {
    final db = await database;
    await db.update('medicines', data.toMap(), where: 'id = ?', whereArgs: [data.id]);
    if (data.cost > 0) {
      await insertExpense({
        'id': data.id + '_expense',
        'category': 'expense',
        'amount': data.cost,
        'description': 'Medicine: ${data.name}',
        'date': data.date,
        'referenceId': data.id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } else {
      await db.delete('expenses', where: 'id = ?', whereArgs: [data.id + '_expense']);
    }
  }

  Future<void> deleteMedicine(String id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
    await db.delete('expenses', where: 'referenceId = ?', whereArgs: [id]);
  }

  // ─── FEED CRUD ───────────────────────────────────────────────────────────────

  Future<String> insertFeed(Feed data) async {
    final db = await database;
    await db.insert('feeds', data.toMap());
    if (data.cost > 0) {
      await insertExpense({
        'id': data.id + '_expense',
        'category': 'expense',
        'amount': data.cost,
        'description': 'Feed: ${data.type}',
        'date': data.date,
        'referenceId': data.id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    return data.id;
  }

  Future<List<Feed>> getFeeds() async {
    final db = await database;
    final maps = await db.query('feeds', orderBy: 'date DESC');
    return maps.map((m) => Feed.fromMap(m)).toList();
  }

  Future<void> updateFeed(Feed data) async {
    final db = await database;
    await db.update('feeds', data.toMap(), where: 'id = ?', whereArgs: [data.id]);
    if (data.cost > 0) {
      await insertExpense({
        'id': data.id + '_expense',
        'category': 'expense',
        'amount': data.cost,
        'description': 'Feed: ${data.type}',
        'date': data.date,
        'referenceId': data.id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } else {
      await db.delete('expenses', where: 'id = ?', whereArgs: [data.id + '_expense']);
    }
  }

  Future<void> deleteFeed(String id) async {
    final db = await database;
    await db.delete('feeds', where: 'id = ?', whereArgs: [id]);
    await db.delete('expenses', where: 'referenceId = ?', whereArgs: [id]);
  }

  // ─── EXPENSES ────────────────────────────────────────────────────────────────

  Future<void> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    await db.insert('expenses', expense, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, double>> getSummary() async {
    final db = await database;
    final incomeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE category = 'income'"
    );
    final expenseResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE category = 'expense'"
    );

    // Labour expense
    final labourResult = await db.rawQuery(
      "SELECT COALESCE(SUM(totalPaid), 0) as total FROM labours"
    );

    // Medicine expense
    final medicineResult = await db.rawQuery(
      "SELECT COALESCE(SUM(cost), 0) as total FROM medicines"
    );

    // Feed expense
    final feedResult = await db.rawQuery(
      "SELECT COALESCE(SUM(cost), 0) as total FROM feeds"
    );
    
    // Total chicks added
    final chicksAddedResult = await db.rawQuery(
      "SELECT COALESCE(SUM(numberOfChicks), 0) as total FROM farm_data"
    );
    
    // Total dead chicks
    final deadChicksResult = await db.rawQuery(
      "SELECT COALESCE(SUM(count), 0) as total FROM dead_chicks"
    );

    // Total sold chicks (from customers)
    final soldChicksResult = await db.rawQuery(
      "SELECT COALESCE(SUM(numberOfChicks), 0) as total FROM customers"
    );

    // Average weight from customers
    final totalWeightResult = await db.rawQuery(
      "SELECT COALESCE(SUM(chickenWeight), 0) as total FROM customers"
    );

    final farmDataResult = await db.rawQuery(
      "SELECT COALESCE(SUM(medicineAmount), 0) as med, COALESCE(SUM(grainsAmount), 0) as feed, COALESCE(SUM(chicksAmount), 0) as chicks FROM farm_data"
    );

    double income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0;
    double expense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0;
    double labourCost = (labourResult.first['total'] as num?)?.toDouble() ?? 0;
    
    double medicineCost = (medicineResult.first['total'] as num?)?.toDouble() ?? 0;
    double feedCost = (feedResult.first['total'] as num?)?.toDouble() ?? 0;
    double farmMedicine = (farmDataResult.first['med'] as num?)?.toDouble() ?? 0;
    double farmFeed = (farmDataResult.first['feed'] as num?)?.toDouble() ?? 0;
    double chicksAmount = (farmDataResult.first['chicks'] as num?)?.toDouble() ?? 0;
    
    double chicksAdded = (chicksAddedResult.first['total'] as num?)?.toDouble() ?? 0;
    double deadChicks = (deadChicksResult.first['total'] as num?)?.toDouble() ?? 0;
    double soldChicks = (soldChicksResult.first['total'] as num?)?.toDouble() ?? 0;
    double totalWeight = (totalWeightResult.first['total'] as num?)?.toDouble() ?? 0;

    double chicksInFarm = chicksAdded - deadChicks - soldChicks;
    double averageSoldWeight = soldChicks > 0 ? totalWeight / soldChicks : 0.0;

    return {
      'income': income,
      'expense': expense + labourCost,
      'profit': income - expense - labourCost,
      'labourCost': labourCost,
      'medicineCost': medicineCost + farmMedicine,
      'feedCost': feedCost + farmFeed,
      'chicksAmount': chicksAmount,
      'chicksInFarm': chicksInFarm >= 0 ? chicksInFarm : 0,
      'totalChicksAdded': chicksAdded,
      'totalDeadChicks': deadChicks,
      'totalSoldChicks': soldChicks,
      'averageSoldWeight': averageSoldWeight,
    };
  }
}
