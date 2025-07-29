import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageTestWidget extends StatelessWidget {
  const ImageTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Testing image loading...'),
            const SizedBox(height: 20),
            Container(
              width: 200,
              height: 200,
              child: CachedNetworkImage(
                imageUrl: 'http://localhost:9000/uploads/test.png',
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) {
                  print('❌ Image error: $error');
                  return Container(
                    color: Colors.red[100],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 50),
                          SizedBox(height: 10),
                          Text('Image failed to load'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Test the API endpoint
                print('🔍 Testing API endpoint...');
              },
              child: const Text('Test API'),
            ),
          ],
        ),
      ),
    );
  }
}
