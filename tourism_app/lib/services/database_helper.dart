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
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) {
        print('✅ Database opened successfully');
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
        category TEXT CHECK(category IN ('beach', 'historical', 'cultural', 'religious')) NOT NULL
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

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    print('👤 Inserting new user: ${user['username']}');
    Database db = await database;
    final id = await db.insert('users', user);
    print('✅ User inserted with ID: $id');
    return id;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    print('🔍 Looking up user: $username');
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
    print('🏖️ Inserting new place: ${place['name_eng']}');
    Database db = await database;
    final id = await db.insert('places', place);
    print('✅ Place inserted with ID: $id');
    return id;
  }

  Future<List<Map<String, dynamic>>> getAllPlaces() async {
    print('🔍 Fetching all places');
    Database db = await database;
    final places = await db.query('places');
    print('✅ Found ${places.length} places');
    return places;
  }

  Future<List<Map<String, dynamic>>> getPlacesByCategory(
      String category) async {
    Database db = await database;
    final places = await db.query(
      'places',
      where: 'category = ?',
      whereArgs: [category],
    );
    print('✅ Found ${places.length} places in category: $category');
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
  Future<int> addToFavorites(int userId, int placeId) async {
    print('⭐ Adding place $placeId to favorites for user $userId');
    Database db = await database;
    final id = await db.insert('favorites', {
      'user_id': userId,
      'place_id': placeId,
    });
    print('✅ Added to favorites with ID: $id');
    return id;
  }

  Future<int> removeFromFavorites(int userId, int placeId) async {
    print('🗑️ Removing place $placeId from favorites for user $userId');
    Database db = await database;
    final count = await db.delete(
      'favorites',
      where: 'user_id = ? AND place_id = ?',
      whereArgs: [userId, placeId],
    );
    print('✅ Removed $count favorite(s)');
    return count;
  }

  Future<List<Map<String, dynamic>>> getFavoritePlaces(int userId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT p.* FROM places p
      INNER JOIN favorites f ON p.id = f.place_id
      WHERE f.user_id = ?
    ''', [userId]);
  }

  Future<bool> isPlaceFavorite(int userId, int placeId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'favorites',
      where: 'user_id = ? AND place_id = ?',
      whereArgs: [userId, placeId],
    );
    return results.isNotEmpty;
  }

  Future<bool> placeExists(String nameEng) async {
    print('🔍 Checking if place exists: $nameEng');
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
    print('✅ Updated $count place(s)');
    return count;
  }

  // Method to check if places table is empty
  Future<bool> isPlacesTableEmpty() async {
    Database db = await database;
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT COUNT(*) as count FROM places');
    return result.first['count'] == 0;
  }

  // Get count of places in database
  Future<int> getPlacesCount() async {
    Database db = await database;
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT COUNT(*) as count FROM places');
    return result.first['count'];
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
    print('🔍 Fetching chat messages');
    Database db = await database;
    final messages = await db.query(
      'chat_messages',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'timestamp ASC',
    );
    print('✅ Found ${messages.length} chat messages');
    return messages;
  }

  Future<void> clearChatMessages(int? userId) async {
    print('🗑️ Clearing chat messages');
    Database db = await database;
    await db.delete(
      'chat_messages',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
    print('✅ Chat messages cleared');
  }
}
