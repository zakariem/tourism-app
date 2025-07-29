import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tourism_app.db');
    print('📱 Database path: $path');
    print(
        '🖥️ Platform: ${Platform.isWindows ? 'Windows' : Platform.isMacOS ? 'macOS' : Platform.isLinux ? 'Linux' : 'Mobile'}');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        print('✅ Database opened successfully');
        // Check if places table exists and has data
        db.rawQuery('SELECT COUNT(*) as count FROM places').then((result) {
          // Places table has ${result.first['count']} records
        }).catchError((e) {
          print('❌ Error checking places table: $e');
        });
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🔄 Creating database tables...');

    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        email TEXT,
        full_name TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Users table created');

    // Create places table
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_som TEXT NOT NULL,
        name_eng TEXT NOT NULL,
        desc_som TEXT NOT NULL,
        desc_eng TEXT NOT NULL,
        location TEXT NOT NULL,
        image_path TEXT,
        category TEXT CHECK(category IN ('beach', 'historical', 'cultural', 'religious', 'suburb', 'urban park')) NOT NULL
      )
    ''');
    print('✅ Places table created');

    // Create favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        place_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (place_id) REFERENCES places (id) ON DELETE CASCADE,
        UNIQUE(user_id, place_id)
      )
    ''');
    print('✅ Favorites table created');

    // Create chat_messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        is_user BOOLEAN NOT NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print('✅ Chat messages table created');

    print('🎉 All database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add new categories to the places table constraint
      // Since SQLite doesn't support modifying CHECK constraints directly,
      // we'll need to recreate the table with the new constraint
      print('🔄 Updating places table constraint for new categories...');

      try {
        // Create a temporary table with the new schema
        await db.execute('''
          CREATE TABLE places_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name_som TEXT NOT NULL,
            name_eng TEXT NOT NULL,
            desc_som TEXT NOT NULL,
            desc_eng TEXT NOT NULL,
            location TEXT NOT NULL,
            image_path TEXT,
            category TEXT CHECK(category IN ('beach', 'historical', 'cultural', 'religious', 'suburb', 'urban park')) NOT NULL
          )
        ''');

        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO places_new 
          SELECT * FROM places
        ''');

        // Drop old table and rename new table
        await db.execute('DROP TABLE places');
        await db.execute('ALTER TABLE places_new RENAME TO places');

        print('✅ Places table updated successfully');
      } catch (e) {
        print('❌ Error during database upgrade: $e');
        // If upgrade fails, try to recreate the table from scratch
        try {
          await db.execute('DROP TABLE IF EXISTS places');
          await db.execute('''
            CREATE TABLE places (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name_som TEXT NOT NULL,
              name_eng TEXT NOT NULL,
              desc_som TEXT NOT NULL,
              desc_eng TEXT NOT NULL,
              location TEXT NOT NULL,
              image_path TEXT,
              category TEXT CHECK(category IN ('beach', 'historical', 'cultural', 'religious', 'suburb', 'urban park')) NOT NULL
            )
          ''');
          print('✅ Places table recreated successfully');
        } catch (e2) {
          print('❌ Error recreating places table: $e2');
        }
      }
    }
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    print('👤 Inserting new user: ${user['username']}');
    Database db = await database;
    final id = await db.insert('users', user);
    print('✅ User inserted with ID: $id');
    return id;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    // Looking up user: $username
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    print(results.isNotEmpty ? '✅ User found' : '❌ User not found');
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    Database db = await database;
    int count = await db.update(
      'users',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  // Places operations
  Future<int> insertPlace(Map<String, dynamic> place) async {
    try {
      Database db = await database;
      final id = await db.insert('places', place);
      return id;
    } catch (e) {
      print('❌ Error inserting place ${place['name_eng']}: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllPlaces() async {
    Database db = await database;
    final places = await db.query('places');
    if (places.isEmpty) {
      print('⚠️ No places found in database');
    }
    return places;
  }

  Future<int> getPlacesCount() async {
    try {
      Database db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM places');
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count;
    } catch (e) {
      print('❌ Error counting places: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getPlacesByCategory(
      String category) async {
    Database db = await database;
    final places = await db.query(
      'places',
      where: 'category = ?',
      whereArgs: [category],
    );
    // Found ${places.length} places in category: $category
    return places;
  }

  Future<List<Map<String, dynamic>>> searchPlaces(
      String query, String language) async {
    Database db = await database;
    String nameColumn = language == 'en' ? 'name_eng' : 'name_som';
    String descColumn = language == 'en' ? 'desc_eng' : 'desc_som';

    return await db.query(
      'places',
      where: '$nameColumn LIKE ? OR $descColumn LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }

  // Favorites operations
  Future<int> addToFavorites(dynamic userId, dynamic placeId) async {
    final userIdInt = userId is int ? userId : int.parse(userId.toString());
    final placeIdInt = placeId is int ? placeId : int.parse(placeId.toString());
    
    Database db = await database;
    final id = await db.insert('favorites', {
      'user_id': userIdInt,
      'place_id': placeIdInt,
    });
    return id;
  }

  Future<int> removeFromFavorites(dynamic userId, dynamic placeId) async {
    final userIdInt = userId is int ? userId : int.parse(userId.toString());
    final placeIdInt = placeId is int ? placeId : int.parse(placeId.toString());
    
    Database db = await database;
    final count = await db.delete(
      'favorites',
      where: 'user_id = ? AND place_id = ?',
      whereArgs: [userIdInt, placeIdInt],
    );
    return count;
  }

  Future<List<Map<String, dynamic>>> getFavoritePlaces(dynamic userId) async {
    final userIdInt = userId is int ? userId : int.parse(userId.toString());
    
    Database db = await database;
    return await db.rawQuery('''
      SELECT p.* FROM places p
      INNER JOIN favorites f ON p.id = f.place_id
      WHERE f.user_id = ?
    ''', [userIdInt]);
  }

  Future<bool> isPlaceFavorite(dynamic userId, dynamic placeId) async {
    final userIdInt = userId is int ? userId : int.parse(userId.toString());
    final placeIdInt = placeId is int ? placeId : int.parse(placeId.toString());
    
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'favorites',
      where: 'user_id = ? AND place_id = ?',
      whereArgs: [userIdInt, placeIdInt],
    );
    return results.isNotEmpty;
  }

  Future<bool> placeExists(String nameEng) async {
    // Checking if place exists: $nameEng
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'places',
      where: 'name_eng = ?',
      whereArgs: [nameEng],
    );
    print(results.isNotEmpty ? '✅ Place exists' : '❌ Place does not exist');
    return results.isNotEmpty;
  }

  // Method to get place by name (useful for checking existence)
  Future<Map<String, dynamic>?> getPlaceByName(String nameEng) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'places',
      where: 'name_eng = ?',
      whereArgs: [nameEng],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Update place by English name
  Future<int> updatePlaceByName(
      String nameEng, Map<String, dynamic> place) async {
    print('🔄 Updating place: $nameEng');
    Database db = await database;
    final count = await db.update(
      'places',
      place,
      where: 'name_eng = ?',
      whereArgs: [nameEng],
    );
    // Updated $count place(s)
    return count;
  }

  // Method to check if places table is empty
  Future<bool> isPlacesTableEmpty() async {
    Database db = await database;
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT COUNT(*) as count FROM places');
    return result.first['count'] == 0;
  }

  // Chat Messages operations
  Future<int> insertChatMessage(Map<String, dynamic> message) async {
    print('💬 Inserting new chat message');
    Database db = await database;
    final id = await db.insert('chat_messages', message);
    print('✅ Chat message inserted with ID: $id');
    return id;
  }

  Future<List<Map<String, dynamic>>> getChatMessages(int? userId) async {
    // Fetching chat messages
    Database db = await database;
    final messages = await db.query(
      'chat_messages',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'timestamp ASC',
    );
    // Found ${messages.length} chat messages
    return messages;
  }

  Future<void> clearChatMessages(int? userId) async {
    // Clearing chat messages
    Database db = await database;
    await db.delete(
      'chat_messages',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
    // Chat messages cleared
  }
}
