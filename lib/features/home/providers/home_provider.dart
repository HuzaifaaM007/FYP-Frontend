import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../models/weak_topic.dart';
import '../models/recommendation.dart';
import '../services/home_service.dart';

enum HomeLoadState { loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  final _homeService = HomeService();

  HomeLoadState state = HomeLoadState.loading;
  String? errorMessage;

  DashboardStats? stats;
  List<WeakTopic> weakTopics = [];
  List<RecommendationItem> recommendations = [];

  Future<void> loadAll() async {
    state = HomeLoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _homeService.fetchDashboard(),
        _homeService.fetchWeakTopics(),
        _homeService.fetchRecommendations(),
      ]);

      stats = results[0] as DashboardStats;
      weakTopics = results[1] as List<WeakTopic>;
      recommendations = results[2] as List<RecommendationItem>;
      state = HomeLoadState.loaded;
    } catch (_) {
      errorMessage = 'Could not load your dashboard. Pull down to try again.';
      state = HomeLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> dismissRecommendation(String recommendationId) async {
    recommendations.removeWhere((item) => item.recommendationId == recommendationId);
    notifyListeners();
    try {
      await _homeService.dismissRecommendation(recommendationId);
    } catch (_) {
      // Non-critical — not displaying the error as it iwll diturb the ui
    }
  }
}