import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'web_database_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static WebDatabaseHelper? _webHelper;

  Future<Database?> get database async {
    if (kIsWeb) {
      // For web, we don't use SQLite database
      return null;
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  WebDatabaseHelper get webHelper {
    _webHelper ??= WebDatabaseHelper.instance;
    return _webHelper!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tourism_app.db');
    print('📱 Database path: $path');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        print('✅ Database opened successfully');
        // Check if places table exists and has data
        db.rawQuery('SELECT COUNT(*) as count FROM places').then((result) {
          print('📊 Places table has ${result.first['count']} records');
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
          rethrow;
        }
      }
    }
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    print('👤 Inserting new user: ${user['username']}');
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      final id = await db.insert('users', user);
      print('✅ User inserted with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error inserting user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    print('🔍 Looking up user: $username');
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      print(results.isNotEmpty ? '✅ User found' : '❌ User not found');
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('❌ Error getting user by username: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      rethrow;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      int count = await db.update(
        'users',
        data,
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  // Places operations
  Future<int> insertPlace(Map<String, dynamic> place) async {
    try {
      Database? db = await database;
      if (db == null) throw Exception('Database not available');
      
      final id = await db.insert('places', place);
      print('✅ Place inserted: ${place['name_eng']} with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error inserting place ${place['name_eng']}: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllPlaces() async {
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      final places = await db.query('places');
      if (places.isEmpty) {
        print('⚠️ No places found in database');
      } else {
        print('📊 Found ${places.length} places in database');
      }
      return places;
    } catch (e) {
      print('❌ Error getting all places: $e');
      rethrow;
    }
  }

  // Alias for getAllPlaces to match DatabaseAdapter interface
  Future<List<Map<String, dynamic>>> getPlaces() async {
    return await getAllPlaces();
  }

  Future<int> getPlacesCount() async {
    try {
      Database? db = await database;
      if (db == null) throw Exception('Database not available');
      
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM places');
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count;
    } catch (e) {
      print('❌ Error counting places: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getPlacesByCategory(String category) async {
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      final places = await db.query(
        'places',
        where: 'category = ?',
        whereArgs: [category],
      );
      print('📊 Found ${places.length} places in category: $category');
      return places;
    } catch (e) {
      print('❌ Error getting places by category: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query, String language) async {
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      String nameColumn = language == 'en' ? 'name_eng' : 'name_som';
      String descColumn = language == 'en' ? 'desc_eng' : 'desc_som';

      return await db.query(
        'places',
        where: '$nameColumn LIKE ? OR $descColumn LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
    } catch (e) {
      print('❌ Error searching places: $e');
      rethrow;
    }
  }

  // Favorites operations
  Future<int> addToFavorites(dynamic userId, dynamic placeId) async {
    final userIdInt = userId is int ? userId : int.parse(userId.toString());
    final placeIdInt = placeId is int ? placeId : int.parse(placeId.toString());
    
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      final id = await db.insert('favorites', {
        'user_id': userIdInt,
        'place_id': placeIdInt,
      });
      return id;
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  // Alias for addToFavorites to match DatabaseAdapter interface
  Future<void> insertFavorite(Map<String, dynamic> favorite) async {
    await addToFavorites(favorite['user_id'], favorite['place_id']);
  }

  Future<int> removeFromFavorites(dynamic userId, dynamic placeId) async {
    final userIdInt = userId is int ? userId : int.parse(userId.toString());
    final placeIdInt = placeId is int ? placeId : int.parse(placeId.toString());
    
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      final count = await db.delete(
        'favorites',
        where: 'user_id = ? AND place_id = ?',
        whereArgs: [userIdInt, placeIdInt],
      );
      return count;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  // Alias for removeFromFavorites to match DatabaseAdapter interface
  Future<void> deleteFavorite(int placeId) async {
    // Note: This method needs a user ID to work properly
    // For now, we'll throw an exception to indicate missing implementation
    throw UnimplementedError('deleteFavorite requires user ID - use removeFromFavorites instead');
  }

  Future<List<Map<String, dynamic>>> getFavoritePlaces(dynamic userId) async {
    final userIdInt = userId is int ? userId : int.parse(userId.toString());
    
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      return await db.rawQuery('''
        SELECT p.* FROM places p
        INNER JOIN favorites f ON p.id = f.place_id
        WHERE f.user_id = ?
      ''', [userIdInt]);
    } catch (e) {
      print('❌ Error getting favorite places: $e');
      rethrow;
    }
  }

  // Alias for getFavoritePlaces to match DatabaseAdapter interface
  Future<List<Map<String, dynamic>>> getFavorites() async {
    // Note: This method needs a user ID to work properly
    // For now, we'll return all favorites without user filtering
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      return await db.query('favorites');
    } catch (e) {
      print('❌ Error getting favorites: $e');
      rethrow;
    }
  }

  Future<bool> isPlaceFavorite(dynamic userId, dynamic placeId) async {
    final userIdInt = userId is int ? userId : int.parse(userId.toString());
    final placeIdInt = placeId is int ? placeId : int.parse(placeId.toString());
    
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      List<Map<String, dynamic>> results = await db.query(
        'favorites',
        where: 'user_id = ? AND place_id = ?',
        whereArgs: [userIdInt, placeIdInt],
      );
      return results.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if place is favorite: $e');
      rethrow;
    }
  }

  // Alias for isPlaceFavorite to match DatabaseAdapter interface
  Future<bool> isFavorite(int placeId) async {
    // Note: This method needs a user ID to work properly
    // For now, we'll throw an exception to indicate missing implementation
    throw UnimplementedError('isFavorite requires user ID - use isPlaceFavorite instead');
  }

  Future<bool> placeExists(String nameEng) async {
    print('🔍 Checking if place exists: $nameEng');
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      List<Map<String, dynamic>> results = await db.query(
        'places',
        where: 'name_eng = ?',
        whereArgs: [nameEng],
      );
      print(results.isNotEmpty ? '✅ Place exists' : '❌ Place does not exist');
      return results.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if place exists: $e');
      rethrow;
    }
  }

  // Method to get place by name (useful for checking existence)
  Future<Map<String, dynamic>?> getPlaceByName(String nameEng) async {
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      List<Map<String, dynamic>> results = await db.query(
        'places',
        where: 'name_eng = ?',
        whereArgs: [nameEng],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('❌ Error getting place by name: $e');
      rethrow;
    }
  }

  // Update place by English name
  Future<int> updatePlaceByName(String nameEng, Map<String, dynamic> place) async {
    print('🔄 Updating place: $nameEng');
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      final count = await db.update(
        'places',
        place,
        where: 'name_eng = ?',
        whereArgs: [nameEng],
      );
      print('✅ Updated $count place(s)');
      return count;
    } catch (e) {
      print('❌ Error updating place: $e');
      rethrow;
    }
  }

  // Method to check if places table is empty
  Future<bool> isPlacesTableEmpty() async {
    try {
      Database? db = await database;
      if (db == null) throw Exception('Database not available');
      
      List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM places');
      return result.first['count'] == 0;
    } catch (e) {
      print('❌ Error checking if places table is empty: $e');
      rethrow;
    }
  }

  // Chat Messages operations
  Future<int> insertChatMessage(Map<String, dynamic> message) async {
    if (kIsWeb) {
      return await webHelper.insertChatMessage(message);
    }
    
    print('💬 Inserting new chat message');
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      final id = await db.insert('chat_messages', message);
      print('✅ Chat message inserted with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error inserting chat message: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages([int? userId]) async {
    if (kIsWeb) {
      return await webHelper.getChatMessages(userId);
    }
    
    print('📨 Fetching chat messages');
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      final messages = await db.query(
        'chat_messages',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
        orderBy: 'timestamp ASC',
      );
      print('📊 Found ${messages.length} chat messages');
      return messages;
    } catch (e) {
      print('❌ Error getting chat messages: $e');
      rethrow;
    }
  }

  Future<void> clearChatMessages([int? userId]) async {
    if (kIsWeb) {
      return await webHelper.clearChatMessages(userId);
    }
    
    print('🗑️ Clearing chat messages');
    Database? db = await database;
    if (db == null) throw Exception('Database not available');
    
    try {
      await db.delete(
        'chat_messages',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
      );
      print('✅ Chat messages cleared');
    } catch (e) {
      print('❌ Error clearing chat messages: $e');
      rethrow;
    }
  }
}
