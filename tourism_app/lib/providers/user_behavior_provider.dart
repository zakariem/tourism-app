import 'package:flutter/material.dart';

class UserBehaviorProvider extends ChangeNotifier {
  int beachClicks = 0,
      historicalClicks = 0,
      culturalClicks = 0,
      religiousClicks = 0;
  double totalViewTime = 0;
  int viewCount = 0;
  int languageEncoded = 1; // 1 for English, 0 for Somali

  void recordClick(String category) {
    print('[UserBehaviorProvider] Click recorded for $category');
    switch (category) {
      case 'beach':
        beachClicks++;
        break;
      case 'historical':
        historicalClicks++;
        break;
      case 'cultural':
        culturalClicks++;
        break;
      case 'religious':
        religiousClicks++;
        break;
    }
    notifyListeners();
  }

  void recordViewTime(double seconds, {bool notify = true}) {
    print('[UserBehaviorProvider] View time recorded: $seconds seconds');
    totalViewTime += seconds;
    viewCount++;
    if (notify) notifyListeners();
  }

  void setLanguage(String lang) {
    print('[UserBehaviorProvider] Language set: $lang');
    languageEncoded = (lang == 'en') ? 1 : 0;
    notifyListeners();
  }

  double get avgViewTime => viewCount == 0 ? 0 : totalViewTime / viewCount;

  List<double> get featureVector => [
        beachClicks.toDouble(),
        historicalClicks.toDouble(),
        culturalClicks.toDouble(),
        religiousClicks.toDouble(),
        avgViewTime,
        languageEncoded.toDouble(),
      ];

  void reset() {
    print('[UserBehaviorProvider] Behavior reset');
    beachClicks = 0;
    historicalClicks = 0;
    culturalClicks = 0;
    religiousClicks = 0;
    totalViewTime = 0;
    viewCount = 0;
    notifyListeners();
  }

  // Only recommend if enough data (e.g., at least 10 clicks)
}
