import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../models/weak_topic.dart';
import '../models/recommendation.dart';
import '../models/activity.dart';
import '../services/home_service.dart';

enum HomeLoadState { loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  final _homeService = HomeService();

  HomeLoadState state = HomeLoadState.loading;
  String? errorMessage;

  DashboardStats? stats;
  List<WeakTopic> weakTopics = [];
  List<RecommendationItem> recommendations = [];

  /// Loaded separately: if it fails the rest of the dashboard still shows.
  StudentActivity? activity;
  bool activityFailed = false;

  Future<void> loadAll() async {
    state = HomeLoadState.loading;
    errorMessage = null;
    notifyListeners();

    // Fire the activity request alongside the main ones, but never let it fail the whole screen.
    final activityFuture = _homeService.fetchActivity().then<StudentActivity?>((a) => a).catchError((_) => null);

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
    }

    final loadedActivity = await activityFuture;
    activity = loadedActivity ?? activity;
    activityFailed = loadedActivity == null;
    notifyListeners();
  }

  /// Tell the backend a recommendation was opened (it learns from this). Fire and forget.
  void markClicked(String recommendationId) {
    _homeService.markRecommendationClicked(recommendationId).catchError((_) {});
  }

  Future<void> dismissRecommendation(String recommendationId) async {
    recommendations.removeWhere((item) => item.recommendationId == recommendationId);
    notifyListeners();
    try {
      await _homeService.dismissRecommendation(recommendationId);
    } catch (_) {
      // Non-critical.
    }
  }
}
