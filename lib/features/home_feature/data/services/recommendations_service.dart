import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/auth_service.dart'
    show AuthException, AuthService;
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/models/recommendation_models.dart';
import 'package:http/http.dart' as http;

class _RecommendationsCacheEntry {
  _RecommendationsCacheEntry(this.items, this.expiresAt);

  final List<RecommendationItem> items;
  final DateTime expiresAt;
}

/// JWT ile öneri listesi; aynı kullanıcı + preference için kısa süreli istemci önbelleği.
class RecommendationsService {
  RecommendationsService({
    AuthService? authService,
    String? baseUrl,
    List<String>? baseUrls,
  }) : _baseUrls =
            baseUrl != null || (baseUrls != null && baseUrls.isNotEmpty)
                ? AuthService(baseUrl: baseUrl, baseUrls: baseUrls).baseUrls
                : (authService ?? AuthService()).baseUrls;

  static final Map<String, _RecommendationsCacheEntry> _memory =
      <String, _RecommendationsCacheEntry>{};

  static const Duration _clientCacheTtl = Duration(seconds: 90);

  final List<String> _baseUrls;

  Future<List<RecommendationItem>> getRecommendations({
    String preference = 'any',
  }) async {
    final token = AppSession.token.trim();
    if (token.isEmpty) {
      throw AuthException('Oturum bulunamadı.');
    }
    final userId = AppSession.userId;
    final pref = preference.trim().toLowerCase();
    final cacheKey = '$userId|$pref';
    final now = DateTime.now();
    final hit = _memory[cacheKey];
    if (hit != null && hit.expiresAt.isAfter(now)) {
      return hit.items;
    }

    final q = Uri.encodeComponent(pref);
    final path = '/api/recommendations?preference=$q';
    final response = await _getWithFallback(path: path, token: token);
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      return const [];
    }
    final raw = data['items'];
    if (raw is! List) {
      return const [];
    }
    final list = raw
        .whereType<Map<String, dynamic>>()
        .map(RecommendationItem.fromJson)
        .toList();

    _memory[cacheKey] = _RecommendationsCacheEntry(
      list,
      now.add(_clientCacheTtl),
    );
    return list;
  }

  Future<http.Response> _getWithFallback({
    required String path,
    required String token,
  }) async {
    for (final baseUrl in _baseUrls) {
      final url = '$baseUrl$path';
      if (kDebugMode) {
        debugPrint('[API DEBUG] RecommendationsService GET: $url');
      }
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: <String, String>{
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 25));
        if (response.statusCode == 401) {
          throw AuthException('Oturum süreniz doldu. Lütfen tekrar giriş yapın.');
        }
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
      } on AuthException {
        rethrow;
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('RecommendationsService GET hata ($baseUrl): $error');
        }
      }
    }
    throw AuthException('Öneriler yüklenemedi.');
  }
}
