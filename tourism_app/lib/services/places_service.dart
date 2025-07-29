import 'package:http/http.dart' as http;
import 'dart:convert';

class PlacesService {
  static const String baseUrl = 'http://localhost:9000/api/places';

  static Future<List<Map<String, dynamic>>> getAllPlaces() async {
    try {
      print('🌐 Fetching places from server...');
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final places = data.map((place) {
          // Convert to Map and use image_data from MongoDB
          final placeMap = Map<String, dynamic>.from(place);
          if (placeMap['image_data'] != null) {
            // Use the base64 image data directly
            placeMap['image_url'] = placeMap['image_data'];
            print('🔗 Using image_data for ${placeMap['name_eng']}');
          } else if (placeMap['image_path'] != null) {
            // Fallback to image_path if image_data is not available
            placeMap['image_url'] =
                'http://localhost:9000/uploads/${placeMap['image_path']}';
            print('🔗 Using image_path for ${placeMap['name_eng']}');
          } else {
            print('⚠️ No image data for ${placeMap['name_eng']}');
          }
          return placeMap;
        }).toList();
        print('✅ Fetched ${places.length} places from server');
        return places;
      } else {
        print('❌ Server error: ${response.statusCode}');
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching places: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPlacesByCategory(
      String category) async {
    try {
      print('🌐 Fetching places for category: $category');
      final response = await http.get(Uri.parse('$baseUrl/category/$category'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final places = data.map((place) {
          // Convert to Map and use image_data from MongoDB
          final placeMap = Map<String, dynamic>.from(place);
          if (placeMap['image_data'] != null) {
            // Use the base64 image data directly
            placeMap['image_url'] = placeMap['image_data'];
          } else if (placeMap['image_path'] != null) {
            // Fallback to image_path if image_data is not available
            placeMap['image_url'] =
                'http://localhost:9000/uploads/${placeMap['image_path']}';
          }
          return placeMap;
        }).toList();
        print('✅ Fetched ${places.length} places for category: $category');
        return places;
      } else {
        print('❌ Server error: ${response.statusCode}');
        throw Exception(
            'Failed to load places for category $category: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching places for category $category: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getPlaceById(String id) async {
    try {
      print('🌐 Fetching place with ID: $id');
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        final place = Map<String, dynamic>.from(json.decode(response.body));
        // Use image_data from MongoDB
        if (place['image_data'] != null) {
          place['image_url'] = place['image_data'];
        } else if (place['image_path'] != null) {
          place['image_url'] =
              'http://localhost:9000/uploads/${place['image_path']}';
        }
        print('✅ Fetched place: ${place['name_eng']}');
        return place;
      } else {
        print('❌ Server error: ${response.statusCode}');
        throw Exception('Failed to load place: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching place with ID $id: $e');
      return null;
    }
  }
}
