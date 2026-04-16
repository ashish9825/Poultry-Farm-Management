import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
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
    return await openDatabase(path, version: 8, onCreate: _createDB, onUpgrade: _onUpgrade);
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
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE medicines ADD COLUMN paymentMode TEXT DEFAULT "Cash"');
      await db.execute('ALTER TABLE feeds ADD COLUMN paymentMode TEXT DEFAULT "Cash"');
      await db.execute('ALTER TABLE labours ADD COLUMN paymentMode TEXT DEFAULT "Cash"');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE farm_data ADD COLUMN paymentMode TEXT DEFAULT "Cash"');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE customer_payments (
          id TEXT PRIMARY KEY,
          customerId TEXT NOT NULL,
          customerName TEXT NOT NULL,
          amount REAL NOT NULL,
          paymentMode TEXT NOT NULL,
          date TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE labour_payments (
          id TEXT PRIMARY KEY,
          labourId TEXT NOT NULL,
          labourName TEXT NOT NULL,
          amount REAL NOT NULL,
          paymentMode TEXT NOT NULL,
          date TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      // Migrate existing customers
      final customers = await db.query('customers');
      for (final c in customers) {
        final amount = (c['depositAmount'] as num?)?.toDouble() ?? 0;
        if (amount > 0) {
          await db.insert('customer_payments', {
            'id': const Uuid().v4(),
            'customerId': c['id'],
            'customerName': c['name'],
            'amount': amount,
            'paymentMode': c['paymentMode'] ?? 'Cash',
            'date': c['date'] ?? DateTime.now().toIso8601String().split('T')[0],
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }

      // Migrate existing labours
      final labours = await db.query('labours');
      for (final l in labours) {
        final amount = (l['totalPaid'] as num?)?.toDouble() ?? 0;
        if (amount > 0) {
          await db.insert('labour_payments', {
            'id': const Uuid().v4(),
            'labourId': l['id'],
            'labourName': l['name'],
            'amount': amount,
            'paymentMode': l['paymentMode'] ?? 'Cash',
            'date': l['joiningDate'] ?? DateTime.now().toIso8601String().split('T')[0],
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
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
        paymentMode TEXT DEFAULT "Cash",
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
        paymentMode TEXT DEFAULT "Cash",
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
        paymentMode TEXT DEFAULT "Cash",
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
        paymentMode TEXT DEFAULT "Cash",
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

    await db.execute('''
      CREATE TABLE customer_payments (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMode TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE labour_payments (
        id TEXT PRIMARY KEY,
        labourId TEXT NOT NULL,
        labourName TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMode TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL
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

    if (customer.depositAmount > 0) {
      await db.insert('customer_payments', {
        'id': const Uuid().v4(),
        'customerId': customer.id,
        'customerName': customer.name,
        'amount': customer.depositAmount,
        'paymentMode': customer.paymentMode ?? 'Cash',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

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
    
    final oldRecordMaps = await db.query('customers', where: 'id = ?', whereArgs: [customer.id]);
    if (oldRecordMaps.isNotEmpty) {
      final oldRecord = Customer.fromMap(oldRecordMaps.first);
      final diff = customer.depositAmount - oldRecord.depositAmount;
      if (diff > 0) {
        await db.insert('customer_payments', {
          'id': const Uuid().v4(),
          'customerId': customer.id,
          'customerName': customer.name,
          'amount': diff,
          'paymentMode': customer.paymentMode ?? 'Cash',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }

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
    await db.delete('customer_payments', where: 'customerId = ?', whereArgs: [id]);
  }

  // ─── LABOUR CRUD ─────────────────────────────────────────────────────────────

  Future<String> insertLabour(Labour labour) async {
    final db = await database;
    await db.insert('labours', labour.toMap());
    
    if (labour.totalPaid > 0) {
      await db.insert('labour_payments', {
        'id': const Uuid().v4(),
        'labourId': labour.id,
        'labourName': labour.name,
        'amount': labour.totalPaid,
        'paymentMode': labour.paymentMode ?? 'Cash',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    
    return labour.id;
  }

  Future<List<Labour>> getLabours() async {
    final db = await database;
    final maps = await db.query('labours', orderBy: 'createdAt DESC');
    return maps.map((m) => Labour.fromMap(m)).toList();
  }

  Future<void> updateLabour(Labour labour) async {
    final db = await database;
    
    final oldRecordMaps = await db.query('labours', where: 'id = ?', whereArgs: [labour.id]);
    if (oldRecordMaps.isNotEmpty) {
      final oldRecord = Labour.fromMap(oldRecordMaps.first);
      final diff = labour.totalPaid - oldRecord.totalPaid;
      if (diff > 0) {
        await db.insert('labour_payments', {
          'id': const Uuid().v4(),
          'labourId': labour.id,
          'labourName': labour.name,
          'amount': diff,
          'paymentMode': labour.paymentMode ?? 'Cash',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }

    await db.update('labours', labour.toMap(), where: 'id = ?', whereArgs: [labour.id]);
  }

  Future<void> deleteLabour(String id) async {
    final db = await database;
    await db.delete('labours', where: 'id = ?', whereArgs: [id]);
    await db.delete('labour_payments', where: 'labourId = ?', whereArgs: [id]);
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

  // ─── TRANSACTION HISTORY ─────────────────────────────────────────────────────
  /// Returns a combined, date-sorted list of transactions:
  /// - Customer payments received (income)
  /// - Labour wages paid (expense)
  /// - Medicine purchases (expense)
  /// - Feed purchases (expense)
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> rows = [];

    // Customer payments received
    final customerPayments = await db.query('customer_payments', orderBy: 'date DESC');
    for (final cp in customerPayments) {
      rows.add({
        'id': cp['id'],
        'referenceId': cp['customerId'],
        'source': 'customer_payments',
        'date': cp['date'] ?? '',
        'title': 'Received from ${cp['customerName']}',
        'amount': (cp['amount'] as num?)?.toDouble() ?? 0,
        'type': 'income',
        'paymentMode': cp['paymentMode'] ?? 'Cash',
        'icon': 'customer',
      });
    }

    // Labour wages paid
    final labourPayments = await db.query('labour_payments', orderBy: 'date DESC');
    for (final lp in labourPayments) {
      rows.add({
        'id': lp['id'],
        'referenceId': lp['labourId'],
        'source': 'labour_payments',
        'date': lp['date'] ?? '',
        'title': 'Labour paid to ${lp['labourName']}',
        'amount': (lp['amount'] as num?)?.toDouble() ?? 0,
        'type': 'expense',
        'paymentMode': lp['paymentMode'] ?? 'Cash',
        'icon': 'labour',
      });
    }

    // Medicine purchases
    final medicines = await db.query('medicines', orderBy: 'date DESC');
    for (final m in medicines) {
      final cost = (m['cost'] as num?)?.toDouble() ?? 0;
      if (cost > 0) {
        rows.add({
          'id': m['id'],
          'source': 'medicines',
          'date': m['date'],
          'title': 'Medicine: ${m['name']}',
          'amount': cost,
          'type': 'expense',
          'paymentMode': m['paymentMode'] ?? 'Cash',
          'icon': 'medicine',
        });
      }
    }

    // Feed purchases
    final feeds = await db.query('feeds', orderBy: 'date DESC');
    for (final f in feeds) {
      final cost = (f['cost'] as num?)?.toDouble() ?? 0;
      if (cost > 0) {
        rows.add({
          'id': f['id'],
          'source': 'feeds',
          'date': f['date'],
          'title': 'Feed: ${f['type']}',
          'amount': cost,
          'type': 'expense',
          'paymentMode': f['paymentMode'] ?? 'Cash',
          'icon': 'feed',
        });
      }
    }

    // Farm data expenses
    final farmData = await db.query('farm_data', orderBy: 'date DESC');
    for (final fd in farmData) {
      final chicksAmt = (fd['chicksAmount'] as num?)?.toDouble() ?? 0;
      final otherExp = (fd['otherExpenses'] as num?)?.toDouble() ?? 0;
      
      if (chicksAmt > 0) {
        rows.add({
          'id': fd['id'],
          'source': 'farm_chicks',
          'date': fd['date'],
          'title': 'Chicks Purchase: ${fd['breed']}',
          'amount': chicksAmt,
          'type': 'expense',
          'paymentMode': fd['paymentMode'] ?? 'Cash',
          'icon': 'farm',
        });
      }
      
      if (otherExp > 0) {
        rows.add({
          'id': fd['id'],
          'source': 'farm_other',
          'date': fd['date'],
          'title': 'Farm Other Expenses',
          'amount': otherExp,
          'type': 'expense',
          'paymentMode': fd['paymentMode'] ?? 'Cash',
          'icon': 'farm',
        });
      }
    }

    // Sort by date descending
    rows.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return rows;
  }

  Future<void> deleteTransaction(String id, String source, String? referenceId, double amount) async {
    final db = await database;
    if (source == 'customer_payments') {
      await db.delete('customer_payments', where: 'id = ?', whereArgs: [id]);
      if (referenceId != null) {
        await db.execute('UPDATE customers SET depositAmount = MAX(0, depositAmount - ?) WHERE id = ?', [amount, referenceId]);
      }
    } else if (source == 'labour_payments') {
      await db.delete('labour_payments', where: 'id = ?', whereArgs: [id]);
      if (referenceId != null) {
        await db.execute('UPDATE labours SET totalPaid = MAX(0, totalPaid - ?) WHERE id = ?', [amount, referenceId]);
      }
    } else if (source == 'medicines') {
      await deleteMedicine(id);
    } else if (source == 'feeds') {
      await deleteFeed(id);
    } else if (source == 'farm_chicks' || source == 'farm_other') {
      final rows = await db.query('farm_data', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final fd = FarmData.fromMap(rows.first);
        final update = FarmData(
          id: fd.id,
          breed: fd.breed,
          date: fd.date,
          numberOfChicks: source == 'farm_chicks' ? 0 : fd.numberOfChicks,
          chicksAmount: source == 'farm_chicks' ? 0 : fd.chicksAmount,
          medicineAmount: fd.medicineAmount,
          grainsAmount: fd.grainsAmount,
          otherExpenses: source == 'farm_other' ? 0 : fd.otherExpenses,
          notes: fd.notes,
          paymentMode: fd.paymentMode,
          createdAt: fd.createdAt,
        );
        await updateFarmData(update);
      }
    }
  }
}
