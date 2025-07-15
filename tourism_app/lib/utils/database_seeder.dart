import 'package:tourism_app/services/database_helper.dart';

class DatabaseSeeder {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  static Future<void> seedTouristPlaces() async {
    print('Checking for new tourist places to seed...');

    final places = [
      {
        'name_eng': 'Lido Beach',
        'name_som': 'Xeebta Liido',
        'desc_eng':
            'One of the most beautiful beaches in Mogadishu, perfect for swimming and relaxation.',
        'desc_som':
            'Mid ka mid ah xeebaha ugu quruxda badan Muqdisho, ku haboon dabaasha iyo nasashada.',
        'location': 'Mogadishu, Somalia',
        'category': 'beach',
        'image_path': 'liido.jpg',
      },
      {
        'name_eng': 'Somali National Museum',
        'name_som': 'Maktabadda Qaranka Soomaaliyeed',
        'desc_eng':
            'A historical museum showcasing Somali culture and heritage.',
        'desc_som':
            'Maktabaddo taariikhi ah oo bandhigta dhaqanka iyo hiddaha Soomaalida.',
        'location': 'Mogadishu, Somalia',
        'category': 'cultural',
        'image_path': 'national_museum.jpg',
      },
      {
        'name_eng': "Arba'a Rukun Mosque",
        'name_som': "Masaajidka Arba'a Rukun",
        'desc_eng':
            'One of the oldest mosques in Mogadishu, built in the 7th century.',
        'desc_som':
            "Mid ka mid ah masaajidyada ugu da'da weyn Muqdisho, la dhisay qarnigii 7aad.",
        'location': 'Mogadishu, Somalia',
        'category': 'religious',
        'image_path': 'arbaa_rukun.jpg',
      },
      {
        'name_eng': 'Laas Geel Cave Paintings',
        'name_som': 'Sawirrada Godka Laas Geel',
        'desc_eng':
            'Ancient rock art dating back to 5000 years, featuring well-preserved cave paintings.',
        'desc_som':
            'Farshaxan dhagax ah oo 5000 sano jir ah, oo leh sawirro god ah oo si fiican loo keydiyey.',
        'location': 'Hargeisa, Somaliland',
        'category': 'historical',
        'image_path': 'laas_geel.jpg',
      },
      {
        'name_eng': 'Hargeisa Cultural Center',
        'name_som': 'Xarunta Dhaqanka Hargeysa',
        'desc_eng':
            'A vibrant cultural center showcasing Somali arts, music, and traditions.',
        'desc_som':
            'Xarun dhaqameed oo bandhigta farshaxanka, muusigta, iyo dhaqamada Soomaalida.',
        'location': 'Hargeisa, Somaliland',
        'category': 'cultural',
        'image_path': 'hargeisa_cultural.jpg',
      },
      {
        'name_eng': 'Berbera Beach',
        'name_som': 'Xeebta Berbera',
        'desc_eng':
            'Beautiful coastal city with pristine beaches and historical port.',
        'desc_som':
            'Magaalo xeebeed oo quruxsan oo leh xeebo fiican iyo deked taariikhi ah.',
        'location': 'Berbera, Somaliland',
        'category': 'beach',
        'image_path': 'berbera_beach.jpg',
      },
      {
        'name_eng': 'Sheikh Sufi Mosque',
        'name_som': 'Masaajidka Sheekh Sufi',
        'desc_eng':
            'Historic mosque known for its unique architecture and spiritual significance.',
        'desc_som':
            'Masaajid taariikhi ah oo loo yaqaano qaab-dhismeedkiisa gaar ah iyo muhiimadda ruuxda ah.',
        'location': 'Mogadishu, Somalia',
        'category': 'religious',
        'image_path': 'sheikh_sufi.jpg',
      },
      {
        'name_eng': 'Jowhara International Hotel',
        'name_som': 'Hoteelka Caalamiga ah ee Jowhara',
        'desc_eng':
            'one of the finest hotels in kismayo, offering luxury accommodation and dining.',
        'desc_som':
            'mid ka mid ah hoteelada ugu fiican kismayo, oo bixiya hoy raaxo leh iyo cuntooyin.',
        'location': 'Kismayo, Somalia',
        'category': 'beach',
        'image_path': 'sheikh_sufi.jpg',
      },
    ];

    int newPlacesCount = 0;
    int skippedPlacesCount = 0;

    try {
      for (var place in places) {
        // Check if place already exists based on English name
        bool placeExists = await _dbHelper.placeExists(place['name_eng']!);

        if (!placeExists) {
          // Insert new place
          await _dbHelper.insertPlace(place);
          newPlacesCount++;
          print('✓ Added new place: ${place['name_eng']}');
        } else {
          // Skip existing place
          skippedPlacesCount++;
          print('• Skipped existing place: ${place['name_eng']}');
        }
      }

      print('\n=== Seeding Summary ===');
      print('New places added: $newPlacesCount');
      print('Existing places skipped: $skippedPlacesCount');
      print('Total places in seed data: ${places.length}');
    } catch (e) {
      print('Error during seeding: $e');
    }
  }

  static Future<void> seedDatabase() async {
    await seedTouristPlaces();
  }

  // Method to update existing places (optional - if you want to update data for existing places)
  static Future<void> updateExistingPlaces() async {
    print('Updating existing places with new data...');

    final places = [
      // Same places array as above
    ];

    int updatedCount = 0;
    int addedCount = 0;

    try {
      for (var place in places) {
        bool placeExists = await _dbHelper.placeExists(place['name_eng']);

        if (placeExists) {
          // Update existing place
          await _dbHelper.updatePlaceByName(place['name_eng'], place);
          updatedCount++;
          print('✓ Updated place: ${place['name_eng']}');
        } else {
          // Add new place
          await _dbHelper.insertPlace(place);
          addedCount++;
          print('✓ Added new place: ${place['name_eng']}');
        }
      }

      print('\n=== Update Summary ===');
      print('Places updated: $updatedCount');
      print('New places added: $addedCount');
    } catch (e) {
      print('Error during update: $e');
    }
  }
}
