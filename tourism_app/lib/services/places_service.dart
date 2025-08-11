import 'package:http/http.dart' as http;
import 'dart:convert';

class PlacesService {
  static const String baseUrl = 'http://localhost:9000/api/places';

  static Future<List<Map<String, dynamic>>> getAllPlaces() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Handle different response formats
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Handle wrapped response like {"data": [...]} from server
          data = responseData['data'] as List<dynamic>;
        } else if (responseData is Map && responseData.containsKey('places')) {
          // Handle wrapped response like {"places": [...]}
          data = responseData['places'] as List<dynamic>;
        } else if (responseData is Map) {
          // Single place object, wrap in list
          data = [responseData];
        } else {
          print('❌ Unexpected response format: $responseData');
          return [];
        }
        
        final places = data.map<Map<String, dynamic>>((place) {
          // Convert to Map and use image_data from MongoDB
          final placeMap = Map<String, dynamic>.from(place);
          
          // Ensure essential fields are not null
          placeMap['id'] = placeMap['id']?.toString() ?? '';
          placeMap['name_eng'] = placeMap['name_eng']?.toString() ?? placeMap['name']?.toString() ?? '';
          placeMap['category'] = placeMap['category']?.toString() ?? '';
          placeMap['description'] = placeMap['description']?.toString() ?? '';
          placeMap['location'] = placeMap['location']?.toString() ?? '';
          
          if (placeMap['image_data'] != null) {
            // Use the base64 image data directly
            placeMap['image_url'] = placeMap['image_data'].toString();
          } else if (placeMap['image_path'] != null) {
            // Fallback to image_path if image_data is not available
            placeMap['image_url'] =
                'http://localhost:9000/uploads/${placeMap['image_path'].toString()}';
          } else {
            placeMap['image_url'] = '';
          }
          return placeMap;
        }).toList();
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
      final response = await http.get(Uri.parse('$baseUrl/category/$category'));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Handle different response formats
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Handle wrapped response like {"data": [...]} from server
          data = responseData['data'] as List<dynamic>;
        } else if (responseData is Map && responseData.containsKey('places')) {
          // Handle wrapped response like {"places": [...]}
          data = responseData['places'] as List<dynamic>;
        } else if (responseData is Map) {
          // Single place object, wrap in list
          data = [responseData];
        } else {
          print('❌ Unexpected response format: $responseData');
          return [];
        }
        
        final places = data.map<Map<String, dynamic>>((place) {
          // Convert to Map and use image_data from MongoDB
          final placeMap = Map<String, dynamic>.from(place);
          
          // Ensure essential fields are not null
          placeMap['id'] = placeMap['id']?.toString() ?? '';
          placeMap['name_eng'] = placeMap['name_eng']?.toString() ?? placeMap['name']?.toString() ?? '';
          placeMap['category'] = placeMap['category']?.toString() ?? '';
          placeMap['description'] = placeMap['description']?.toString() ?? '';
          placeMap['location'] = placeMap['location']?.toString() ?? '';
          
          if (placeMap['image_data'] != null) {
            // Use the base64 image data directly
            placeMap['image_url'] = placeMap['image_data'].toString();
          } else if (placeMap['image_path'] != null) {
            // Fallback to image_path if image_data is not available
            placeMap['image_url'] =
                'http://localhost:9000/uploads/${placeMap['image_path'].toString()}';
          } else {
            placeMap['image_url'] = '';
          }
          return placeMap;
        }).toList();
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
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        final place = Map<String, dynamic>.from(json.decode(response.body));
        
        // Ensure essential fields are not null
        place['id'] = place['id']?.toString() ?? '';
        place['name_eng'] = place['name_eng']?.toString() ?? place['name']?.toString() ?? '';
        place['category'] = place['category']?.toString() ?? '';
        place['description'] = place['description']?.toString() ?? '';
        place['location'] = place['location']?.toString() ?? '';
        
        // Use image_data from MongoDB
        if (place['image_data'] != null) {
          place['image_url'] = place['image_data'].toString();
        } else if (place['image_path'] != null) {
          place['image_url'] =
              'http://localhost:9000/uploads/${place['image_path'].toString()}';
        } else {
          place['image_url'] = '';
        }
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
