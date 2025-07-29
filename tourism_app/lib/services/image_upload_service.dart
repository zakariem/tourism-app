import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageUploadService {
  static const String baseUrl = 'http://localhost:9000/api/places';

  // Upload a single image
  static Future<Map<String, dynamic>?> uploadImage(File imageFile) async {
    try {
      // print('📤 Uploading image: ${imageFile.path}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/test-upload'),
      );

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse;
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        // print('Response: $responseData');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Upload multiple images
  static Future<List<Map<String, dynamic>>> uploadMultipleImages(
      List<File> imageFiles) async {
    List<Map<String, dynamic>> results = [];

    for (File imageFile in imageFiles) {
      final result = await uploadImage(imageFile);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  // Add a new place with image
  static Future<Map<String, dynamic>?> addPlaceWithImage({
    required String nameEng,
    required String nameSom,
    required String descEng,
    required String descSom,
    required String location,
    required String category,
    File? imageFile,
    double? pricePerPerson,
    int? maxCapacity,
  }) async {
    try {
      print('📤 Adding place with image: $nameEng');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl),
      );

      // Add text fields
      request.fields['name_eng'] = nameEng;
      request.fields['name_som'] = nameSom;
      request.fields['desc_eng'] = descEng;
      request.fields['desc_som'] = descSom;
      request.fields['location'] = location;
      request.fields['category'] = category;

      if (pricePerPerson != null) {
        request.fields['pricePerPerson'] = pricePerPerson.toString();
      }

      if (maxCapacity != null) {
        request.fields['maxCapacity'] = maxCapacity.toString();
      }

      // Add image if provided
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            imageFile.path,
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 201) {
        return jsonResponse;
      } else {
        print('❌ Failed to add place: ${response.statusCode}');
        // print('Response: $responseData');
        return null;
      }
    } catch (e) {
      print('❌ Error adding place: $e');
      return null;
    }
  }

  // Update a place with image
  static Future<Map<String, dynamic>?> updatePlaceWithImage({
    required String placeId,
    String? nameEng,
    String? nameSom,
    String? descEng,
    String? descSom,
    String? location,
    String? category,
    File? imageFile,
    double? pricePerPerson,
    int? maxCapacity,
  }) async {
    try {
      print('📤 Updating place: $placeId');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/$placeId'),
      );

      // Add text fields (only if provided)
      if (nameEng != null) request.fields['name_eng'] = nameEng;
      if (nameSom != null) request.fields['name_som'] = nameSom;
      if (descEng != null) request.fields['desc_eng'] = descEng;
      if (descSom != null) request.fields['desc_som'] = descSom;
      if (location != null) request.fields['location'] = location;
      if (category != null) request.fields['category'] = category;

      if (pricePerPerson != null) {
        request.fields['pricePerPerson'] = pricePerPerson.toString();
      }

      if (maxCapacity != null) {
        request.fields['maxCapacity'] = maxCapacity.toString();
      }

      // Add image if provided
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            imageFile.path,
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse;
      } else {
        print('❌ Failed to update place: ${response.statusCode}');
        // print('Response: $responseData');
        return null;
      }
    } catch (e) {
      print('❌ Error updating place: $e');
      return null;
    }
  }
}
