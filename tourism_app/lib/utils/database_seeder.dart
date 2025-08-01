import 'package:tourism_app/services/database_adapter.dart';

class DatabaseSeeder {
  static final DatabaseAdapter _dbHelper = DatabaseAdapter.instance;

  static Future<void> seedTouristPlaces() async {
    print('🌱 Starting database seeding...');
    print('Checking for new tourist places to seed...');

    // Add a simple test place first to verify database is working
    final testPlace = {
      'name_eng': 'Test Place',
      'name_som': 'Test Place',
      'desc_eng': 'This is a test place to verify database is working.',
      'desc_som': 'This is a test place to verify database is working.',
      'location': 'Test Location',
      'category': 'beach',
      'image_path': 'liido.jpg',
    };

    try {
      // Try to insert test place first
      await _dbHelper.insertPlace(testPlace);
      print('✅ Test place inserted successfully');
    } catch (e) {
      print('❌ Error inserting test place: $e');
    }

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
        'name_eng': 'Abaaydhaxan',
        'name_som': 'Abaaydhaxan',
        'desc_eng':
            'A historic settlement south of Mogadishu, known for its ancient architecture and ruined stone houses, including old mosques.',
        'desc_som':
            'Degmo taariikhi ah oo koonfur ka xigta Muqdisho, caan ku ah dhismayaal qadiimi ah iyo guryo dhagax ah oo masajidadooduna ay burbureen.',
        'location': 'Near Mogadishu, Banaadir, Somalia',
        'category': 'historical',
        'image_path': 'abaaydhaxan.png',
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
            'One of the finest hotels in Kismayo, offering luxury accommodation and dining.',
        'desc_som':
            'Mid ka mid ah hoteelada ugu fiican Kismayo, oo bixiya hoy raaxo leh iyo cuntooyin.',
        'location': 'Kismayo, Somalia',
        'category': 'cultural',
        'image_path': 'jowhara_hotel.jpg',
      },
      {
        'name_eng': 'Nimow',
        'name_som': 'Nimow',
        'desc_eng':
            'A small historical town about 30 km south‑east of Mogadishu, featuring ruins of stone houses and mosques, once home to Islamic scholars.',
        'desc_som':
            'Magaalo yar oo taariikhi ah, qiyaastii 30 km koonfur‑bari ka xigta Muqdisho, leh guryo dhagax ah oo burburay iyo masaajid, markii horena waxaa degan jiray culimo.',
        'location': 'Near Mogadishu, Banaadir, Somalia',
        'category': 'historical',
        'image_path': 'nimow-2.png',
      },
      {
        'name_eng': 'Warsheikh',
        'name_som': 'Warshiikh',
        'desc_eng':
            'A coastal town about 70 km north of Mogadishu, once a major settlement in the Sultanate of Mogadishu and home to historic mosques and colonial buildings.',
        'desc_som':
            'Magaalo xeebeed qiyaastii 70 km waqooyi kaga beegan Muqdisho, ahayd xarun muhiim ah xilligii Boqortooyadii Muqdisho, leh masaajido taariikhi ah iyo dhismayaal taariikhi ah.',
        'location': 'Warsheikh, Middle Shabelle, Somalia',
        'category': 'cultural',
        'image_path': 'warshiikh.png',
      },
      {
        'name_eng': 'Beerta Nabada',
        'name_som': 'Beerta Nabada',
        'desc_eng':
            'A public park in Mogadishu (also called "Warta Nabada"), popular among locals for relaxation and recreation in the capital.',
        'desc_som':
            'Beertii dadweynaha ee Muqdisho (loo yaqaan "Warta Nabada"), oo caan ku ah madadaalo iyo nasasho bulshooyinka deegaanka magaalada.',
        'location': 'Mogadishu, Banaadir, Somalia',
        'category': 'urban park',
        'image_path': 'beerta-nabada.png',
      },
      {
        'name_eng': 'Beerta Xamar',
        'name_som': 'Beerta Xamar',
        'desc_eng':
            'A recreational green space in Xamar Weyne district of Mogadishu, often used by locals for leisure, picnics, and evening strolls.',
        'desc_som':
            'Goob cagaaran oo madadaalo ah oo ku taalla degmada Xamar Weyne ee Muqdisho, dadka deegaanka badanaa waxay u adeegsadaan nasasho, picnic, iyo socod habeenkii.',
        'location': 'Mogadishu, Banaadir, Somalia',
        'category': 'urban park',
        'image_path': 'beerta-xamar.png',
      },
      {
        'name_eng': 'Beerta Banadir',
        'name_som': 'Beerta Banaadir',
        'desc_eng':
            'Another central park in Mogadishu often associated with the Banaadir Market area, serving as a local gathering and leisure spot.',
        'desc_som':
            'Beerta kale ee bartamaha Muqdisho oo inta badan lala xiriiriyo aagga Suuqa Banaadir, waxay u tahay bulshada deegaanka meel isugu yimaadaan oo madadaalo ah.',
        'location': 'Mogadishu, Banaadir, Somalia',
        'category': 'urban park',
        'image_path': 'beerta-banadir.png',
      },
      {
        'name_eng': 'Xeebta Jaziira (Jaziira Beach)',
        'name_som': 'Xeebta Jaziira',
        'desc_eng':
            'Jazeera (Gezira) Beach near Mogadishu, a leisure destination where locals gather, featuring a small island reachable by boat and nearby animal market and salt-mining.',
        'desc_som':
            'Xeebta Jasiira oo ku dhow Muqdisho, ah meel nasasho oo dadku isugu yimaadaan, leh jasiirad yar oo la tegi karo dooni, suuqa xoolaha iyo macdanta milixda agteeda.',
        'location': 'Mogadishu, Banaadir, Somalia',
        'category': 'beach',
        'image_path': 'jaziira.png',
      },
      {
        'name_eng': 'Dayniile',
        'name_som': 'Dayniile',
        'desc_eng':
            'A suburban district of Mogadishu, known for its proximity to coastal and desert landscapes; visitors often pass through or stay when exploring outlying areas.',
        'desc_som':
            'Degmo ka tirsan Muqdisho, caan ku ah meelaha xeebaha iyo lamadega ah ee agteeda; booqdayaashu waxay marsiiyaan ama ku nagaanayaan markay meelaha agagaarka ah baaraan.',
        'location': 'Dayniile, Mogadishu, Banaadir, Somalia',
        'category': 'suburb',
        'image_path': 'dayniile.png',
      },
    ];

    int newPlacesCount = 0;
    int skippedPlacesCount = 0;

    try {
      for (var place in places) {
        // Check if place already exists based on English name
        final existingPlace = await _dbHelper.getPlaceByName(place['name_eng']!);
        bool placeExists = existingPlace != null;

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
      print('🌱 Database seeding completed!');
    } catch (e) {
      print('❌ Error during seeding: $e');
      rethrow;
    }
  }

  static Future<void> seedDatabase() async {
    print('🌱 Starting database seeding process...');

    try {
      // Check if database is empty
      final isEmpty = await _dbHelper.isPlacesTableEmpty();
      print('📊 Database is empty: $isEmpty');

      if (isEmpty) {
        print('⚠️ Database is empty, forcing reseed...');
      }

      await seedTouristPlaces();

      // Verify seeding was successful
      final finalIsEmpty = await _dbHelper.isPlacesTableEmpty();
      print('📊 Database is empty after seeding: $finalIsEmpty');

      if (finalIsEmpty) {
        print('❌ WARNING: Database is still empty after seeding!');
      } else {
        print('✅ Database seeding completed successfully!');
      }
    } catch (e) {
      print('❌ Error during database seeding: $e');
      rethrow;
    }
  }

  // Method to force reseed the database (clears existing data and reseeds)
  static Future<void> forceReseed() async {
    print('🔄 Force reseeding database...');

    try {
      // Note: This method would need to be implemented in DatabaseAdapter
      // For now, we'll just reseed without clearing
      await seedTouristPlaces();
      print('✅ Force reseed completed!');
    } catch (e) {
      print('❌ Error during force reseed: $e');
      rethrow;
    }
  }

  // Method to update existing places
  static Future<void> updateExistingPlaces() async {
    print('🔄 Updating existing places with new data...');

    // This would use the same places array as in seedTouristPlaces
    // Implementation would depend on having an updatePlace method in DatabaseAdapter
    print('⚠️ Update functionality not yet implemented in DatabaseAdapter');
  }
}
