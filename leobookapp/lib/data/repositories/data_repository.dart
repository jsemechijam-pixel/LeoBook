import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_urls.dart';
import '../models/match_model.dart';
import '../models/recommendation_model.dart';
import '../database/predictions_database.dart';
import 'dart:convert';

class DataRepository {
  static const String _keyRecommended = 'cached_recommended';

  final PredictionsDatabase _predictionsDb = PredictionsDatabase();

  Future<List<MatchModel>> fetchMatches() async {
    try {
      // 1. Get database (downloads if not cached)
      await _predictionsDb.getDatabase(ApiUrls.predictionsDb);

      // 2. Query all predictions from database
      final predictions = await _predictionsDb.getAllPredictions();

      debugPrint('Loaded ${predictions.length} predictions from database');

      // 3. Convert database rows to MatchModel objects
      return predictions
          .map((row) {
            // Database row already contains all prediction data
            return MatchModel.fromCsv(row, row);
          })
          .where((m) => m.prediction != null && m.prediction!.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint("DataRepository Error (Database): $e");

      // Fallback: try to use cached database if download failed
      final isCached = await _predictionsDb.isDatabaseCached();
      if (isCached) {
        try {
          await _predictionsDb.getDatabase(ApiUrls.predictionsDb);
          final predictions = await _predictionsDb.getAllPredictions();
          return predictions
              .map((row) => MatchModel.fromCsv(row, row))
              .where((m) => m.prediction != null && m.prediction!.isNotEmpty)
              .toList();
        } catch (cacheError) {
          debugPrint("Failed to load from cached database: $cacheError");
        }
      }

      return [];
    }
  }

  Future<List<RecommendationModel>> fetchRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http
          .get(Uri.parse(ApiUrls.recommended))
          .timeout(const Duration(seconds: 30));

      String? body;
      if (response.statusCode == 200) {
        body = utf8.decode(response.bodyBytes);
        await prefs.setString(_keyRecommended, body);
      } else {
        body = prefs.getString(_keyRecommended);
      }

      if (body == null) return [];

      final List<dynamic> jsonList = jsonDecode(body);
      return jsonList
          .map((json) => RecommendationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetching recommendations: $e");
      final cached = prefs.getString(_keyRecommended);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        return jsonList
            .map((json) => RecommendationModel.fromJson(json))
            .toList();
      }
      return [];
    }
  }
}
